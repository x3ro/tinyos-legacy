/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * This module monitors network traffic and relays log message to the display
 * node if possible.
 */

// note setting DISPLAY to 0 also disables NetworkMonitor keyboard input
#define DISPLAY 1
module NetworkMonitorM {

  provides {
    interface StdControl;
    command result_t Display(char *str);
    event result_t DisplayMessageDone();
  }

  uses {
#if DISPLAY
    interface StdControl as UARTControl;
    interface ReceiveData;
    interface SendVarLenPacket;
#endif

    interface NetworkPacket;
    interface NetworkTopology;
    interface NetworkProperty;

    interface HCILinkControl;
    interface HCIData;
    interface HCIBaseband;

    command result_t DisplayMessage(char *str);
    interface NetworkLowPower;
    command result_t NetworkWriteScanEnable(uint32 state);
//    command result_t NetworkInitLowPower(uint16 min, uint16 max);
//    command result_t NetworkEnterLowPower();
//    command result_t NetworkExitLowPower();
  }
}

implementation
{
  #include "./motelib.h" // needed for TOSBuffer declaration
  #include <stdarg.h>

//#define NETWORK_DEBUG
//#define LOG_HCIDATA
//#define LOG_BASEBAND
//#define LOG_LINKCONTROL

  /*
   * List of messages passed between the monitor components.  The query/ reply
   * TRACE_ROUTE messages are used together.  The query/ reply next neighbor
   * messages are used together.
   *
   * MONITOR_QUERY_TRACE_ROUTE
   *   [0:3]  command id
   *   [4:7]  requesting node ID
   *   [8:11] target node ID
   *   - Requests a backtrace of node hops from the target node to the requestor
   *
   * MONITOR_REPLY_TRACE_ROUTE
   *   [0:3]   command id
   *   [4:7]   requesting node ID
   *   [8:11]  target node ID
   *   [12:15] last hop before the target node
   *   [16:19] second to last hop before the target node
   *   ...
   *   [len-3:len] next hop from the requesting node to the target node
   *   - Reply message which contains the entire chain of nodes from the target
   *     node to the current node on the way to the requesting node.  Each hop
   *     appends its ID so that the entire chain is available when the message
   *     reaches the requesting node.
   */

  enum { MONITOR_QUERY_TRACE_ROUTE = 1,
         MONITOR_REPLY_TRACE_ROUTE,
         MONITOR_QUERY_SIGNAL_STRENGTH,
         MONITOR_REPLY_SIGNAL_STRENGTH,
         MONITOR_QUERY_POWER_LEVEL,
         MONITOR_REPLY_POWER_LEVEL,
         MONITOR_DEBUG_DISPLAY};



  char ChannelStr[6][16];

  bool sendPending;
  
  #define MAX_STR_LEN 80

  char DisplayString[MAX_STR_LEN];
  uint32 ThisNodeID;

  #define MAX_TRACE_ROUTE_NODES 32
  uint32 TraceRouteList[MAX_TRACE_ROUTE_NODES];
  bool TracePending;

  #define MAX_SIGNAL_STRENGTH_NODES 32
  uint32 SignalStrengthList[MAX_SIGNAL_STRENGTH_NODES];
  bool SignalStrengthPending;

  #define MAX_POWER_LEVEL_NODES 32
  uint32 PowerLevelList[MAX_POWER_LEVEL_NODES];
  bool PowerLevelPending;

  #define MAX_LINK_POWER 16
  typedef struct tLinkPower {
    uint32  Node1;
    uint32  Node2;
    int8_t  Node1_RSSI;
    int8_t  Node1_Tx;
    int8_t  Node2_RSSI;
    int8_t  Node2_Tx;
  } tLinkPower;
  tLinkPower LinkPower[MAX_LINK_POWER];
  int NumLinkPower;
  
  bool DisplayMessagePending;

  uint32 DebugNode;     // Node ID to send diagnostic messages

  void MyPrint(char *str) {

#if DISPLAY
#if 0
    int len, i;

    len = strlen(str);
    if (len > MAX_STR_LEN - 2) len = MAX_STR_LEN - 2;

    if (!sendPending) {
  
      sendPending = TRUE;
      for (i = 0; i < len; i++) DisplayString[i] = str[i];
      DisplayString[len++] = 13; // LF?
      DisplayString[len++] = 0;  // EOS
      if ((call SendVarLenPacket.send(DisplayString, len)) == FAIL) {
        sendPending = FALSE;
      }

    }
#endif
    int len;

    if (!sendPending) {
// don't block messages to lower level
//      sendPending = TRUE;
      snprintf(DisplayString, MAX_STR_LEN, "%05X:%s\r", ThisNodeID, str);
      len = strlen(DisplayString);
      if ((call SendVarLenPacket.send(DisplayString, len)) == FAIL) {
        sendPending = FALSE;
      }
    }
#endif

    return;
  }

  void DisplayStr(char *str) __attribute__ ((C, spontaneous)) {
#if DISPLAY
#ifdef NETWORK_DEBUG
    char *buf;
    uint32 *t;
    int length, i;
#endif // NETWORK_DEBUG

    MyPrint(str);
#ifdef NETWORK_DEBUG
    if (DebugNode != INVALID_NODE) {
      length = ((4 + strlen(str) + 1) + 3) & ~0x3;
              // command word length + string length + EOS, 4-byte aligned
      buf = call NetworkPacket.AllocateBuffer(length);
      if (buf == NULL) return;

      t = (uint32 *) buf;
      t[0] = (uint32) MONITOR_DEBUG_DISPLAY;
      for (i = 4; i < length; i++) buf[i] = str[i - 4];
      buf[length - 1] = 0; // make sure string ends with EOS

      if (call NetworkPacket.Send(DebugNode, buf, length) == FAIL) {
        call NetworkPacket.ReleaseBuffer(buf);
        return;
      }
    }
#endif // NETWORK_DEBUG
#endif //DISPLAY
  }

  command result_t Display(char *str) {
#if 0
    DisplayStr(str);
#endif
    return SUCCESS;
  }

  command result_t StdControl.init() {

    result_t ok1;

    sendPending = TRUE;
#if DISPLAY
    ok1 = call UARTControl.init();
#endif
    sendPending = FALSE;

    sprintf(ChannelStr[0], "DATA");
    sprintf(ChannelStr[1], "RELAY");
    sprintf(ChannelStr[2], "MONITOR");
    sprintf(ChannelStr[3], "SCATTERNET");
    sprintf(ChannelStr[4], "ROUTING");
    sprintf(ChannelStr[5], "PROPERTIES");

    DebugNode = INVALID_NODE;
    TracePending = FALSE;
    SignalStrengthPending = FALSE;
    PowerLevelPending = FALSE;
    DisplayMessagePending = FALSE;

//    call NetworkLowPower.NetworkInitLowPower(20000, 25000);

    return ok1;
  }



  command result_t StdControl.start() {

    result_t ok1, ok2, ok3;

#if DISPLAY
    ok1 = call UARTControl.start();
#endif
    ok2 = call NetworkPacket.Initialize();
    ok3 = call NetworkTopology.GetNodeID(&ThisNodeID);

    return rcombine3(ok1, ok2, ok3);
  }



  command result_t StdControl.stop() {

    result_t ok1;
    
#if DISPLAY
    ok1 = call UARTControl.stop();
#endif

    return ok1;
  }

  

  void SendTraceReply(uint32 Requestor) {
    char    *buf;
    uint32  *t;
    uint32  NextNode;

    buf = call NetworkPacket.AllocateBuffer(12);
    if (buf == NULL) return;

    t = (uint32 *) buf;
    t[0] = (uint32) MONITOR_REPLY_TRACE_ROUTE;
    t[1] = Requestor; // Requesting node's ID
    t[2] = ThisNodeID;

    if (call NetworkTopology.GetNextConnection(Requestor, &NextNode, NULL)
        == SUCCESS) {
      if (call NetworkPacket.Send(NextNode, buf, 12) == FAIL) {
        call NetworkPacket.ReleaseBuffer(buf);
        return;
      }
    }

    return;
  }



  void RelayTraceReply(uint32 Source, char *Data, uint16 Length) {
    char    *buf;
    uint32  *t;
    uint32  NextNode;
    int     i;

    buf = call NetworkPacket.AllocateBuffer(Length + 4);
    if (buf == NULL) return;

    for (i = 0; i < Length; i++) buf[i] = Data[i];
    t = (uint32 *) buf;

    t[(Length >> 2)] = ThisNodeID;

    if (call NetworkTopology.GetNextConnection(t[1], &NextNode, NULL)
        == SUCCESS) {
      if (call NetworkPacket.Send(NextNode, buf, Length + 4) == FAIL) {
        call NetworkPacket.ReleaseBuffer(buf);
        return;
      }
    }

    return;
  }


  void DisplayTraceRoute(char *data, uint16 length) {
    char str[80];
    int i;
    uint32 *t;

    t = (uint32 *) data;
    memset (str, 0, 80);
    sprintf (str, "Trace Route:");
    for (i = 2; i < (length >> 2); i++) {
      sprintf (str, "%s %05X,", str, t[i] & 0xFFFFF);
    }
    sprintf (str, "%s %05X\n", str, t[1] & 0xFFFFF);
    MyPrint(str);

    return;
  }


  void SendSignalStrengthReply(uint32 Requestor) {
    char    *buf;
    uint32  *t;
    uint32  NextNode;
    tHandle NextHandle;

    buf = call NetworkPacket.AllocateBuffer(20);
    if (buf == NULL) return;

    t = (uint32 *) buf;
    t[0] = (uint32) MONITOR_REPLY_SIGNAL_STRENGTH;
    t[1] = Requestor; // Requesting node's ID
    t[2] = ThisNodeID;

    // Get the next node on the path back to the requesting node
    if (call NetworkTopology.GetNextConnection(Requestor, &NextNode,
          &NextHandle) == SUCCESS) {
      t[3] = NextNode;
      t[4] = (int32_t) call NetworkTopology.GetRSSI(NextHandle);
    } else {
      t[3] = INVALID_NODE;
      t[4] = 0;
    }

    if (call NetworkPacket.Send(Requestor, buf, 20) == FAIL) {
      call NetworkPacket.ReleaseBuffer(buf);
      return;
    }

    return;
  }


  void DisplaySignalStrength(char *data, uint16 length) {
    char str[80];
    uint32 *t;

    t = (uint32 *) data;
    sprintf (str, "Signal strength from %05X to %05X = %d\n\r",
      t[2], t[3], t[4]);
    MyPrint(str);

    return;
  }

  void SendPowerLevelReply(uint32 Requestor) {
    uint32  NumNeighbors;
    uint32  NeighborList[16];

    char    *buf;
    uint32  *t;
    uint32  NextNode;
    tHandle NextHandle;
    int i;

    // Get neighbor list
    call NetworkTopology.Get1HopDestinations( 16, &NumNeighbors,
                                              &(NeighborList[0]));

    // allocate buffers
    // conservatively allocate 12 bytes for the header and 8 bytes for each link
    buf = call NetworkPacket.AllocateBuffer(12 + 8 * NumNeighbors);
    if (buf == NULL) return;

    // fill in header
    t = (uint32 *) buf;
    t[0] = (uint32) MONITOR_REPLY_POWER_LEVEL;
    t[1] = Requestor; // Requesting node's ID
    t[2] = ThisNodeID;

    // cycle through neighbors adding node ID, transmit level,
    // and signal strength
    for (i = 0; i < NumNeighbors; i++) {
      if (call NetworkTopology.GetNextConnection(NeighborList[i], &NextNode,
            &NextHandle) == SUCCESS) {
        t[3 + i * 2] = NextNode;
        buf[12 + i * 8 + 4] = (int8_t) call NetworkTopology.GetRSSI(NextHandle);
        buf[12 + i * 8 + 5] =
            (int8_t) call NetworkTopology.GetTransmitPower(NextHandle);
      } else {
        t[3] = INVALID_NODE;
        buf[12 + i * 8 + 4] = 0;
        buf[12 + i * 8 + 5] = 0;
      }
    }


    if (call NetworkPacket.Send(Requestor, buf, 12 + 8 * NumNeighbors)== FAIL) {
      call NetworkPacket.ReleaseBuffer(buf);
      return;
    }

    return;
  }



  /*
   * This function should be called every time half of a link's power
   * information is received.  If this is the first half of the link, a new
   * entry is created and the power information is added to the table.
   * If this is the second half of the link's data, the link information is
   * printed and the entry is removed.
   * The power collection is done when there are no more entries in this table.
   */
  void UpdateLinkPower( uint32 LocalNode, uint32 RemoteNode,
                        int8_t RSSI, int8_t Tx) {
    char str[80];
    int i;

    for (i = 0; i < NumLinkPower; i++) {
      if ((LocalNode == LinkPower[i].Node2) &&
          (RemoteNode == LinkPower[i].Node1)) {
        // The first half of the link already exists, so print out the link.
        sprintf(str, "Power: %05X %05X %-3d %-3d %-3d %-3d \n",
          LocalNode, RemoteNode, LinkPower[i].Node1_RSSI, LinkPower[i].Node1_Tx,
          RSSI, Tx);
        MyPrint(str);

        if (--NumLinkPower > 0) {
          LinkPower[i].Node1 = LinkPower[NumLinkPower].Node1;
          LinkPower[i].Node2 = LinkPower[NumLinkPower].Node2;
          LinkPower[i].Node1_RSSI = LinkPower[NumLinkPower].Node1_RSSI;
          LinkPower[i].Node1_Tx = LinkPower[NumLinkPower].Node1_Tx;
        } else {
          MyPrint("Power Done\n");
        }
//sprintf(str, "Power remove num links %d\n", NumLinkPower);
//MyPrint(str);
        return;
      }
    }

    // not currently in the list
    if (NumLinkPower < MAX_LINK_POWER - 1) {
      LinkPower[NumLinkPower].Node1 = LocalNode;
      LinkPower[NumLinkPower].Node2 = RemoteNode;
      LinkPower[NumLinkPower].Node1_RSSI = RSSI;
      LinkPower[NumLinkPower].Node1_Tx = Tx;
      NumLinkPower++;
    }
//sprintf(str, "Power add local %05X remote %05X num links %d\n", LocalNode, RemoteNode, NumLinkPower);
//MyPrint(str);
    return;
  }



  void DisplayPowerLevel(char *data, uint16 length) {
    uint32 *t;
    int i, samples;

    t = (uint32 *) data;

    samples = (length - 12) >> 3;
    for (i = 0; i < samples; i++) {
      UpdateLinkPower( t[2],                         // LocalNode
                       t[3 + i*2],                   // array of Remote Nodes
                       (int8_t) data[12 + i*8 + 4],  // array of RSSI
                       (int8_t) data[12 + i*8 + 5]); // array of Tx
    }

    return;
  }


  event result_t NetworkPacket.Receive( uint32 Source, uint8 *Data,
                                        uint16 Length) {

    uint32 *t;
    char str[80];

    t = (uint32 *) Data;

    switch (t[0]) {

      case MONITOR_QUERY_TRACE_ROUTE:
        if (t[2] == ThisNodeID) SendTraceReply(t[1]);
        break;

      case MONITOR_REPLY_TRACE_ROUTE:
        if (t[1] == ThisNodeID) {
          DisplayTraceRoute(Data, Length);
        } else {
          RelayTraceReply(Source, Data, Length);
        }
        break;

      case MONITOR_QUERY_SIGNAL_STRENGTH:
        if (t[2] == ThisNodeID) SendSignalStrengthReply(t[1]);
        break;

      case MONITOR_REPLY_SIGNAL_STRENGTH:
        if (t[1] == ThisNodeID) {
          DisplaySignalStrength(Data, Length);
        }
        break;

      case MONITOR_QUERY_POWER_LEVEL:
        if (t[2] == ThisNodeID) SendPowerLevelReply(t[1]);
        break;

      case MONITOR_REPLY_POWER_LEVEL:
        if (t[1] == ThisNodeID) {
          DisplayPowerLevel(Data, Length);
        }
        break;

      case MONITOR_DEBUG_DISPLAY:
        snprintf(str, 80, "%05X %s", Source & 0xFFFFF, &(Data[4]));
        MyPrint(str);
        break;

      default:
    }

    return SUCCESS;

  }


  task void DoTraceRoute() {
    int TraceRouteIndex;
    char    *buf;
    uint32  *t;

    if (TracePending) {

      TraceRouteIndex = MAX_TRACE_ROUTE_NODES;
      call NetworkTopology.GetAllDestinations (&(TraceRouteList[0]), NULL,
                                               &TraceRouteIndex);

      while (TraceRouteIndex != 0) {
        TraceRouteIndex--;

        buf = call NetworkPacket.AllocateBuffer(12);
        if (buf == NULL) return;
  
        t = (uint32 *) buf;
        t[0] = (uint32) MONITOR_QUERY_TRACE_ROUTE;
        t[1] = ThisNodeID;
        t[2] = TraceRouteList[TraceRouteIndex];
    
        if (call NetworkPacket.Send(TraceRouteList[TraceRouteIndex], buf, 12)
            == FAIL) {
  
          call NetworkPacket.ReleaseBuffer(buf);
          return;
        }
      }
    }
    TracePending = FALSE;
  }


  task void DoSignalStrength() {
    int SignalStrengthIndex;
    char    *buf;
    uint32  *t;

    if (SignalStrengthPending) {

      SignalStrengthIndex = MAX_SIGNAL_STRENGTH_NODES;
      call NetworkTopology.GetAllDestinations (&(SignalStrengthList[0]), NULL,
                                               &SignalStrengthIndex);

      while (SignalStrengthIndex != 0) {
        SignalStrengthIndex--;

        buf = call NetworkPacket.AllocateBuffer(12);
        if (buf == NULL) return;
  
        t = (uint32 *) buf;
        t[0] = (uint32) MONITOR_QUERY_SIGNAL_STRENGTH;
        t[1] = ThisNodeID;
        t[2] = SignalStrengthList[SignalStrengthIndex];
    
        if (call NetworkPacket.Send(SignalStrengthList[SignalStrengthIndex], buf, 12)
            == FAIL) {
  
          call NetworkPacket.ReleaseBuffer(buf);
          return;
        }
      }
    }
    SignalStrengthPending = FALSE;
  }





  task void DoPowerLevel() {
    int     PowerLevelIndex;
    char    *buf;
    uint32  *t;
    uint32  NumNeighbors, NeighborList[16], NextNode;
    tHandle NextHandle;
    int     i;

    if (PowerLevelPending) {

      NumLinkPower = 0;

      call NetworkTopology.Get1HopDestinations( 16, &NumNeighbors,
                                                &(NeighborList[0]));

      // Print header
      MyPrint("Power: Local Remote L_RS  L_Tx  R_RS R_Tx\n");

      for (i = 0; i < NumNeighbors; i++) {
        if (call NetworkTopology.GetNextConnection(NeighborList[i], &NextNode,
              &NextHandle) == SUCCESS) {
          UpdateLinkPower( ThisNodeID, NeighborList[i], 
                   (int8_t) call NetworkTopology.GetRSSI(NextHandle),
                   (int8_t) call NetworkTopology.GetTransmitPower(NextHandle));
        }
      }

      PowerLevelIndex = MAX_POWER_LEVEL_NODES;
      call NetworkTopology.GetAllDestinations (&(PowerLevelList[0]), NULL,
                                               &PowerLevelIndex);

      while (PowerLevelIndex != 0) {
        PowerLevelIndex--;

        buf = call NetworkPacket.AllocateBuffer(12);
        if (buf == NULL) return;
  
        t = (uint32 *) buf;
        t[0] = (uint32) MONITOR_QUERY_POWER_LEVEL;
        t[1] = ThisNodeID;
        t[2] = PowerLevelList[PowerLevelIndex];
    
        if (call NetworkPacket.Send(PowerLevelList[PowerLevelIndex], buf, 12)
            == FAIL) {
  
          call NetworkPacket.ReleaseBuffer(buf);
          return;
        }
      }
    }
    PowerLevelPending = FALSE;
  }


  task void PrintRoutingTable() {
#define LIST_SIZE 10
#define STRING_SIZE (LIST_SIZE * 10 + 20)
     uint32 NodeList[LIST_SIZE];
     uint32 HopList[LIST_SIZE];
     uint32 NumHops;
     uint8 i;
     char str[STRING_SIZE];
     
     NumHops = LIST_SIZE;
     call NetworkTopology.GetAllDestinations(NodeList, HopList, &NumHops);
     sprintf (str, "Routing Table:");
     for (i=0; i<NumHops; i++) {
        sprintf (str, "%s %05X %1X,", str, NodeList[i] & 0xFFFFF, HopList[i]);
     }
     sprintf (str, "%s \n", str);
     MyPrint(str);
  }



  task void TurnOffActiveRouting() {
    call NetworkTopology.UnsetProperty(ThisNodeID,
           NETWORK_PROPERTY_ACTIVE_ROUTING);
    MyPrint("Routing Off\n");
  }



  task void TurnOnActiveRouting() {
    call NetworkTopology.SetProperty(ThisNodeID,
           NETWORK_PROPERTY_ACTIVE_ROUTING);
    MyPrint("Routing On\n");
  }



#if DISPLAY
  /*
   * Added SendKey call below to test out low power interface via console
   * window.  Remove after testing.
   */
  event result_t ReceiveData.receive(uint8 *data, uint32 length) {
    char str[80];
    char key;

    key = data[0];
    switch (key) {
      case 't':
        if (!TracePending) {
          TracePending = TRUE;
          post DoTraceRoute();
        }
        break;

      case 'd':
         // Dump my table with hops
         post PrintRoutingTable();
         break;

      case 'r':
         // turn off active routing
         post TurnOffActiveRouting();
         break;

      case 'R':
         // turn on active routing
         post TurnOnActiveRouting();
         break;

      case 'm':
         if (DisplayMessagePending == FALSE) {
           DisplayMessagePending = TRUE;
           call DisplayMessage("Testing Network Message\r\n");
         }
         break;

      case 'I':
        call NetworkLowPower.NetworkInitLowPower(20000, 25000);
        break;

      case 'z':
        call NetworkLowPower.NetworkEnterLowPower(0);
        break;

      case 'Z':
        call NetworkLowPower.NetworkExitLowPower();
        break;

      case 's':
        // turn off scan
        call NetworkWriteScanEnable(0);
        break;

      case 'S':
        // turn on scan
        // this may not actually turn on both inquiry and page scan.
        // which scans are enabled depends on the SF algorithm.
        call NetworkWriteScanEnable(3);
        break;

      case 'i':
        // get the signal strengths for the network
        if (!SignalStrengthPending) { 
          SignalStrengthPending = TRUE;
          post DoSignalStrength();
        }
        break;

      case 'o':
        // get the power levels for the network
        if (!PowerLevelPending) { 
          PowerLevelPending = TRUE;
          post DoPowerLevel();
        }
        break;

      case 'h':
        DisplayStr("Network commands : \r\n");
        DisplayStr("t = Trace Route\r\n"); 
        DisplayStr("z = Put Network to Sleep\r\n"); 
        DisplayStr("Z = Wake up network\r\n"); 
        break;

      default:
#if 0   // assume app will decode, don't print message
        sprintf(str, "Unknown command %c\n", key);
        MyPrint(str);
#endif
        break;
    }

    return SUCCESS;

  }

  
  event result_t SendVarLenPacket.sendDone(uint8_t* packet, result_t success) {
    sendPending = FALSE;
//    if (TraceRouteIndex != 0) post DoTraceRoute();

    return SUCCESS;
  }
#endif
  

  event result_t NetworkPacket.SendDone( char *data ) {

    call NetworkPacket.ReleaseBuffer(data);
    return SUCCESS;
  }

  event result_t HCILinkControl.Command_Status_Inquiry( uint8 Status) {
#ifdef LOG_LINKCONTROL
    char str[80];
    if (Status == 0) {
      sprintf(str, "Inquiry Succeeded\n");
    } else {
      sprintf(str, "Inquiry Failed %X\n", Status);
    }
    MyPrint(str);
#endif //LOG_LINKCONTROL
    return SUCCESS;
  }

  event result_t HCILinkControl.Inquiry_Result( uint8 Num_Responses,
                                          tBD_ADDR *BD_ADDR,
                                          uint8 *Page_Scan_Repetition_Mode,
                                          uint8 *Page_Scan_Period_Mode,
                                          uint8 *Page_Scan_Mode,
                                          uint32 *Class_of_Device,
                                          uint16 *Clock_Offset) {
#ifdef LOG_LINKCONTROL
    char str[80];
    sprintf(str, "Inquiry Result %02X%02X%02X\n", BD_ADDR[0].byte[2], BD_ADDR[0].byte[1], BD_ADDR[0].byte[0]);
        MyPrint(str);
#endif //LOG_LINKCONTROL
    return SUCCESS;
  }

  event result_t HCILinkControl.Inquiry_Complete( uint8 Status ) {
    return SUCCESS;
  }

  event result_t HCILinkControl.Command_Complete_Inquiry_Cancel( uint8 Status ) {
    return SUCCESS;
  }

  event result_t HCILinkControl.Connection_Complete( uint8 Status,
                                      tHandle Connection_Handle,
                                      tBD_ADDR BD_ADDR,
                                      uint8 Link_Type,
                                      uint8 Encryption_Mode) {
#ifdef LOG_LINKCONTROL
    char str[80];
    sprintf(str, "Connection Complete %d %02X%02X%02X\n", Status, BD_ADDR.byte[2], BD_ADDR.byte[1], BD_ADDR.byte[0]);
        MyPrint(str);
#endif //LOG_LINKCONTROL
    return SUCCESS;
  }

  event result_t HCILinkControl.Connection_Request( tBD_ADDR BD_ADDR,
                                     uint32 Class_of_Device,//3 bytes meaningful
                                     uint8 Link_Type) {
#ifdef LOG_LINKCONTROL
    char str[80];
    sprintf(str, "Connection Request %02X%02X%02X\n", BD_ADDR.byte[2], BD_ADDR.byte[1], BD_ADDR.byte[0]);
        MyPrint(str);
#endif //LOG_LINKCONTROL
    return SUCCESS;
  }

  event result_t HCILinkControl.Disconnection_Complete( uint8 Status,
                                         tHandleId Connection_Handle,
                                         uint8 Reason) {
#ifdef LOG_LINKCONTROL
    char str[80];
    uint32 DestID;

    call NetworkTopology.NextHandle2NodeID(Connection_Handle, &DestID);
    sprintf(str, "Disconnection Complete %d %05X %d\n", Status, DestID, Reason);
        MyPrint(str);
#endif //LOG_LINKCONTROL
    return SUCCESS;
  }

  /*
   * Start HCIData interface
   */

  void BogusPacket(char *data) {
    char str[80];
    sprintf(str, "Error sending Bogus Packet\n");
    MyPrint(str);
  }

  event result_t HCIData.SendDone( uint32 TransactionID,
                                   tHandle Connection_Handle,
                                   result_t Acknowledge) {

#ifdef LOG_HCIDATA
    char str[80], ack[16], *data;
    tiMoteHeader *header;

    if (Acknowledge == TRUE) {
      sprintf(ack, "ACK");
    } else {
      sprintf(ack, "NACK");
    }

    header = (tiMoteHeader *) TransactionID;
    data = (char *) TransactionID;
    if (header->channel > 5) {
      BogusPacket((char *) TransactionID);
    } else {
      sprintf(str, "%s %d Send to %05X  - %s\n", ChannelStr[header->channel],
              data[sizeof(tiMoteHeader)], header->dest, ack);
      MyPrint(str);
    }
#endif //LOG_HCIDATA
    return SUCCESS;
  }



  event result_t HCIData.ReceiveACL( uint32  TransactionID,
                                     tHandle Connection_Handle,
                                     uint8   *Data,
                                     uint16  DataSize,
                                     uint8   DataFlags) {

#ifdef LOG_HCIDATA
    char str[80];
    tiMoteHeader *header;

    header = (tiMoteHeader *) Data;
    if (header->channel > 5) {
      BogusPacket(Data);
    } else {
      sprintf( str, "%s %d Receive from %05X\n", ChannelStr[header->channel],
               (uint8) Data[sizeof(tiMoteHeader)], header->source);
      MyPrint(str);
    }

#endif //LOG_HCIDATA
    return SUCCESS;
  }

  /*
   * End HCIData interface
   */



/*
 * Start of HCIBaseband interface.
 */

  event result_t HCIBaseband.Command_Complete_Write_Scan_Enable(uint8 Status) {
#ifdef LOG_BASEBAND
    char str[80];

    sprintf(str, "Write Scan Enable Status %d\n", Status);
    MyPrint(str);
#endif // LOG_BASEBAND
    return SUCCESS;
  }



  event result_t HCIBaseband.Command_Complete_Read_Link_Supervision_Timeout(
                                              uint8 Reason,
                                              tHandle Connection_Handle,
                                              uint16 Timeout) {
#ifdef LOG_BASEBAND
    char str[80];

    sprintf(str, "Status %d Handle %d Supervision Timeout = %d\n", Reason,
            Connection_Handle, Timeout);
    MyPrint(str);
#endif // LOG_BASEBAND

    return SUCCESS;
  }



  event result_t HCIBaseband.Command_Complete_Write_Current_IAC_LAP(
                                              uint8 Status ) {
    return SUCCESS;
  }
   


  event result_t HCIBaseband.Command_Complete_Read_Transmit_Power_Level(
                                                 uint8 Status,
                                                 tHandle Connection_Handle,
                                                 int8_t Transmit_Power_Level) {
    return SUCCESS;
  }


/*
 * End of HCIBaseband interface.
 */



/*
 * Start of NetworkProperty interface.
 */


  event result_t NetworkProperty.NodePropertiesReady(uint32 NodeID) {
    if (call NetworkTopology.IsPropertySupported(NodeID,
          NETWORK_PROPERTY_DEBUG_DISPLAY)) {
      DebugNode = NodeID;
    }
    return SUCCESS;
  }

/*
 * End of NetworkProperty interface.
 */

/*
 * Start of NetworkManager interface.
 */


  event result_t DisplayMessageDone() { 
    DisplayMessagePending = FALSE;
    return SUCCESS;
  }

  event result_t NetworkLowPower.NetworkInitLowPowerDone() { return SUCCESS;}
  event result_t NetworkLowPower.NetworkEnterLowPowerDone() { return SUCCESS;}
  event result_t NetworkLowPower.NetworkExitLowPowerDone() { return SUCCESS;}

/*
 * End of NetworkManager interface.
 */

 
}

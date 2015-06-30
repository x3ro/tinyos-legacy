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
 * This module manages the network connections for each node.
 * 
 * Nodes alternate between the inquiry and scan states until they find
 * someone connected to the root.  New nodes always join the tree as slaves and
 * leaf nodes.
 */

module FindRootScatternetFormationM
{
  provides {
    interface StdControl as Control;
    interface ScatternetFormation;

    command result_t NetworkDiscoveryActive(bool DiscoveryActive);
    command result_t GetRootNodeID(uint32 *ID);
  }

  uses {
    interface StdControl as BTLowerLevelControl;
    interface HCILinkControl;
    interface HCILinkPolicy;
    interface HCIBaseband;

    interface Timer;
    interface NetworkPacket;
    interface NetworkTopology;
    interface NetworkPage;
    interface StdControl as WDControl;
    interface WDTControl;

    interface Random;
  
    interface StatsLogger;

    event result_t SuspendDataTraffic(bool status);
  }
}


implementation
{

//#define TSF_DEBUG

/*
 * TSF_LED_DEBUG : Turn RED led if connected to RootNode
 * TSF_LED_LEVEL_DEBUG : Turn on color coding based on HopCount to Root
 * Define only one of them
 */
//#define TSF_LED_DEBUG
//#define TSF_LED_LEVEL_DEBUG
#define INVALID_HANDLE 0xFFFF

#ifndef MAX_ROOT_DISTANCE
#define MAX_ROOT_DISTANCE 7 // arbitrary
#endif

//#define TRACE_DEBUG_LEVEL DBG_USR1
#define TRACE_DEBUG_LEVEL DBG_ROUTE

  void SetNetworkDiscovery(bool active) __attribute__ ((C, spontaneous)) {
    call NetworkDiscoveryActive(active);
  }

  // Network states used by the node state machine.  Each state has at most
  // one outstanding HCI command.

  enum { NODE_STATE_INIT = 1,

         // states for TSF_FREE
         FREE_START,
         FREE_WRITE_IAC,
         FREE_WRITE_SCAN_ENABLE,
         FREE_SCAN,
         FREE_WAIT_FOR_PAGE,
         FREE_STOP_SCAN,
         FREE_PAGE_COMPLETE_WAIT_FOR_SYNC,
         FREE_SYNC_RECEIVED_WAIT_FOR_PAGE,
         FREE_PAGE_COMPLETE_SLAVE,
         FREE_PAGE_COMPLETE_SLAVE_SCAN_OFF,
         FREE_ROLE_SWITCH,
         FREE_SLAVE_CONNECTION_DONE,
         FREE_INQUIRE,
         FREE_WAIT_FOR_INQUIRY_RESULT,
         FREE_STOP_INQUIRY,
         FREE_PAGE,
         FREE_PAGE_COMPLETE_MASTER,
         FREE_DISCONNECT_PENDING_CONNECTION,

         // states for TSF_TREE
         TREE_START = 64,
         TREE_WRITE_IAC,
         TREE_WRITE_SCAN_ENABLE,
         TREE_COMM,
         TREE_SCAN,
         TREE_WAIT_FOR_PAGE,
         TREE_STOP_SCAN,
         TREE_PAGE_COMPLETE_WAIT_FOR_SYNC,
         TREE_SYNC_RECEIVED_WAIT_FOR_PAGE,
         TREE_PAGE_COMPLETE,
         TREE_PAGE_COMPLETE_SCAN_OFF,
         TREE_ROLE_SWITCH,         
         TREE_CONNECTION_DONE,
         TREE_DISCONNECT_PENDING_CONNECTION,

         DISCONNECT_ALL_NODES,

         NODE_STATE_RESET };

  // Message commands
  enum { NEW_CONNECTION_SYNC = 1,
         NEW_TREE_FOUND };


  uint32 ThisNodeID; // Unique address for this node
  uint32 RootNodeID; // ID of the root of the tree, INVALID_NODE if this node
                     // is not connected to the root
  uint32 RootNodeHopCount; // HopCount to RootNode

  int    NodeState;
  int    TSFRole;

  uint32 InquiryTime;     // inquiry time in ms

  #define MAX_HCI_RETRY 2
  int    NumRetry;

  #define GIAC 0x33
  #define FREE_IAC 0x34

  #define HCI_CMD_TIMEOUT 10000
  #define MOTE_PAGE_TIMEOUT 21000 // greater than the 20s supervisor T/O
  #define MESSAGE_TIMEOUT 10000
  #define PACKET_RETRY_TIMEOUT 1000

  //#define EXPECTED_INQUIRY_TIME 2100
  //#define DURATION 6300
  #define EXPECTED_INQUIRY_TIME 3500
  #define DURATION 7500
  //#define EXPECTED_INQUIRY_TIME 7000
  //#define DURATION 12000

  #define INVALID_NODE 0xFFFFF
  #define INVALID_HANDLE 0xFFFF
  enum { TSF_INVALID = 0, TSF_FREE, TSF_TREE };

  typedef struct tConnection {
    uint32  NodeID;
    uint32  OtherNodeType;
    uint32  OtherNodeRootNodeID;
    uint32  OtherNodeRootHopCount;
    tHandle Handle;
  } tConnection;

  tConnection PendingConnection;


  typedef void (* tStateFunc) ();
  typedef struct tTimer {
    tStateFunc  NextState;
    uint32      Time;
    bool        TimerFired;
    bool        ResetRetry;
  } tTimer;

  tTimer CurrentTimer;

  bool NodeDiscovery;

/*
 * LN : Added to enable stop network functionality, assumes the node
 * will reset to re-enable network .. State not maintained
 * Assume 8 nodes connected at most
 */
#define MAX_DISCONNECT_HANDLES 8
  bool NetworkOn;
  tHandle DisconnectHandles[MAX_DISCONNECT_HANDLES];
  bool DisconnectMap[MAX_DISCONNECT_HANDLES];
  bool DisconnectComplete;
    
  void StateFreeStart();
  void StateFreeStopScan();
  void StateFreeStopInquiry();
  void StateFreeDisconnectPendingConnection();

  void StateTreeStart();
  void StateTreeStopScan();
  void StateTreeDisconnectPendingConnection();

  void StateReset();

  void StopNetwork();

  void DisplayState(char *str) {
      trace(TRACE_DEBUG_LEVEL,"%s %d\n", str, NodeState);
  }


  void DebugLevelLED() {
     if (RootNodeID == INVALID_NODE) {
        return;
     }
     switch (RootNodeHopCount) {
        case 0 :  // Red	
           TM_ResetPio(4);
           TM_SetPio(5);
           TM_ResetPio(6);
           break;
        case 1 :  // Yellow
           TM_ResetPio(4);
           TM_SetPio(5);
           TM_SetPio(6);
           break;
        case 2 :  // Green
           TM_ResetPio(4);
           TM_ResetPio(5);
           TM_SetPio(6);
           break;
        case 3 :  // Cyan
           TM_SetPio(4);
           TM_ResetPio(5);
           TM_SetPio(6);
           break;
        default :  // Magenta
           TM_SetPio(4);
           TM_SetPio(5);
           TM_ResetPio(6);
           break;
     }
     return;
   }

  void NodeID2BD_ADDR(uint32 NodeID, tBD_ADDR *BD_ADDR) {

    BD_ADDR->byte[0] = NodeID & 0xFF;
    BD_ADDR->byte[1] = (NodeID >> 8) & 0xFF;
    BD_ADDR->byte[2] = ((NodeID >> 16) & 0x0F) | 0x80;
    BD_ADDR->byte[3] = 0x42;
    BD_ADDR->byte[4] = 0x5F;
    BD_ADDR->byte[5] = 0x4B;

  }
    


  result_t AddConnection(uint32 NodeID, tHandle Handle) {

    tBD_ADDR BD_ADDR;

    NodeID2BD_ADDR(NodeID, &BD_ADDR);
    return (call NetworkTopology.AddConnection( NodeID, Handle, BD_ADDR,
                                                FALSE, TRUE));
  }



  void FinishConnection() {
    AddConnection(PendingConnection.NodeID, PendingConnection.Handle);

    // these may need to be serialized
    call HCILinkPolicy.Write_Link_Policy_Settings(PendingConnection.Handle,0xF);
    // set supervisor timeout to 5s
    call HCIBaseband.Write_Link_Supervision_Timeout(PendingConnection.Handle,5*1600);

    signal ScatternetFormation.NodeConnected(PendingConnection.NodeID);
  }



  result_t Send2WordPacket(uint32 Dest, uint32 Data1, uint32 Data2) {

    uint32 *t;
    char *buffer;

    if ((buffer = call NetworkPacket.AllocateBuffer(8)) == NULL) return FAIL;
    t = (uint32 *) buffer;
    t[0] = Data1;
    t[1] = Data2;

    if (call NetworkPacket.Send(Dest, buffer, 8) == FAIL) {
      call NetworkPacket.ReleaseBuffer(buffer);
      return FAIL;
    }

    return SUCCESS;
  }



  result_t Send4WordPacket(uint32 Dest, uint32 D1, uint32 D2, uint32 D3, 
                           uint32 D4) {

    uint32 *t;
    char *buffer;

    if ((buffer = call NetworkPacket.AllocateBuffer(16)) == NULL) return FAIL;
    t = (uint32 *) buffer;
    t[0] = D1;
    t[1] = D2;
    t[2] = D3;
    t[3] = D4;

    if (call NetworkPacket.Send(Dest, buffer, 16) == FAIL) {
      call NetworkPacket.ReleaseBuffer(buffer);
      return FAIL;
    }

    return SUCCESS;
  }



  // Filters must be set in task context to guarantee that the BT lower level
  // has finished set up.

  task void SetUpFilters() {
    uint8   condition;

    trace(TRACE_DEBUG_LEVEL,"Setting up filters\r\n");
    condition = 0;
    call HCIBaseband.Set_Event_Filter( 0x01, // Inquiry Filter
                                       0x00, // a new device responded
                                       &condition); // condition not used

    condition = 0x01; // do NOT auto accept connection
    call HCIBaseband.Set_Event_Filter( 0x02, // Connection setup filter
                                       0x00, // all devices
                                       &condition);

    if (NodeState == NODE_STATE_INIT) StateFreeStart();

  }



  void ResetPendingConnection() {
    PendingConnection.NodeID = INVALID_NODE;
    PendingConnection.OtherNodeType = TSF_INVALID;
    PendingConnection.OtherNodeRootNodeID = INVALID_NODE;
    PendingConnection.Handle = INVALID_HANDLE;
  }



  /*
   * This routine is called in the initial states of each of the TSF roles
   * to check that the node's connections are valid for its TSF role.
   * The initial states should not have any outstanding HCI commands so they
   * are safe transition points.
   * These states are also used to transition into and out of the coordinator
   * state.
   */

  bool CheckValidState() {
    int       NumLinks;
    bool      IsSlave;

    call NetworkTopology.Get1HopDestinations(16, &NumLinks, NULL);
    IsSlave = call NetworkTopology.IsASlave(0xFFFFFFFF);

    switch (NodeState) {

      case FREE_WRITE_SCAN_ENABLE:
      case FREE_INQUIRE:
        if (NumLinks > 0) { // shouldn't be a free node
          if (!IsSlave) { // not a slave
            StateTreeStart();
          } else {
            StateTreeStart();
          }
          return FALSE;
        }
        break;

      case TREE_WRITE_SCAN_ENABLE:
      case TREE_SCAN:
      case TREE_COMM:
        if (NumLinks == 0) {
          StateFreeStart();
          return FALSE;
        }
        break;

    }

    return TRUE;
  }



  void StartTimer(uint32 Time, tStateFunc NextState, bool ResetRetry) {
    call Timer.stop();
    CurrentTimer.Time = Time;
    CurrentTimer.NextState = NextState;
    CurrentTimer.TimerFired = FALSE;
    CurrentTimer.ResetRetry = ResetRetry;
    call Timer.start(TIMER_ONE_SHOT, Time);
  }



/*
 * Start of StdControl interface
 */

  command result_t Control.init() {

    // NetworkTopology must be initialized at a higher level,
    // typically (NetworkCommand)

    call BTLowerLevelControl.init();
    call NetworkTopology.GetNodeID ( &ThisNodeID );

    // global variable used to seed the Random number generator
    atomic TOS_LOCAL_ADDRESS = ThisNodeID & 0xFFFF;
    call Random.init();

    call NetworkPage.Initialize();
    call WDControl.init();

    post SetUpFilters(); // does this need to move to start?
    NodeState = NODE_STATE_INIT;
    TSFRole = TSF_INVALID;
    CurrentTimer.TimerFired = FALSE;

    RootNodeID = INVALID_NODE;
    NodeDiscovery = TRUE;

    NetworkOn = false;
    DisconnectComplete = false;

    return SUCCESS;
  }



  command result_t Control.start() {

    call BTLowerLevelControl.start();
    call WDControl.start();
    NetworkOn = true;

    return SUCCESS;

  }



  command result_t Control.stop() {

    call BTLowerLevelControl.stop();
    call Timer.stop();
    call WDControl.stop();
    NetworkOn = false;
    StopNetwork();
    trace(TRACE_DEBUG_LEVEL,"Stop Network\n");

    return SUCCESS;
  }

/*
 * End of StdControl interface
 */



/*
 * Start of ScatternetFormation interface
 */

  command result_t ScatternetFormation.SuspendNodeDiscovery() {
    NodeDiscovery = FALSE;
    return SUCCESS;
  }

  command result_t ScatternetFormation.ResumeNodeDiscovery() {
    NodeDiscovery = TRUE;
    return SUCCESS;
  }


  command result_t ScatternetFormation.EnablePageScan() {
    return SUCCESS;
  }

  command result_t ScatternetFormation.DisableScan() {
    return SUCCESS;
  }

  command result_t ScatternetFormation.PageNode(uint32 NodeID) {
    return SUCCESS;
  }

/*
 * End of ScatternetFormation interface
 */



  command result_t NetworkDiscoveryActive(bool DiscoveryActive) {
    NodeDiscovery = DiscoveryActive;
    return SUCCESS;
  }



/*
 * Node state routines
 */



  void StateFreeWriteIAC() {
    tLAP Lap;

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = FREE_WRITE_IAC;
      trace(TRACE_DEBUG_LEVEL,"State - Free Write IAC\n");
      NumRetry++;

      Lap.byte[0] = FREE_IAC;
      Lap.byte[1] = 0x8b;
      Lap.byte[2] = 0x9e;

      call HCIBaseband.Write_Current_IAC_LAP(1, Lap);
      StartTimer(HCI_CMD_TIMEOUT, StateFreeWriteIAC, FALSE);
    } else {
      StateReset();
    }
  }



  void StateFreeStart() {

    NodeState = FREE_START;
    TSFRole = TSF_FREE;

#ifdef TSF_LED_DEBUG
  TM_ResetPio(5);
#endif // TSF_LED_DEBUG


    if (call NetworkTopology.IsPropertySupported(ThisNodeID, 
               NETWORK_PROPERTY_CLUSTER_HEAD)) {
       RootNodeID = ThisNodeID;
       RootNodeHopCount = 0;
    }

    NumRetry = 0;
    StateFreeWriteIAC();

  }



  void StateFreeWriteScanEnable() {

    NodeState = FREE_WRITE_SCAN_ENABLE;

    if (CheckValidState() == FALSE) return;

    if (NumRetry < MAX_HCI_RETRY) {
      trace(TRACE_DEBUG_LEVEL,"State - Free write scan enable\n");
      NumRetry++;

      ResetPendingConnection();
      signal SuspendDataTraffic(FALSE);

      call HCIBaseband.Write_Scan_Enable(3);
      StartTimer(HCI_CMD_TIMEOUT, StateFreeWriteScanEnable, FALSE);
    } else {
      StateReset();
    }

  }



  void StateFreeScan() {
    uint32 Time;

    NodeState = FREE_SCAN;
    trace(TRACE_DEBUG_LEVEL,"State - Free Scan\n");
    Time = EXPECTED_INQUIRY_TIME +
           (((call Random.rand()) * (DURATION - EXPECTED_INQUIRY_TIME)) >> 16);
    StartTimer(Time, StateFreeStopScan, TRUE);
  }



  void StateFreeWaitForPage(tBD_ADDR BD_ADDR) {

    NodeState = FREE_WAIT_FOR_PAGE;
    trace(TRACE_DEBUG_LEVEL,"State - Free Wait For Page \n");

    // Only respond to iMote nodes
    if ((BD_ADDR.byte[5] == 0x4B) && (BD_ADDR.byte[4] == 0x5F) &&
        (BD_ADDR.byte[3] == 0x42) && ((BD_ADDR.byte[2] & 0xF0)==0x80)) {

      PendingConnection.NodeID = ((BD_ADDR.byte[2] & 0xF) << 16) |
                               (BD_ADDR.byte[1] << 8) | (BD_ADDR.byte[0]);

      call HCILinkControl.Accept_Connection_Request( BD_ADDR, 0x1);
    } else {
      call HCILinkControl.Reject_Connection_Request( BD_ADDR, 0x1F);
    }
    StartTimer(MOTE_PAGE_TIMEOUT, StateFreeStopScan, TRUE);
  }



  void StateFreeSyncReceivedWaitForPage() {
    NodeState = FREE_SYNC_RECEIVED_WAIT_FOR_PAGE;
    StartTimer(MOTE_PAGE_TIMEOUT, StateFreeStopScan, TRUE);
  }



  void StateFreePageCompleteWaitForSync(uint32 NodeID, tHandle Handle) {
    NodeState = FREE_PAGE_COMPLETE_WAIT_FOR_SYNC;
    trace(TRACE_DEBUG_LEVEL,"State - Free Page Complete Wait For Sync\n");
    StartTimer(MOTE_PAGE_TIMEOUT, StateFreeStopScan, TRUE);

    PendingConnection.NodeID = NodeID;
    PendingConnection.Handle = Handle;
    AddConnection(NodeID, Handle);
  }



  void StateFreeStopScan() {
    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = FREE_STOP_SCAN;
      trace(TRACE_DEBUG_LEVEL,"State - Free Stop Scan\n");
      NumRetry++;

      call HCIBaseband.Write_Scan_Enable(0);
      StartTimer(HCI_CMD_TIMEOUT, StateFreeStopScan, FALSE);
    } else {
      StateReset();
    }
  }


  void StateFreePageCompleteSlave() {

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = FREE_PAGE_COMPLETE_SLAVE;
      trace(TRACE_DEBUG_LEVEL,"State - Free Page Complete Slave\n");
      NumRetry++;

      AddConnection(PendingConnection.NodeID, PendingConnection.Handle);
      call HCIBaseband.Write_Scan_Enable(0);
      StartTimer(HCI_CMD_TIMEOUT, StateFreePageCompleteSlave, FALSE);
    } else {
      StateReset();
    }

  }



  void StateFreeSlaveConnectionDone() {

    NodeState = FREE_SLAVE_CONNECTION_DONE;
    FinishConnection();
    call NetworkTopology.UpdateConnectionRole(PendingConnection.Handle, TRUE);
    Send4WordPacket(PendingConnection.NodeID, NEW_CONNECTION_SYNC, TSFRole, RootNodeID, RootNodeHopCount); 

    StartTimer(MESSAGE_TIMEOUT, StateFreeDisconnectPendingConnection, TRUE);

  }



  void StateFreeRoleSwitch() {
    tBD_ADDR BD_ADDR;

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = FREE_ROLE_SWITCH;
      trace(TRACE_DEBUG_LEVEL,"State - Free Role Switch\n");
      NumRetry++;

      NodeID2BD_ADDR(PendingConnection.NodeID, &BD_ADDR);
      // try to become the master
      call HCILinkPolicy.Switch_Role (BD_ADDR, 0x0);
      StartTimer( HCI_CMD_TIMEOUT, StateFreeRoleSwitch, FALSE);
    } else {
      NumRetry = 0;
      StateFreeDisconnectPendingConnection();
    }
  }



  void StateFreePageCompleteSlaveScanOff() {
    // no need to set an initial state since it will change below
    if (PendingConnection.OtherNodeType == TSF_FREE) {
      if (ThisNodeID == RootNodeID) {
        StateFreeRoleSwitch();
      } else if (PendingConnection.OtherNodeRootNodeID != INVALID_NODE) {
        RootNodeID = PendingConnection.OtherNodeRootNodeID;
        RootNodeHopCount = PendingConnection.OtherNodeRootHopCount + 1;
        StateFreeSlaveConnectionDone();
      } else {
        NumRetry = 0;
        StateFreeDisconnectPendingConnection();
      }
    } else {
      NumRetry = 0;
      StateFreeDisconnectPendingConnection();
    }
  }



  void StateFreeInquire() {
    tLAP    Lap;
    uint8   Duration; // inquiry duration in 1.28 sec increments

    NodeState = FREE_INQUIRE;

    if (CheckValidState() == FALSE) return;

    if (NumRetry < MAX_HCI_RETRY) {
      trace(TRACE_DEBUG_LEVEL,"State - Free Inquire\n");
      NumRetry++;

      ResetPendingConnection();
//      signal SuspendDataTraffic(TRUE);
      Lap.byte[0] = FREE_IAC;
      Lap.byte[1] = 0x8b;
      Lap.byte[2] = 0x9e;

      // Calculation is not precise, but it avoids the divide
      InquiryTime = EXPECTED_INQUIRY_TIME +
           (((call Random.rand()) * (DURATION - EXPECTED_INQUIRY_TIME)) >> 16);
      Duration = InquiryTime / 1280;
      InquiryTime <<= 1;

      // come back as soon as the first is discovered
      call HCILinkControl.Inquiry( Lap, Duration, 1);
      //StartTimer(HCI_CMD_TIMEOUT, StateFreeInquire, FALSE);
      StartTimer(InquiryTime, StateFreeWriteScanEnable, TRUE);
    } else {
      StateReset();
    }

    return;
  }



  void StateFreeWaitForInquiryResult() {

    NodeState = FREE_WAIT_FOR_INQUIRY_RESULT;
    trace(TRACE_DEBUG_LEVEL,"State - Free Wait For Inquiry Result \n");
    StartTimer(InquiryTime, StateFreeStopInquiry, TRUE);

  }



  void StateFreeStopInquiry() {

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = FREE_STOP_INQUIRY;
      trace(TRACE_DEBUG_LEVEL,"State - Free Stop Inquiry\n");
      NumRetry++;

      call HCILinkControl.Inquiry_Cancel ();
      StartTimer(HCI_CMD_TIMEOUT, StateFreeStopInquiry, FALSE);
    } else {
      StateReset();
    }

  }



  void StateFreePage( tBD_ADDR *pBD, uint8 *PSRM, uint8 *PSM, uint16 *Offset) {

    uint32   NodeID;
    result_t res;

    NodeState = FREE_PAGE;
    
    trace(TRACE_DEBUG_LEVEL,"State - Free Page %01X%02X%02X\n", pBD->byte[2] & 0xF, pBD->byte[1], pBD->byte[0]);
    
    if ((pBD->byte[5] == 0x4B) && (pBD->byte[4] == 0x5F) &&
        (pBD->byte[3] == 0x42) && ((pBD->byte[2] & 0xF0)==0x80)) {

      NodeID = ((pBD->byte[2] & 0xF) << 16) |
                (pBD->byte[1] << 8) | (pBD->byte[0]);

      signal SuspendDataTraffic(FALSE);
      res = call NetworkPage.PageNodeWithOffset( NodeID, *PSRM, *PSM, *Offset);
      if (res  == SUCCESS) {
        PendingConnection.NodeID = NodeID;

// don't timeout, wait for a reply from the lower level
// VEH - is this a timer problem?
//        StartTimer(MOTE_PAGE_TIMEOUT, StateFreeWriteScanEnable, TRUE);
call Timer.stop();

      } else {
        NumRetry = 0;
        StateFreeWriteScanEnable();
      }
    } else { // other node is not an imote
      NumRetry = 0;
      StateFreeWriteScanEnable();
    }

  }


  void StateFreePageCompleteMaster() {
    NodeState = FREE_PAGE_COMPLETE_MASTER;
    
    trace(TRACE_DEBUG_LEVEL,"State - Free Page Complete Master %05X\n", PendingConnection.NodeID);

    //    trace(TRACE_DEBUG_LEVEL,"State - Free Page Complete Master\n");

    PendingConnection.OtherNodeType = TSF_INVALID;

    AddConnection(PendingConnection.NodeID, PendingConnection.Handle);
    call NetworkTopology.UpdateConnectionRole(PendingConnection.Handle, FALSE);
    if ( Send4WordPacket(PendingConnection.NodeID, NEW_CONNECTION_SYNC, TSFRole, RootNodeID, RootNodeHopCount)
         == FAIL) {
      NumRetry = 0;
      StateFreeDisconnectPendingConnection();
    } else {
      StartTimer(MESSAGE_TIMEOUT, StateFreeDisconnectPendingConnection, TRUE);
    }
  }



  void StateFreeDisconnectPendingConnection() {

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = FREE_DISCONNECT_PENDING_CONNECTION;
      trace(TRACE_DEBUG_LEVEL,"State - Free Disconnect Pending\n");
      NumRetry++;
      if (PendingConnection.Handle != INVALID_HANDLE) {
        call HCILinkControl.Disconnect( PendingConnection.Handle, 0x13 );
        StartTimer( HCI_CMD_TIMEOUT, StateFreeDisconnectPendingConnection,
                    FALSE);
      } else {
        // There may be more node which are trying to page this one so restart
        // in the scan state
        StateFreeWriteScanEnable();
        // don't know if last task was scanning or inquiring so randomly select
        // StateFreeStart();
      }
    } else {
      StateReset();
    }
  }



  void StateTreeWriteIAC() {
    tLAP Lap;

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = TREE_WRITE_IAC;
      trace(TRACE_DEBUG_LEVEL,"State - Tree Write IAC\n");
      NumRetry++;

      Lap.byte[0] = FREE_IAC;
      Lap.byte[1] = 0x8b;
      Lap.byte[2] = 0x9e;

      call HCIBaseband.Write_Current_IAC_LAP(1, Lap);
      StartTimer( HCI_CMD_TIMEOUT, StateTreeWriteIAC, FALSE);
    } else {
      StateReset();
    }
  }



  void StateTreeStart() {
    NodeState = TREE_START;
    TSFRole = TSF_TREE;
    trace(TRACE_DEBUG_LEVEL,"State - Tree Start\n");
    NumRetry = 0;
    StateTreeWriteIAC();
  }



  void StateTreeWriteScanEnable() {

    NodeState = TREE_WRITE_SCAN_ENABLE;

    if (CheckValidState() == FALSE) return;

    if (NumRetry < MAX_HCI_RETRY) {
      trace(TRACE_DEBUG_LEVEL,"State - Tree write scan enable\n");
      NumRetry++;

      ResetPendingConnection();
      signal SuspendDataTraffic(FALSE);

      call HCIBaseband.Write_Scan_Enable(3);
      StartTimer( HCI_CMD_TIMEOUT, StateTreeWriteScanEnable, FALSE);
    } else {
      StateReset();
    }

  }



  void StateTreeComm() {
    uint32 Time;

    NodeState = TREE_COMM;

    if (CheckValidState() == FALSE) return;

    trace(TRACE_DEBUG_LEVEL,"State - Tree Comm\n");

    signal SuspendDataTraffic(FALSE);
#ifdef TSF_LED_DEBUG
if (RootNodeID == INVALID_NODE) {
  TM_ResetPio(5);
} else {
  TM_SetPio(5);
}
#endif // TSF_DEBUG

#ifdef TSF_LED_LEVEL_DEBUG
  DebugLevelLED(); 
#endif

    Time = EXPECTED_INQUIRY_TIME +
           (((call Random.rand()) * (DURATION - EXPECTED_INQUIRY_TIME)) >> 16);
    if (NodeDiscovery == TRUE) {
      StartTimer( Time, StateTreeWriteScanEnable, TRUE);
    } else {
      StartTimer( Time, StateTreeComm, TRUE);
    }
  }



  void StateTreeScan() {
    uint32 Time;

    NodeState = TREE_SCAN;

    // need to add the check here as well as in the write scan enable state
    // since tree nodes will stay in the scan state full time.  This is the
    // entry point for full time scanning.

    if (CheckValidState() == FALSE) return;


    trace(TRACE_DEBUG_LEVEL,"State - Tree Scan\n");
    Time = EXPECTED_INQUIRY_TIME +
           (((call Random.rand()) * (DURATION - EXPECTED_INQUIRY_TIME)) >> 16);
    if (NodeDiscovery == TRUE) {
      // stay in scan mode full time to increase likelihood of connections
      StartTimer( Time, StateTreeScan, TRUE);
    } else {
      StartTimer( Time, StateTreeStopScan, TRUE);
    }
#ifdef TSF_LED_DEBUG
if (RootNodeID == INVALID_NODE) {
  TM_ResetPio(5);
} else {
  TM_SetPio(5);
}
#endif // TSF_DEBUG

#ifdef TSF_LED_LEVEL_DEBUG
  DebugLevelLED(); 
#endif
  }



  void StateTreeWaitForPage(tBD_ADDR BD_ADDR) {

    NodeState = TREE_WAIT_FOR_PAGE;
    trace(TRACE_DEBUG_LEVEL,"State - Tree Wait For Page \n");

    // Only respond to iMote nodes
    if ((BD_ADDR.byte[5] == 0x4B) && (BD_ADDR.byte[4] == 0x5F) &&
        (BD_ADDR.byte[3] == 0x42) && ((BD_ADDR.byte[2] & 0xF0)==0x80)) {

      PendingConnection.NodeID = ((BD_ADDR.byte[2] & 0xF) << 16) |
                               (BD_ADDR.byte[1] << 8) | (BD_ADDR.byte[0]);

      call HCILinkControl.Accept_Connection_Request( BD_ADDR, 0x1);
    } else {
      call HCILinkControl.Reject_Connection_Request( BD_ADDR, 0x1F);
    }
    StartTimer( MOTE_PAGE_TIMEOUT, StateTreeStopScan, TRUE);
  }



  void StateTreeSyncReceivedWaitForPage() {
    NodeState = TREE_SYNC_RECEIVED_WAIT_FOR_PAGE;
    trace(TRACE_DEBUG_LEVEL,"State - Tree Sync Received Wait For Page\n");
    StartTimer( MOTE_PAGE_TIMEOUT, StateTreeStopScan, TRUE);
  }



  void StateTreePageCompleteWaitForSync(uint32 NodeID, tHandle Handle) {
    NodeState = TREE_PAGE_COMPLETE_WAIT_FOR_SYNC;
    trace(TRACE_DEBUG_LEVEL,"State - Tree Page Complete Wait For Sync\n");
    StartTimer( MOTE_PAGE_TIMEOUT, StateTreeStopScan, TRUE);
    AddConnection(NodeID, Handle);
    PendingConnection.NodeID = NodeID;
    PendingConnection.Handle = Handle;
  }



  void StateTreeStopScan() {
    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = TREE_STOP_SCAN;
      trace(TRACE_DEBUG_LEVEL,"State - Tree Stop Scan\n");
      NumRetry++;

      call HCIBaseband.Write_Scan_Enable(0);
      StartTimer( HCI_CMD_TIMEOUT, StateTreeStopScan, FALSE);
    } else {
      StateReset();
    }
  }



  void StateTreePageComplete() {

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = TREE_PAGE_COMPLETE;
      trace(TRACE_DEBUG_LEVEL,"State - Tree Page Complete\n");
      NumRetry++;

      AddConnection(PendingConnection.NodeID, PendingConnection.Handle);
      call HCIBaseband.Write_Scan_Enable(0);
      StartTimer( HCI_CMD_TIMEOUT, StateTreePageComplete, FALSE);
    } else {
      StateReset();
    }

  }



  void StateTreeRoleSwitch() {
    tBD_ADDR BD_ADDR;
#if 0
tHandle MasterHandle;
#endif

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = TREE_ROLE_SWITCH;
      NumRetry++;

      NodeID2BD_ADDR(PendingConnection.NodeID, &BD_ADDR);
      trace(TRACE_DEBUG_LEVEL,"State - Tree Role Switch with %0X\n", PendingConnection.NodeID);
      
      // try to become the master
#if 0
if (ThisNodeID != RootNodeID) {
call NetworkTopology.GetNextConnection( RootNodeID, NULL, &MasterHandle);
call HCILinkPolicy.Park_Mode( MasterHandle,
                                  5000 * 1.6, // max
                                  5000);  // min
}
#endif
      call HCILinkPolicy.Switch_Role (BD_ADDR, 0x0);
      StartTimer( HCI_CMD_TIMEOUT, StateTreeRoleSwitch, FALSE);
    } else {
      NumRetry = 0;
      StateTreeDisconnectPendingConnection();
    }
  }



  void StateTreePageCompleteScanOff() {
    // no need to set an initial state since it will change below
    if ((PendingConnection.OtherNodeType == TSF_FREE) &&
        (RootNodeID != INVALID_NODE)) {
      // free node is joining an island so become master
      NumRetry = 0;
      StateTreeRoleSwitch();
    } else {
      NumRetry = 0;
      StateTreeDisconnectPendingConnection();
    }
  }



  void StateTreeConnectionDone() {

    NodeState = TREE_CONNECTION_DONE;
    trace(TRACE_DEBUG_LEVEL,"State - Tree Connection Done\n");
    FinishConnection();
    if (PendingConnection.OtherNodeType == TSF_FREE) {
      call NetworkTopology.UpdateConnectionRole(PendingConnection.Handle,FALSE);
    } else {
      trace(TRACE_DEBUG_LEVEL,"Non-free node merging with Tree node\n");
    }
    Send4WordPacket(PendingConnection.NodeID, NEW_CONNECTION_SYNC, TSFRole, RootNodeID, RootNodeHopCount); 

    StartTimer( MESSAGE_TIMEOUT, StateTreeDisconnectPendingConnection, TRUE);

  }



  void StateTreeDisconnectPendingConnection() {

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = TREE_DISCONNECT_PENDING_CONNECTION;
      trace(TRACE_DEBUG_LEVEL,"State - Tree Disconnect Pending\n");
      NumRetry++;
      if (PendingConnection.Handle != INVALID_HANDLE) {
        call HCILinkControl.Disconnect( PendingConnection.Handle, 0x13 );
        StartTimer( HCI_CMD_TIMEOUT, StateTreeDisconnectPendingConnection,
                    FALSE);
      } else {
        // don't know if last task was scanning or inquiring so randomly select
        StateTreeStart();
      }
    } else {
      StateReset();
    }
  }


  /*
   * LN : This function retrieves all the connection handles, populates the
   * disconnect array and starts the disconnection process
   */
  void StopNetwork() {
    uint32 NodeList[MAX_DISCONNECT_HANDLES], NumReturned, NextNode;
    tHandle Handle;
    uint8 i;

    call NetworkTopology.Get1HopDestinations( MAX_DISCONNECT_HANDLES, 
                                              &NumReturned, &(NodeList[0]));

    if (NumReturned == 0) {
       DisconnectComplete = true;
       return;
    }

    for (i=NumReturned; i<MAX_DISCONNECT_HANDLES; i++) {
       DisconnectMap[i] = true;
    }
    for (i=0; i<NumReturned; i++) {
       call NetworkTopology.GetNextConnection(NodeList[i],&NextNode,&Handle);
       DisconnectMap[i] = false;
       DisconnectHandles[i] = Handle;
    }

    call HCILinkControl.Disconnect(DisconnectHandles[0], 0x13);
    call Timer.start(TIMER_ONE_SHOT, 10000);
  }

  void RemoveDisconnectHandle(tHandle handle) {
    uint8 i;
    for (i=0; i<MAX_DISCONNECT_HANDLES; i++) {
       if (DisconnectHandles[i] == handle) {
          DisconnectMap[i] = true;
          return;
       }
    }
  }

  task void ProcessNextDisconnect() {
    uint8 i;
    for (i=0; i<MAX_DISCONNECT_HANDLES; i++) {
       if (DisconnectMap[i] == false) {
          trace(TRACE_DEBUG_LEVEL,"disconnect\n");
          call HCILinkControl.Disconnect(DisconnectHandles[i], 0x13);
          call Timer.stop();
          call Timer.start(TIMER_ONE_SHOT, 10000);
          return;
       }
    }
    // All nodes disconnected
    DisconnectComplete = true;
    //call NetworkPage.DisableScan();
  }

  void StateDisconnectAllNodes() {
    uint32 NodeList[16], NumReturned, NextNode;
    tHandle Handle;

    if (NumRetry < MAX_HCI_RETRY) {
      NodeState = DISCONNECT_ALL_NODES;
      trace(TRACE_DEBUG_LEVEL,"State - Disconnect All Nodes\n");
      NumRetry++;

      call NetworkTopology.Get1HopDestinations( 16, &NumReturned,
                                                &(NodeList[0]));

      if (NumReturned == 0) {
        StateFreeStart();
        return;
      }

      call NetworkTopology.GetNextConnection(NodeList[0], &NextNode, &Handle);
      call HCILinkControl.Disconnect(Handle, 0x13);
      StartTimer( HCI_CMD_TIMEOUT, StateDisconnectAllNodes, FALSE);
    } else {
      StateReset();
    }
  }



  void StateReset() {
    NodeState = NODE_STATE_RESET;
    trace(TRACE_DEBUG_LEVEL,"State - Reset\n");
    call WDTControl.AllowForceReset();
  }


/*
 * Start of HCILinkControl interface
 */

  event result_t HCILinkControl.Command_Status_Inquiry(uint8 Status) {

    if (!NetworkOn) {
        trace(TRACE_DEBUG_LEVEL,"Network Off-IS\n");
        return SUCCESS;
    }

    if (Status != 0) {
        trace(TRACE_DEBUG_LEVEL,"Inquiry failed, status = %d\n", Status);
    }
    if (NodeState == FREE_INQUIRE) {
      if (Status != 0) {
        StateFreeInquire();
      } else {
        StateFreeWaitForInquiryResult();
      } 
    } else {
      DisplayState("Error - Command Status Inquiry in state ");
    }

    return SUCCESS;
  }



  /*
   * Respond to inquiry results.  This component only acknowledges the
   * first response.
   */

  event result_t HCILinkControl.Inquiry_Result( uint8 Num_Responses,
                                                tBD_ADDR *BD_ADDR_ptr,
                                                uint8 *PSRM_ptr,
                                                uint8 *Page_Scan_Period_Mode,
                                                uint8 *Page_Scan_Mode,
                                                uint32 *Class_of_Device,
                                                uint16 *Clock_Offset) {

    if (!NetworkOn) {
        trace(TRACE_DEBUG_LEVEL,"Network Off-IR\n");
        return SUCCESS;
    }

    switch (NodeState) {

      case FREE_INQUIRE:
      case FREE_WAIT_FOR_INQUIRY_RESULT:
        StateFreePage( BD_ADDR_ptr, PSRM_ptr, Page_Scan_Mode, Clock_Offset);
        break;

      default:
        DisplayState("Error - Inquiry Result in state");
    }

    return SUCCESS;

  }



  event result_t HCILinkControl.Inquiry_Complete( uint8 Status ) {

    if (!NetworkOn) {
        trace(TRACE_DEBUG_LEVEL,"Network Off-IC\n");
        return SUCCESS;
    }

    switch (NodeState) {
      case FREE_INQUIRE:
      case FREE_WAIT_FOR_INQUIRY_RESULT:
      case FREE_STOP_INQUIRY:
        NumRetry = 0;
        StateFreeWriteScanEnable();
        break;

      case FREE_PAGE:
        // do nothing since the inquiry complete may come after the inquiry
        // result already caused a transition to the Free Page state
        break;

      default:
        DisplayState("Error - Inquiry Complete in state");
    }

    return SUCCESS;
  }



  event result_t HCILinkControl.Command_Complete_Inquiry_Cancel(uint8 Status) {

    if (!NetworkOn) {
        trace(TRACE_DEBUG_LEVEL,"Network Off-CCIC\n");
        return SUCCESS;
    }

    if (Status != 0) {
        trace(TRACE_DEBUG_LEVEL,"Inquiry cancel status %d\n", Status);
    }
    if (NodeState == FREE_STOP_INQUIRY) {
      if (Status == 0) {
        NumRetry = 0;
        StateFreeWriteScanEnable();
      } else {
        StateFreeStopInquiry();
      }
    } else {
      DisplayState("Error - Inquiry Cancel Complete in state");
    }
    return SUCCESS;

  }



  event result_t HCILinkControl.Connection_Complete( uint8 Status,
                                                     tHandle Connection_Handle,
                                                     tBD_ADDR BD_ADDR,
                                                     uint8 Link_Type,
                                                     uint8 Encryption_Mode) {
    return SUCCESS;
  }



  event result_t HCILinkControl.Connection_Request( tBD_ADDR BD_ADDR,
                                                    //3 bytes meaningful
                                                    uint32 Class_of_Device,
                                                    uint8 Link_Type) {

      uint32 NodeID;

    if (!NetworkOn) {
        call HCILinkControl.Reject_Connection_Request( BD_ADDR, 0x1F);
        trace(TRACE_DEBUG_LEVEL,"Network Off-CR\n");
        call NetworkPage.DisableScan();
        return SUCCESS;
    }

    switch (NodeState) {

      case FREE_SCAN:
        NumRetry = 0;
        StateFreeWaitForPage(BD_ADDR);
        break;

      // already processing a request so reject this one
      case FREE_WAIT_FOR_PAGE:
      case FREE_SYNC_RECEIVED_WAIT_FOR_PAGE:
        NodeID = BD_ADDR.byte[0] | (BD_ADDR.byte[1] << 8) |
                 ((BD_ADDR.byte[2] & 0x0F) << 16);
        trace(TRACE_DEBUG_LEVEL,
              "Connection request from %0X. Waiting for page complete from %0X\n", 
              NodeID, PendingConnection.NodeID);

        // fall through is intentional
      case FREE_PAGE_COMPLETE_WAIT_FOR_SYNC:
      case FREE_PAGE_COMPLETE_SLAVE:

      // response took too long so drop it
      case FREE_STOP_SCAN:
        call HCILinkControl.Reject_Connection_Request( BD_ADDR, 0x1F);
        break;

      case TREE_SCAN:
        NumRetry = 0;
        StateTreeWaitForPage(BD_ADDR);
        break;

      // already processing a request so reject this one
      case TREE_WAIT_FOR_PAGE:
      case TREE_SYNC_RECEIVED_WAIT_FOR_PAGE:
        NodeID = BD_ADDR.byte[0] | (BD_ADDR.byte[1] << 8) |
                 ((BD_ADDR.byte[2] & 0x0F) << 16);
        trace(TRACE_DEBUG_LEVEL,
              "Connection request from %0X. Waiting for page complete from %0X\n", 
              NodeID, PendingConnection.NodeID);
        // fall through is intentional
      case TREE_PAGE_COMPLETE_WAIT_FOR_SYNC:
      case TREE_PAGE_COMPLETE:

      // response took too long so drop it
      case TREE_STOP_SCAN:
        call HCILinkControl.Reject_Connection_Request( BD_ADDR, 0x1F);
        break;

      default:
        call HCILinkControl.Reject_Connection_Request( BD_ADDR, 0x1F);
        DisplayState("Error - Connection Request in state");
    }

    return SUCCESS;

  }



  event result_t HCILinkControl.Disconnection_Complete( uint8 Status,
                                                        tHandleId Handle,
                                                        uint8 Reason) {

    tHandle MasterHandle;
    uint32 DisconnectedNode;

    if (!NetworkOn) {
        trace(TRACE_DEBUG_LEVEL,"Network Off-DC\n");
        call Timer.stop();
        RemoveDisconnectHandle(Handle);
        post ProcessNextDisconnect();
        return SUCCESS;
    }

    trace(TRACE_DEBUG_LEVEL,"Disconnect complete status = %d, reason = %d\n\r", Status, Reason);
    
    MasterHandle = INVALID_HANDLE;
    call NetworkTopology.GetNextConnection( RootNodeID, NULL, &MasterHandle);
    call NetworkTopology.NextHandle2NodeID(Handle, &DisconnectedNode);
    call NetworkTopology.RemoveConnection(Handle, FALSE);

    if ((MasterHandle != INVALID_HANDLE) && (ThisNodeID != RootNodeID) &&
        (RootNodeID != INVALID_NODE) && (MasterHandle == Handle)) {
      // lost path to the root
      RootNodeID = INVALID_NODE;
      NumRetry = 0;
      StateDisconnectAllNodes();
      return SUCCESS;
    }
      
    if (Handle == PendingConnection.Handle) {
      switch (NodeState) {
        case FREE_PAGE_COMPLETE_WAIT_FOR_SYNC:
          // master couldn't send sync so it disconnected
        case FREE_PAGE_COMPLETE_MASTER:
          // other node rejected the connection so start over
        case FREE_DISCONNECT_PENDING_CONNECTION:
          if (Status == 0) {
            // There may be more nodes which are trying to page this one so
            // restart in the scan state
            StateFreeWriteScanEnable();
            // StateFreeStart();
          } else {
            NumRetry = 0;
            StateFreeDisconnectPendingConnection();
          }
          break;

        case TREE_PAGE_COMPLETE_WAIT_FOR_SYNC:
          // master couldn't send sync so it disconnected
        case TREE_DISCONNECT_PENDING_CONNECTION:
          if (Status == 0) {
            StateTreeStart();
          } else {
            StateTreeDisconnectPendingConnection();
          }
          break;

        case DISCONNECT_ALL_NODES:
          NumRetry = 0;
          StateDisconnectAllNodes();
          break;

        default:
          DisplayState("Error - Disconnection Complete in state ");
      }
    } // Check ValidState will update TSF role based on active connections
    else {
        signal ScatternetFormation.NodeDisconnected(DisconnectedNode);
    }

    return SUCCESS;
  }

/*
 * End of HCILinkControl interface
 */



/*
 * Start of HCILinkPolicy interface
 */

  event result_t HCILinkPolicy.Role_Change( uint8 Status,
                                            tBD_ADDR BD_ADDR,
                                            uint8 New_Role) {

    tHandle Handle;
    uint32 NodeID;

    if (!NetworkOn) {
        trace(TRACE_DEBUG_LEVEL,"Network Off-RC\n");
        return SUCCESS;
    }

    switch (NodeState) {
      case FREE_PAGE_COMPLETE_MASTER:
        // do nothing, this node paged a tree node and needs to become a slave
        break;

      case FREE_ROLE_SWITCH:
        if (Status == 0) {
          StateFreeSlaveConnectionDone();
        } else {
          StateFreeRoleSwitch();
        }
        break;

      case TREE_ROLE_SWITCH:
        if (Status == 0) {
          StateTreeConnectionDone();
        } else {
            
            trace(TRACE_DEBUG_LEVEL,"Role Change status = %d in Tree Role Switch\n", Status);
            StateTreeRoleSwitch();
        }
        break;

      default:
        DisplayState("Error - Role change complete in state ");
        StateReset();
    }

    NodeID = ((BD_ADDR.byte[2] & 0xF) << 16) |
              (BD_ADDR.byte[1] << 8) | (BD_ADDR.byte[0]);
    if (call NetworkTopology.GetNextConnection(NodeID, NULL, &Handle)
         == SUCCESS) {

      if (New_Role == 0x0) { // currently master
        call NetworkTopology.UpdateConnectionRole(Handle, FALSE);
      } else { // slave
        call NetworkTopology.UpdateConnectionRole(Handle, TRUE);
      }
    }

    return SUCCESS;
  }

  event result_t HCILinkPolicy.Command_Complete_Role_Discovery( uint8 Status,
                                                                tHandle Handle,
                                                                uint8 Role) {
    return SUCCESS;
  }

  event result_t HCILinkPolicy.Mode_Change( uint8 Status,
                                            uint16 Connection_Handle,
                                            uint8 Current_Mode,
                                            uint16 Interval) {

    switch (NodeState) {
      default:
        // Park mode may timeout during many states.
        // Packets are buffered so don't log an error 
    }
 
    return SUCCESS;
  }

/*
 * End of HCILinkPolicy interface
 */



/*
 * Start of HCIBaseband interface
 */


  event result_t HCIBaseband.Command_Complete_Write_Scan_Enable(uint8 Status) {

    if (!NetworkOn) {
        trace(TRACE_DEBUG_LEVEL,"Network Off-CCWSE\n");
        return SUCCESS;
    }

    switch (NodeState) {
      case FREE_WRITE_SCAN_ENABLE:
        if (Status == 0) {
          StateFreeScan();
        } else {
          StateFreeWriteScanEnable();
        }
        break;

      case FREE_STOP_SCAN:
        if (Status == 0) {
          NumRetry = 0;
          StateFreeInquire();
        } else {
          StateFreeStopScan();
        }
        break;

      case FREE_PAGE_COMPLETE_SLAVE:
        if (Status == 0) {
          StateFreePageCompleteSlaveScanOff();
        } else {
          StateFreePageCompleteSlave();
        }
        break;

      case TREE_WRITE_SCAN_ENABLE:
        if (Status == 0) {
          StateTreeScan();
        } else {
          StateTreeWriteScanEnable();
        }
        break;

      case TREE_STOP_SCAN:
        if (Status == 0) {
          NumRetry = 0;
          StateTreeComm();
        } else {
          StateTreeStopScan();
        }
        break;

      case TREE_PAGE_COMPLETE:
        if (Status == 0) {
          StateTreePageCompleteScanOff();
        } else {
          StateTreePageComplete();
        }
        break;

      default:
        DisplayState("Error - Write Scan Enable Complete in state");
    }

    return SUCCESS;
  }



  event result_t HCIBaseband.Command_Complete_Read_Link_Supervision_Timeout(
                             uint8 Reason,
                             tHandle Connection_Handle,
                             uint16 Timeout ) {
    return SUCCESS;
  }



  event result_t HCIBaseband.Command_Complete_Write_Current_IAC_LAP(uint8 Res) {

    if (!NetworkOn) {
        trace(TRACE_DEBUG_LEVEL,"Network Off-CCWI\n");
        return SUCCESS;
    }

    switch (NodeState) {

      case FREE_WRITE_IAC:
        if (Res == 0) {
          if (call Random.rand() & 0x1) {
            NumRetry = 0;
            StateFreeWriteScanEnable();
          } else {
            NumRetry = 0;
            StateFreeInquire();
          }
        } else { 
          StateFreeWriteIAC();
        }
        break;

      case TREE_WRITE_IAC:
        if (Res == 0) {
          if (call Random.rand() & 0x1) {
            NumRetry = 0;
            StateTreeWriteScanEnable();
          } else {
            NumRetry = 0;
            StateTreeComm();
          }
        } else { 
          StateTreeWriteIAC();
        }
        break;

      default:
        DisplayState("Error - Write IAC Complete in state ");
    }

    return SUCCESS;

  }

  event result_t HCIBaseband.Command_Complete_Read_Transmit_Power_Level(
                                                 uint8 Status,
                                                 tHandle Connection_Handle,
                                                 int8_t Transmit_Power_Level) {
    return SUCCESS;
  }


/*
 * End of HCIBaseband interface
 */



/*
 * Start of Timer interface
 */


  task void ProcessTimerFired() {

    // intervening event makes this irrelevant
    if (CurrentTimer.TimerFired == FALSE) return;

    DisplayState("Timer fired in state ");
    CurrentTimer.TimerFired = FALSE;

    if (CurrentTimer.ResetRetry == TRUE) NumRetry = 0;
    (*CurrentTimer.NextState)();

  }



  event result_t Timer.fired() {
    trace(TRACE_DEBUG_LEVEL,"t\n");
    if (!NetworkOn) {
        if (!DisconnectComplete) {
           post ProcessNextDisconnect();
        }
        return SUCCESS;
    }

    if (CurrentTimer.TimerFired == TRUE) {
        trace(TRACE_DEBUG_LEVEL,"Multiple Timer fire\n");
    }
    CurrentTimer.TimerFired = TRUE;
    post ProcessTimerFired();

    return SUCCESS;
  }



/*
 * End of Timer interface
 */



/*
 * Start of NetworkPacket interface
 */


  event result_t NetworkPacket.SendDone(char *data) {
    call StatsLogger.BumpCounter(NUM_SF_SEND, 1);

    if (!NetworkOn) {
        call NetworkPacket.ReleaseBuffer ( data );
        return SUCCESS;
    }

    switch (NodeState) {
      case FREE_SLAVE_CONNECTION_DONE:
        StateTreeStart();
        break;

      case FREE_PAGE_COMPLETE_MASTER:
        // don't do anything
        break;

      case TREE_CONNECTION_DONE:
        StateTreeStart();
        break;

      default:
#if 0
        DisplayState("Error - SendDone received in state ");
        if (TSFRole == TSF_FREE) {
          StateFreeStart();
        } else if (TSFRole == TSF_TREE) {
          StateTreeStart();
        } else {
          StateReset();
        }
#endif
    }

    call NetworkPacket.ReleaseBuffer ( data );

    return SUCCESS;
  }

  event result_t NetworkPacket.Receive( uint32 Source,
                                        uint8  *Data,
                                        uint16 Length) {

    uint32  *t;
    t = (uint32 *) (Data);

    if (!NetworkOn) {
        return SUCCESS;
    }

    call StatsLogger.BumpCounter(NUM_SF_RECV, 1);

    switch (t[0]) {
      case NEW_CONNECTION_SYNC:

        switch (NodeState) {
          case FREE_PAGE_COMPLETE_WAIT_FOR_SYNC:

            NumRetry = 0;
            PendingConnection.NodeID = Source;
            PendingConnection.OtherNodeType = t[1];
            PendingConnection.OtherNodeRootNodeID = t[2];
            PendingConnection.OtherNodeRootHopCount = t[3];
            StateFreePageCompleteSlave();
            break;

          case FREE_WAIT_FOR_PAGE:
            PendingConnection.NodeID = Source;
            PendingConnection.OtherNodeType = t[1];
            PendingConnection.OtherNodeRootNodeID = t[2];
            PendingConnection.OtherNodeRootHopCount = t[3];
            StateFreeSyncReceivedWaitForPage();
            break;

          case FREE_PAGE_COMPLETE_MASTER:
            if (Source == PendingConnection.NodeID) {
              PendingConnection.OtherNodeType = t[1];
              PendingConnection.OtherNodeRootNodeID = t[2];
              PendingConnection.OtherNodeRootHopCount = t[3];

              if ((t[1] == TSF_FREE) || (t[1] == TSF_TREE)) {
                if (ThisNodeID == RootNodeID) { // I am the root
                  FinishConnection();
                  call NetworkTopology.UpdateConnectionRole(
                      PendingConnection.Handle, FALSE);
                  StateTreeStart();
                } else if ( PendingConnection.OtherNodeRootNodeID
                            != INVALID_NODE) {
                  // other node knows about the root and will switch roles
                  RootNodeID = PendingConnection.OtherNodeRootNodeID;
                  RootNodeHopCount = PendingConnection.OtherNodeRootHopCount + 1;
                  if (RootNodeHopCount > MAX_ROOT_DISTANCE) {
                    NumRetry = 0;
                    StateFreeDisconnectPendingConnection();
                  } else {
                    FinishConnection();
                    call NetworkTopology.UpdateConnectionRole(
                        PendingConnection.Handle, TRUE);
                    StateTreeStart();
                  }
                } else { // neither of us know the root so disconnect
                  NumRetry = 0;
                  StateFreeDisconnectPendingConnection();
                }
              }
            } // otherwise continue to wait for a reply or timeout
            break;

          case TREE_PAGE_COMPLETE_WAIT_FOR_SYNC:

            NumRetry = 0;
            PendingConnection.NodeID = Source;
            PendingConnection.OtherNodeType = t[1];
            PendingConnection.OtherNodeRootNodeID = t[2];
            PendingConnection.OtherNodeRootHopCount = t[3];
            StateTreePageComplete();
            break;

          case TREE_WAIT_FOR_PAGE:
            PendingConnection.NodeID = Source;
            PendingConnection.OtherNodeType = t[1];
            PendingConnection.OtherNodeRootNodeID = t[2];
            PendingConnection.OtherNodeRootHopCount = t[3];
            StateTreeSyncReceivedWaitForPage();
            break;

          default:
            DisplayState("Error - Receieve new connection sync in state ");
        }
        break;

      case NEW_TREE_FOUND:
        switch (NodeState) {
          case TREE_PAGE_COMPLETE_WAIT_FOR_SYNC:
            // coordinator switched to tree, but other node is still trying
            // to page this node so disconnect
            StateTreeDisconnectPendingConnection();
            break;

          default:
            DisplayState("Error - Received NEW_TREE_FOUND in state ");
        }
        break;

      default:
    }

    return SUCCESS;
  }


/*
 * End of NetworkPacket interface
 */



/*
 * Start of NetworkPage interface
 */


  event result_t NetworkPage.PageComplete(uint32 NodeID,
                                          tHandle Connection_Handle) {

    if (!NetworkOn) {
        return SUCCESS;
    }

    if (Connection_Handle != INVALID_HANDLE) {
      call HCILinkPolicy.Write_Link_Policy_Settings(Connection_Handle, 0xF);
      // 5 s timeout
      call HCIBaseband.Write_Automatic_Flush_Timeout(Connection_Handle, 5*1600);
    }

    switch (NodeState) {
      case FREE_SCAN:
          trace(TRACE_DEBUG_LEVEL,
                "Warning - Page complete with %05X in State Free Scan\n",
                NodeID);
        // fall through is intentional
      case FREE_WAIT_FOR_PAGE:
        if (Connection_Handle == INVALID_HANDLE) {
          if (PendingConnection.NodeID == NodeID) {
            NumRetry = 0;
            StateFreeStopScan();
          } else {
            trace(TRACE_DEBUG_LEVEL,"Warning - Failed connection with %05X\n", NodeID);
          }
        } else {
          StateFreePageCompleteWaitForSync(NodeID, Connection_Handle);
        }
        break;

      case FREE_SYNC_RECEIVED_WAIT_FOR_PAGE:
        if (Connection_Handle == INVALID_HANDLE) {
          NumRetry = 0;
          StateFreeStopScan();
        } else {
          if (NodeID == PendingConnection.NodeID) { // set by received message
            PendingConnection.Handle = Connection_Handle;
            NumRetry = 0;
            StateFreePageCompleteSlave();
          } else {
            StateFreePageCompleteWaitForSync(NodeID, Connection_Handle);
          }
        }
        break;

      case FREE_PAGE:
        if (Connection_Handle == INVALID_HANDLE) {
            trace(TRACE_DEBUG_LEVEL,"Warning - Page complete invalid handle with %05X\n",
                NodeID);
          NumRetry = 0;
          if (PendingConnection.NodeID == NodeID) {
            StateFreeWriteScanEnable();
          }
        } else {
          if (PendingConnection.NodeID == NodeID) {
            PendingConnection.Handle = Connection_Handle;
            StateFreePageCompleteMaster();
          } else {
              trace(TRACE_DEBUG_LEVEL,"Error - Successful connection with %05X while waiting for %05X\n", NodeID, PendingConnection.NodeID);
          }
        }
        break;

      case TREE_SCAN:
          trace(TRACE_DEBUG_LEVEL,"Warning - Page complete with %05X in State Tree Scan\n",
                NodeID);
        // fall through is intentional
      case TREE_WAIT_FOR_PAGE:
        if (Connection_Handle == INVALID_HANDLE) {
          if (PendingConnection.NodeID == NodeID) {
            NumRetry = 0;
            StateTreeStopScan();
          } else {
              trace(TRACE_DEBUG_LEVEL,"Warning - Failed connection with %05X\n", NodeID);
          }
        } else {
          StateTreePageCompleteWaitForSync(NodeID, Connection_Handle);
        }
        break;

      case TREE_SYNC_RECEIVED_WAIT_FOR_PAGE:
        if (Connection_Handle == INVALID_HANDLE) {
          NumRetry = 0;
          StateTreeStopScan();
        } else {
          if (NodeID == PendingConnection.NodeID) { // set by received message
            PendingConnection.Handle = Connection_Handle;
            NumRetry = 0;
            StateTreePageComplete();
          } else {
            StateTreePageCompleteWaitForSync(NodeID, Connection_Handle);
          }
        }
        break;

      default:
        if (Connection_Handle != INVALID_HANDLE) {
          DisplayState("Error - Page complete in state ");
          PendingConnection.NodeID = NodeID;
          PendingConnection.Handle = Connection_Handle;
          StateTreeDisconnectPendingConnection();
          trace(TRACE_DEBUG_LEVEL,"Error - Page complete %05X in state %d\n", NodeID, NodeState);
        } else {
            trace(TRACE_DEBUG_LEVEL,"Warning - Page complete %05X with invalid handle in state %d\n", NodeID, NodeState);
        }
    }

    return SUCCESS;

  }

  command result_t GetRootNodeID(uint32 *ID) {
    if (RootNodeID == INVALID_NODE) {
       return FAIL;
    } else {
       *ID = RootNodeID;
       return SUCCESS;
    }
  }


/*
 * End of NetworkPage interface
 */

}


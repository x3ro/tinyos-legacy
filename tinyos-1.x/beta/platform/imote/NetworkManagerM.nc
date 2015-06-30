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
 * This module distributes a command or state throughout the network by
 * handshaking between masters and slaves.  When all slaves have entered the
 * new state, each signals the master.
 */

module NetworkManagerM {
  provides {
//    command result_t Initialize();

    interface NetworkLowPower;

    command result_t DisplayMessage(char *str);
    command result_t NetworkWriteScanEnable(uint32 state);
    command result_t NetworkResetNodes(uint32 ResetDelayMS);
  }

  uses {
    interface NetworkPacket;
    interface NetworkTopology;

    event result_t DisplayMessageDone();
//    event result_t NetworkInitLowPowerDone();
//    event result_t NetworkEnterLowPowerDone();
//    event result_t NetworkExitLowPowerDone();

    interface LowPower;
    interface Timer;
    interface HCIBaseband;
    interface StatsLogger;
    interface WDTControl;
  }
}

implementation {

#define TRACE_DEBUG_LEVEL 0ULL

  // Network management messages
  enum {
         NM_DISPLAY_MESSAGE = 1,
         NM_DISPLAY_MESSAGE_DONE,
         NM_INIT_LOW_POWER,
         NM_INIT_LOW_POWER_DONE,
         NM_ENTER_LOW_POWER,
         NM_ENTER_LOW_POWER_DONE,
         NM_EXIT_LOW_POWER,
         NM_EXIT_LOW_POWER_DONE,
         NM_WRITE_SCAN_ENABLE,
         NM_NETWORK_RESET_NODES
       };

  #define MAX_CHILDREN 8              // maximum number of slaves in a piconet
  uint32  ChildList[MAX_CHILDREN];
  uint32  NumChildren;
  uint32  LowPowerSleepTime;
  uint32  ScanState;   // current state of the write scan enable
  uint32  ResetDelay;


#if 0
  command result_t Initialize() {
  }
#endif




/*
 * Start of Display Message routines
 */

  char DisplayString[80];
 
  void PassDownDisplayMessage() {
    uint32 *t;
    char *buffer;
    int i, len;

    len = strlen(DisplayString) + 4;
    for (i = 0; i < NumChildren; i++) {
      // Need to add retry on failure
      if ((buffer = call NetworkPacket.AllocateBuffer(len)) == NULL) return;
      t = (uint32 *) buffer;
      t[0] = NM_DISPLAY_MESSAGE;
      strcpy(&(buffer[4]), &(DisplayString[0]));

      if (call NetworkPacket.Send(ChildList[i], buffer, len) == FAIL) {
        call NetworkPacket.ReleaseBuffer(buffer);
        // need to add retry on failure
      }
    }
  }



  task void SendDisplayMessageDone() {
    int    i;
    uint32 NumNeighbors;
    uint32 NeighborList[11];  // max number of connections allowed
    uint32 *t;
    char *buffer;

    if (call NetworkTopology.IsASlave(0xFFFFFFFF) == TRUE) {
      call NetworkTopology.Get1HopDestinations( 11, &NumNeighbors,
                                                &(NeighborList[0]));

      for (i = 0; i < NumNeighbors; i++) {
        if (call NetworkTopology.IsASlave(NeighborList[i]) == TRUE) {
          // Need to add retry on failure
          if ((buffer = call NetworkPacket.AllocateBuffer(4)) == NULL) return;
          t = (uint32 *) buffer;
          t[0] = NM_DISPLAY_MESSAGE_DONE;
  
          if (call NetworkPacket.Send(NeighborList[i], buffer, 4) == FAIL) {
            call NetworkPacket.ReleaseBuffer(buffer);
            // need to add retry on failure
          }
        }
      }
    } else { // this is the root node
        //      signal DisplayMessageDone();
    }

  }



  task void DoDisplayMessage() {

    call NetworkTopology.GetChildren(&NumChildren, &(ChildList[0]));

    if (NumChildren == 0) { // this is a leaf node
      trace(TRACE_DEBUG_LEVEL,"%s",DisplayString);
      post SendDisplayMessageDone();
    } else {
      PassDownDisplayMessage();
    }
  }


  void DoDisplayMessageDone(uint32 NodeID) {
    int i;

    i = 0;
    while (i < NumChildren) {
      if (ChildList[i] == NodeID) {
        ChildList[i] = ChildList[--NumChildren];
        i = NumChildren;
      }
      i++;
    }

    if (NumChildren == 0) {
      trace(TRACE_DEBUG_LEVEL,"%s",DisplayString);
      post SendDisplayMessageDone();
    }
  }

/*
 * End of Display Message routines
 */



/*
 * Start of Disable Scan routines
 */

  void PassDownWriteScanEnable() {
    uint32 *t;
    char *buffer;
    int i;

    for (i = 0; i < NumChildren; i++) {
      // Need to add retry on failure
      if ((buffer = call NetworkPacket.AllocateBuffer(8)) == NULL) return;
      t = (uint32 *) buffer;
      t[0] = NM_WRITE_SCAN_ENABLE;
      t[1] = ScanState;

      if (call NetworkPacket.Send(ChildList[i], buffer, 8) == FAIL) {
        call NetworkPacket.ReleaseBuffer(buffer);
        // need to add retry on failure
      }
    }
  }


extern void SetNetworkDiscovery(bool active) __attribute__ ((C, spontaneous));

  task void DoWriteScanEnable() {

    call NetworkTopology.GetChildren(&NumChildren, &(ChildList[0]));

    if (NumChildren == 0) { // this is a leaf node
      if (ScanState == 0) {
        SetNetworkDiscovery(FALSE);
      } else {
        SetNetworkDiscovery(TRUE);
      }
      call HCIBaseband.Write_Scan_Enable(ScanState);
    } else {
      PassDownWriteScanEnable();
    }
  }


  command result_t NetworkWriteScanEnable(uint32 state) {
    ScanState = state;
    post DoWriteScanEnable();
    return SUCCESS;
  }

  void PassDownNetworkResetNodes() {
    uint32 *t;
    char *buffer;
    int i;

    for (i = 0; i < NumChildren; i++) {
      // Need to add retry on failure
      if ((buffer = call NetworkPacket.AllocateBuffer(8)) == NULL) return;
      t = (uint32 *) buffer;
      t[0] = NM_NETWORK_RESET_NODES;
      t[1] = ResetDelay;

      if (call NetworkPacket.Send(ChildList[i], buffer, 8) == FAIL) {
        call NetworkPacket.ReleaseBuffer(buffer);
        // need to add retry on failure
      }
    }
  }

  task void DoNetworkResetNodes() {

    call NetworkTopology.GetChildren(&NumChildren, &(ChildList[0]));

    if (NumChildren != 0) { // have children
      PassDownNetworkResetNodes();
    }
    call Timer.stop();		// just in case
    call Timer.start(TIMER_ONE_SHOT, ResetDelay);
  }

  command result_t NetworkResetNodes(uint32 ResetDelayMS) {
    ResetDelay = ResetDelayMS;
    post DoNetworkResetNodes();
    return SUCCESS;
  }

/*
 * End of Disable scan routines
 */



/*
 * Start of Init Low Power routines
 */

  uint16 min, max;

  void PassDownInitLowPower() {
    uint32 *t;
    char *buffer;
    int i;
    uint16 *ptr16;

    for (i = 0; i < NumChildren; i++) {
      // Need to add retry on failure
      // assumes returned buffer is 4-byte aligned
      if ((buffer = call NetworkPacket.AllocateBuffer(8)) == NULL) return;
      t = (uint32 *) buffer;
      ptr16 = (uint16 *) buffer;
      t[0] = NM_INIT_LOW_POWER;
      ptr16[2] = min;
      ptr16[3] = max;

      if (call NetworkPacket.Send(ChildList[i], buffer, 8) == FAIL) {
        call NetworkPacket.ReleaseBuffer(buffer);
        // need to add retry on failure
      }
    }
  }



  task void SendInitLowPowerDone() {
    int    i;
    uint32 NumNeighbors;
    uint32 NeighborList[11];  // max number of connections allowed
    uint32 *t;
    char *buffer;

    if (call NetworkTopology.IsASlave(0xFFFFFFFF) == TRUE) {
      call NetworkTopology.Get1HopDestinations( 11, &NumNeighbors,
                                                &(NeighborList[0]));

      for (i = 0; i < NumNeighbors; i++) {
        if (call NetworkTopology.IsASlave(NeighborList[i]) == TRUE) {
          // Need to add retry on failure
          if ((buffer = call NetworkPacket.AllocateBuffer(4)) == NULL) return;
          t = (uint32 *) buffer;
          t[0] = NM_INIT_LOW_POWER_DONE;
  
          if (call NetworkPacket.Send(NeighborList[i], buffer, 4) == FAIL) {
            call NetworkPacket.ReleaseBuffer(buffer);
            // need to add retry on failure
          }
        }
      }
    } else { // this is the root node
      signal NetworkLowPower.NetworkInitLowPowerDone();
    }

  }



  task void DoInitLowPower() {

    call NetworkTopology.GetChildren(&NumChildren, &(ChildList[0]));

    if (NumChildren == 0) { // this is a leaf node
      // leaf nodes don't control any links, but need to turn on low power
      // manager
      post SendInitLowPowerDone();
      
      trace(TRACE_DEBUG_LEVEL,"Initializing Low Power min = %d, max = %d\r\n", min, max);
      call LowPower.init(min, max); 
    } else {
      PassDownInitLowPower();
    }
  }


  void DoInitLowPowerDone(uint32 NodeID) {
    int i;

    i = 0;
    while (i < NumChildren) {
      if (ChildList[i] == NodeID) {
        ChildList[i] = ChildList[--NumChildren];
        i = NumChildren;
      }
      i++;
    }

    if (NumChildren == 0) {
        post SendInitLowPowerDone();
        trace(TRACE_DEBUG_LEVEL,"Initializing Low Power min = %d, max = %d\r\n", min, max);
        call LowPower.init(min, max); 
    }
  }

  default event result_t NetworkLowPower.NetworkInitLowPowerDone() { return SUCCESS; }

/*
 * End of Enter Low Power routines
 */



/*
 * Start of Enter Low Power routines
 */

  void PassDownEnterLowPower() {
    uint32 *t;
    char *buffer;
    int i;

    for (i = 0; i < NumChildren; i++) {
      // Need to add retry on failure
      if ((buffer = call NetworkPacket.AllocateBuffer(4)) == NULL) return;
      t = (uint32 *) buffer;
      t[0] = NM_ENTER_LOW_POWER;
//      t[1] = LowPowerSleepTime;

      if (call NetworkPacket.Send(ChildList[i], buffer, 4) == FAIL) {
        call NetworkPacket.ReleaseBuffer(buffer);
        // need to add retry on failure
      }
    }
  }



  task void SendEnterLowPowerDone() {
    int    i;
    uint32 NumNeighbors;
    uint32 NeighborList[11];  // max number of connections allowed
    uint32 *t;
    char *buffer;

    if (call NetworkTopology.IsASlave(0xFFFFFFFF) == TRUE) {
      call NetworkTopology.Get1HopDestinations( 11, &NumNeighbors,
                                                &(NeighborList[0]));

      for (i = 0; i < NumNeighbors; i++) {
        if (call NetworkTopology.IsASlave(NeighborList[i]) == TRUE) {
          // Need to add retry on failure
          if ((buffer = call NetworkPacket.AllocateBuffer(4)) == NULL) return;
          t = (uint32 *) buffer;
          t[0] = NM_ENTER_LOW_POWER_DONE;
  
          if (call NetworkPacket.Send(NeighborList[i], buffer, 4) == FAIL) {
            call NetworkPacket.ReleaseBuffer(buffer);
            // need to add retry on failure
          }
        }
      }
    } else { // this is the root node
      signal NetworkLowPower.NetworkEnterLowPowerDone();
    }

  }



  task void DoEnterLowPower() {

    call NetworkTopology.GetChildren(&NumChildren, &(ChildList[0]));

    if (NumChildren == 0) { // this is a leaf node
      // leaf nodes don't control any links, but need to turn on low power
      // manager
      post SendEnterLowPowerDone();
      trace(TRACE_DEBUG_LEVEL,"Entering Low Power\r\n");
      call LowPower.EnterLowPower(NULL, 0); 
      if (LowPowerSleepTime != 0) {
//        call Timer.start(TIMER_ONE_SHOT, LowPowerSleepTime);
      }
    } else {
      PassDownEnterLowPower();
    }
  }


  void DoEnterLowPowerDone(uint32 NodeID) {
    int i;
    uint8 tmp;

    trace(TRACE_DEBUG_LEVEL,"Child done with Entering Low Power\r\n");
    i = 0;
    while (i < NumChildren) {
      if (ChildList[i] == NodeID) {
        ChildList[i] = ChildList[--NumChildren];
        i = NumChildren;
      }
      i++;
    }

    if (NumChildren == 0) {
      post SendEnterLowPowerDone();
      trace(TRACE_DEBUG_LEVEL,"Entering Low Power\r\n");
      call NetworkTopology.GetChildren(&NumChildren, &(ChildList[0]));
      tmp = NumChildren;
      call LowPower.EnterLowPower(&(ChildList[0]), tmp); 
      if (LowPowerSleepTime != 0) {
//        call Timer.start(TIMER_ONE_SHOT, LowPowerSleepTime);
      }
    }
  }

  command result_t NetworkLowPower.NetworkInitLowPower(uint16 MinVal, uint16 MaxVal) {

    min = MinVal;
    max = MaxVal;
    post DoInitLowPower();

    return SUCCESS;
  }


  command result_t NetworkLowPower.NetworkEnterLowPower(uint32 time) {

    LowPowerSleepTime = time;
    post DoEnterLowPower();
    return SUCCESS;

  }


  default event result_t NetworkLowPower.NetworkEnterLowPowerDone() { return SUCCESS; }

/*
 * End of Enter Low Power routines
 */



/*
 * Start of Exit Low Power routines
 */

  void PassDownExitLowPower() {
    uint32 *t;
    char *buffer;
    int i;

    for (i = 0; i < NumChildren; i++) {
      // Need to add retry on failure
      if ((buffer = call NetworkPacket.AllocateBuffer(4)) == NULL) return;
      t = (uint32 *) buffer;
      t[0] = NM_EXIT_LOW_POWER;

      if (call NetworkPacket.Send(ChildList[i], buffer, 4) == FAIL) {
          trace(TRACE_DEBUG_LEVEL,"Manager - pass down send fails\r\n");
        call NetworkPacket.ReleaseBuffer(buffer);
        // need to add retry on failure
      } else {
          trace(TRACE_DEBUG_LEVEL,"Exit Low Power packet sent\r\n");
      }
    }
  }



  task void SendExitLowPowerDone() {
    int    i;
    uint32 NumNeighbors;
    uint32 NeighborList[11];  // max number of connections allowed
    uint32 *t;
    char *buffer;

    if (call NetworkTopology.IsASlave(0xFFFFFFFF) == TRUE) {
      call NetworkTopology.Get1HopDestinations( 11, &NumNeighbors,
                                                &(NeighborList[0]));

      for (i = 0; i < NumNeighbors; i++) {
        if (call NetworkTopology.IsASlave(NeighborList[i]) == TRUE) {
          // Need to add retry on failure
          if ((buffer = call NetworkPacket.AllocateBuffer(4)) == NULL) return;
          t = (uint32 *) buffer;
          t[0] = NM_EXIT_LOW_POWER_DONE;
  
          if (call NetworkPacket.Send(NeighborList[i], buffer, 4) == FAIL) {
            call NetworkPacket.ReleaseBuffer(buffer);
            // need to add retry on failure
          }
        }
      }
    } else { // this is the root node
      signal NetworkLowPower.NetworkExitLowPowerDone();
    }

  }



  task void DoExitLowPower() {

    call NetworkTopology.GetChildren(&NumChildren, &(ChildList[0]));

    call LowPower.ExitDeepSleep(); 
    call LowPower.ExitLowPower(); 

    if (NumChildren == 0) { // this is a leaf node
      // leaf nodes don't control any links, but need to turn off low power
      // manager
      post SendExitLowPowerDone();
      trace(TRACE_DEBUG_LEVEL,"Exiting Low Power\r\n");
    } else {
      PassDownExitLowPower();
    }
  }


  void DoExitLowPowerDone(uint32 NodeID) {
    int i;

    i = 0;
    while (i < NumChildren) {
      if (ChildList[i] == NodeID) {
        ChildList[i] = ChildList[--NumChildren];
        i = NumChildren;
      }
      i++;
    }

    if (NumChildren == 0) {
      post SendExitLowPowerDone();
    }
  }

  command result_t NetworkLowPower.NetworkExitLowPower() {

      trace(TRACE_DEBUG_LEVEL,"Manager - exit low power\r\n");
    post DoExitLowPower();

    return SUCCESS;
  }
  default event result_t NetworkLowPower.NetworkExitLowPowerDone() { return SUCCESS; }

/*
 * End of Enter Low Power Message routines
 */


/*
 * Start of NetworkPacket interface
 */


  event result_t NetworkPacket.SendDone(char *data) {
    call NetworkPacket.ReleaseBuffer ( data );
    call StatsLogger.BumpCounter(NUM_PS_SEND, 1);
    return SUCCESS;
  }



  event result_t NetworkPacket.Receive( uint32 Source,
                                        uint8  *Data,
                                        uint16 Length) {
    uint32  *t;
    uint16  *ptr16;
    t = (uint32 *) (Data);

    call StatsLogger.BumpCounter(NUM_PS_RECV, 1);

    switch (t[0]) {
      case NM_DISPLAY_MESSAGE:
        strncpy(&(DisplayString[0]), &(Data[4]), Length - 4);
        post DoDisplayMessage();
        break;

      case NM_DISPLAY_MESSAGE_DONE:
        DoDisplayMessageDone(Source);
        break;

      case NM_INIT_LOW_POWER:
        ptr16 = (uint16 *) (Data);
        min = ptr16[2];
        max = ptr16[3];
        post DoInitLowPower();
        break;

      case NM_INIT_LOW_POWER_DONE:
        DoInitLowPowerDone(Source);
        break;

      case NM_ENTER_LOW_POWER:
//        LowPowerSleepTime = t[1];
        post DoEnterLowPower();
        break;

      case NM_ENTER_LOW_POWER_DONE:
        DoEnterLowPowerDone(Source);
        break;

      case NM_EXIT_LOW_POWER:
          trace(TRACE_DEBUG_LEVEL,"Receive Exit Low Power packet\r\n");
        post DoExitLowPower();
        break;

      case NM_EXIT_LOW_POWER_DONE:
          trace(TRACE_DEBUG_LEVEL,"Receive Exit Low Power Done packet\r\n");
        DoExitLowPowerDone(Source);
        break;

      case NM_WRITE_SCAN_ENABLE:
        ScanState = t[1];
        post DoWriteScanEnable();
        break;

      case NM_NETWORK_RESET_NODES:
        ResetDelay = t[1];
        post DoNetworkResetNodes();
        break;

      default:
    }

    return SUCCESS;
  }


/*
 * End of NetworkPacket interface
 */



/*
 * Start of LowPower interface
 */

  /*
   * This is called when all links have been put in hold mode.
   * Now this node is ready for deep sleep.
   */

  event result_t LowPower.EnterLowPowerComplete () {
      trace(TRACE_DEBUG_LEVEL,"Entering deep sleep\r\n");
    call LowPower.EnterDeepSleep();
    return SUCCESS;
  }

  event result_t LowPower.PowerModeChange(bool LowPowerMode) {
    return SUCCESS;
  }

/*
 * End of LowPower interface
 */



  command result_t DisplayMessage(char *str) {

    snprintf(&(DisplayString[0]), 80, "%s", str);
    post DoDisplayMessage();

    return SUCCESS;
  }


/*
 * Start of Timer interface
 */


  event result_t Timer.fired() {

    call WDTControl.AllowForceReset();
    return SUCCESS;
  }


/*
 * End of Timer interface
 */


/*
 * Start of HCIBaseband interface
 */



  event result_t HCIBaseband.Command_Complete_Write_Scan_Enable( uint8 Status ) {
    return SUCCESS;
  }

  event result_t HCIBaseband.Command_Complete_Read_Link_Supervision_Timeout( uint8 Reason,
                   tHandle Connection_Handle, uint16 Timeout ) {
    return SUCCESS;
  }

  event result_t HCIBaseband.Command_Complete_Write_Current_IAC_LAP( uint8 Status ) {
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

}


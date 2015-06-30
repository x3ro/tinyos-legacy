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
 * This module manages the network connections for each node.  It will
 * establish and maintain the specified connections.
 */

module ScatternetHardwiredM
{
  provides {
    interface StdControl as Control;
    interface ScatternetFormation;
    interface NetworkHardwired;
    command result_t NetworkDiscoveryActive(bool DiscoveryActive);
  }

  uses {
    interface StdControl as BTLowerLevelControl;
    interface NetworkPage;
    interface HCILinkControl;
    interface HCIBaseband;
    interface NetworkTopology;
    interface Timer; 
  }
}

implementation
{

/*
 * fwd declaration
 */
task void PageScanEnable();

#define DEBUG_ON 0

void debug_msg(char *str) {
#if DEBUG_ON
   DisplayStr(str);
#endif
};


/*
 * If the number of retries pased the RETRY_THRESHOLD, we use the
 * longer timeout to page a node 
 */
#define PAGE_INTERVAL 5000	// 5 seconds
#define SHORT_RETRY_INTERVAL 1	// 1 page interval (5 seconds)
#define LONG_RETRY_INTERVAL 12 	// 12 * page interval (60 seconds)
#define RETRY_THRESHOLD 10      
#define PENDING_TIMEOUT_INTERVAL 12 // assume we missed the event, if we don't come back

#define INVALID_HANDLE 0xFFFF
#define MAX_CONNECTIONS 10	

#define FLAGS_VALID 0x1
#define FLAGS_PENDING 0x2
#define FLAGS_MASTER 0x4

#define IsValid(flags) ((flags & FLAGS_VALID) == FLAGS_VALID)
#define SetValid(flags) (flags |= FLAGS_VALID)
#define ClearValid(flags) (flags &= ~FLAGS_VALID)
#define IsPending(flags) ((flags & FLAGS_PENDING) == FLAGS_PENDING)
#define SetPending(flags) (flags |= FLAGS_PENDING)
#define ClearPending(flags) (flags &= ~FLAGS_PENDING)
#define IsMaster(flags) ((flags & FLAGS_MASTER) == FLAGS_MASTER)
#define SetMaster(flags) (flags |= FLAGS_MASTER)
#define ClearMaster(flags) (flags &= ~FLAGS_MASTER)

   typedef struct tConnection {
      uint32  other_node;
      uint16  last_attempt;
      tHandle handle;
      uint8   retry_count;
      bool    flags;
   } tConnection;

   uint32     ThisNodeID;
   uint16     MyTime;
   tBD_ADDR   ConnectionRequestAddr;
   tConnection Connections[MAX_CONNECTIONS];
   uint8 NumConnections;
   bool  HardwiredOn;

   char temp[32];

   // Filters must be set in task context to guarantee that the BT lower level 
   // has finished set up.
   task void SetUpFilters() {
      uint8   condition;

      condition = 0;
      call HCIBaseband.Set_Event_Filter(0x01, // Inquiry Filter
                                        0x00, // a new device responded
                                        &condition); // condition not used

      condition = 0x01; // do NOT auto accept connection
      call HCIBaseband.Set_Event_Filter(0x02, // Connection setup filter
                                        0x00, // all devices
                                        &condition);
   }

   command result_t Control.init() {

     // NetworkTopology must be initialized at a higher level,
     // typically (NetworkCommand)

      call BTLowerLevelControl.init();
      call NetworkTopology.GetNodeID(&ThisNodeID);
      post SetUpFilters();
      call NetworkPage.Initialize();

      return SUCCESS;
   }


   command result_t Control.start() {

      call BTLowerLevelControl.start();
      return SUCCESS;
   }

   command result_t Control.stop() {

      call BTLowerLevelControl.stop();
      return SUCCESS;
   }

   void ClearConnections() {
      uint8 i;
    
      for(i=0; i<MAX_CONNECTIONS; i++) {
         ClearValid(Connections[i].flags);
      }

      NumConnections = 0;
   }

   task void PageMissingNodes() {
      uint8 i;
      uint16 Timeout;
      uint8 flags;

      for(i=0; i<NumConnections; i++) {
         flags = Connections[i].flags; 

         if ((Connections[i].handle != INVALID_HANDLE) || !IsValid(flags)) {
            continue;
         }
         if (IsMaster(flags)) {
            if (IsPending(flags)) {
               sprintf(temp, "Page Pending %x, %x\r\n", Connections[i].last_attempt, MyTime);
               debug_msg(temp);
               // Check that we have not locked up, i.e. haven't been pending for a long time
               if ((Connections[i].last_attempt + PENDING_TIMEOUT_INTERVAL) < MyTime) {
                  sprintf(temp, "Missed Event %x, %x\r\n", Connections[i].last_attempt, MyTime);
                  debug_msg(temp);
                  ClearPending(Connections[i].flags);
                  Connections[i].last_attempt = MyTime;
               }
               return;
            }

            // No pending request, Check if it is time to repage
            if (Connections[i].retry_count < RETRY_THRESHOLD) {
               Timeout = SHORT_RETRY_INTERVAL;
            } else {
               Timeout = LONG_RETRY_INTERVAL;
            }
            Timeout+= Connections[i].last_attempt;

            if (MyTime > Timeout) {
               // Timeout expired, retry
               SetPending(Connections[i].flags);
               Connections[i].last_attempt = MyTime;
               Connections[i].retry_count++; 
               sprintf(temp, "Paging %dx\r\n", Connections[i].other_node);
               debug_msg(temp);
               call NetworkPage.PageNode(Connections[i].other_node);
            }
         } else {
            // Slave & unconnected, turn on page scan
            post PageScanEnable();
         }
      }
    
   }

   command result_t NetworkHardwired.init() {
      ClearConnections();
      return SUCCESS;
   }

   command result_t NetworkHardwired.start() {
      uint8 i;
      uint8 flags;
      HardwiredOn = true;
      MyTime = 1;
      call Timer.start(TIMER_REPEAT, PAGE_INTERVAL);

      // TODO : For now always enable page scan
      post PageScanEnable();

      // Page all slaves
      for(i=0; i<NumConnections; i++) {
         flags = Connections[i].flags; 
         if (IsValid(flags) && IsMaster(flags) && !IsPending(flags)) {
            SetPending(Connections[i].flags);
            Connections[i].last_attempt = MyTime;
            Connections[i].retry_count++; 
            sprintf(temp, "Paging %dx\r\n", Connections[i].other_node);
            debug_msg(temp);
            call NetworkPage.PageNode(Connections[i].other_node);
         }
      }
      return SUCCESS;
   }

   command result_t NetworkHardwired.stop() {
      uint8 i;
      HardwiredOn = false;

      // Disconnect all established connections
      for(i=0; i<NumConnections; i++) {
         if (Connections[i].handle != INVALID_HANDLE) {
            /*
             * Disconnect, specify user ended connection
             */
            call HCILinkControl.Disconnect(Connections[i].handle, 0x13);
            // TODO : Wait for disconnection complete ?
            Connections[i].handle = INVALID_HANDLE;
            Connections[i].last_attempt = MyTime;
            sprintf(temp, "Disc %dx, handle %x\r\n", Connections[i].other_node, Connections[i].handle);
            debug_msg(temp);
         }
      }
      
      call Timer.stop();
   }

   /*
    * This function just populates the table, it doesn't start the connections
    * until the start is called
    */	
   command result_t NetworkHardwired.AddConnection(uint32 Master, uint32 Slave) {
      uint8 flags;
      uint32 other_node;

      flags = 0;

      other_node = Master;
      if (Master == ThisNodeID) {
         SetMaster(flags);
         other_node = Slave;
      } else if (Slave != ThisNodeID) {
         // this node is not part of the connection, no need to add to table
         return SUCCESS;
      }
     
      if (NumConnections >= MAX_CONNECTIONS) { 
         // table is full
         return FAIL;
      }
      
      // Setup the flags, master/slave was setup already
      SetValid(flags);
      ClearPending(flags);
      Connections[NumConnections].flags = flags;
      
      Connections[NumConnections].other_node = other_node;
      Connections[NumConnections].last_attempt = 0;
      Connections[NumConnections].retry_count = 0;
      Connections[NumConnections].handle = INVALID_HANDLE;
      NumConnections++;
   }

    command result_t ScatternetFormation.ResumeNodeDiscovery() {
      return SUCCESS;
   }


   command result_t ScatternetFormation.SuspendNodeDiscovery() {
      return SUCCESS;
   }

   /*
    * This needs to happen in a task, to make sure that the radio gets a 
    * chance to initialize
    */
 
   task void PageScanEnable() {
      call NetworkPage.EnablePageScan();
   }

   command result_t ScatternetFormation.EnablePageScan() {
     post PageScanEnable();
     return SUCCESS;
   }

   command result_t ScatternetFormation.DisableScan() {
      return call NetworkPage.DisableScan();
   }

   command result_t ScatternetFormation.PageNode(uint32 id) {
      return call NetworkPage.PageNode(id);
   }

   /*
    * NetworkPage interface
    */
   event result_t NetworkPage.PageComplete(uint32 NodeID, tHandle Handle) {

      tBD_ADDR BD_ADDR;
      uint8 i;

      if (!HardwiredOn) {
         // Only track connections when using the Hardwired version
         return SUCCESS;
      }

      if (Handle == INVALID_HANDLE) {
         // Page failed, log in table and clear the flag
         for(i=0; i<NumConnections; i++) {
            if (Connections[i].other_node == NodeID) {
               Connections[i].handle = INVALID_HANDLE;
               ClearPending(Connections[i].flags);
               Connections[i].last_attempt = MyTime;
               return SUCCESS;
            }
         }
         sprintf(temp, "Page Failed %dx\r\n", NodeID);
         debug_msg(temp);
         return SUCCESS;
      }

      BD_ADDR.byte[0] = NodeID & 0xFF;
      BD_ADDR.byte[1] = (NodeID >> 8) & 0xFF;
      BD_ADDR.byte[2] = ((NodeID >> 16) & 0x0F) | 0x80;
      BD_ADDR.byte[3] = 0x42;
      BD_ADDR.byte[4] = 0x5F;
      BD_ADDR.byte[5] = 0x4B;

      call NetworkTopology.AddConnection( NodeID, Handle, BD_ADDR, FALSE, TRUE);

      signal ScatternetFormation.NodeConnected(NodeID);

      sprintf(temp, "Page Succeeded %dx\r\n", NodeID);
      debug_msg(temp);

      // Update the table
      for(i=0; i<NumConnections; i++) {
         if (Connections[i].other_node == NodeID) {
            Connections[i].handle = Handle;
            Connections[i].retry_count = 0;
            ClearPending(Connections[i].flags);
            return SUCCESS;
         }
      }
      return SUCCESS;
   }

   /* 
    * HCILinkControl interface
    */
   event result_t HCILinkControl.Command_Status_Inquiry(uint8 Status) {
      return SUCCESS;
   }

   event result_t HCILinkControl.Inquiry_Result( uint8 Num_Responses,
                                           tBD_ADDR *BD_ADDR,
                                           uint8 *Page_Scan_Repetition_Mode,
                                           uint8 *Page_Scan_Period_Mode,
                                           uint8 *Page_Scan_Mode,
                                           uint32 *Class_of_Device,
                                           uint16 *Clock_Offset) {
      return SUCCESS;
   }
  
  event result_t HCILinkControl.Inquiry_Complete( uint8 Status ) {

    return SUCCESS;

  }

   event result_t HCILinkControl.Command_Complete_Inquiry_Cancel(uint8 Status) {
      return SUCCESS;
   }

   void AcceptConnectionRequest() {

      call HCILinkControl.Accept_Connection_Request(ConnectionRequestAddr,0x1);
      return;
   }

   void RejectConnectionRequest() {

      call HCILinkControl.Reject_Connection_Request(ConnectionRequestAddr,0x1F);
      return;
   }

   event result_t HCILinkControl.Connection_Request(tBD_ADDR BD_ADDR,
                                             uint32 Class_of_Device, //3 bytes
                                             uint8 Link_Type) {
      int i;

      if (!HardwiredOn) {
         // Only track connections when using the Hardwired version
         return SUCCESS;
      }

      // only accept requests from other iMotes
      if ((BD_ADDR.byte[5] == 0x4B) && (BD_ADDR.byte[4] == 0x5F) &&
          (BD_ADDR.byte[3] == 0x42) && ((BD_ADDR.byte[2] & 0xF0) == 0x80)) {

         for (i = 0; i < 6; i++) {
            ConnectionRequestAddr.byte[i] = BD_ADDR.byte[i];
         }
         // TODO: Restrict acceptance if needed
         sprintf(temp, "request %x %x", BD_ADDR.byte[1], BD_ADDR.byte[0]);
         debug_msg(temp);
         AcceptConnectionRequest();
      }

      return SUCCESS;
   }

   event result_t HCILinkControl.Disconnection_Complete( uint8 Status,
                                                  tHandle Connection_Handle,
                                                  uint8 Reason) {

      uint32 DestID;
      uint8 i;

      if (!HardwiredOn) {
         // Only track connections when using the Hardwired version
         return SUCCESS;
      }

      sprintf(temp, "Disc %x, reason %x\r\n", Connection_Handle, Reason);
      debug_msg(temp);

      call NetworkTopology.NextHandle2NodeID(Connection_Handle, &DestID);
      // invalidate the routing table entries;
      call NetworkTopology.RemoveConnection(Connection_Handle, FALSE);

      signal ScatternetFormation.NodeDisconnected(DestID);

      // Update the table
      for(i=0; i<NumConnections; i++) {
         if (Connections[i].handle == Connection_Handle) {
            Connections[i].handle = INVALID_HANDLE;
            Connections[i].last_attempt = MyTime;
            /* 
             * TODO : Is this OK?
             * Check reason code, if this was a user disconnect
             * Don't repage right away (case of network powerdown), 
             * rely on timer.
             * All other cases, repage right away
             */
            if (Reason == 0x13) {
               return SUCCESS;
            }

            if (IsMaster(Connections[i].flags)) {
               call NetworkPage.PageNode(Connections[i].other_node);
               SetPending(Connections[i].flags);
               Connections[i].last_attempt = MyTime;
               Connections[i].retry_count++; 
               sprintf(temp, "Paging %dX\r\n", Connections[i].other_node);
               debug_msg(temp);
            } else {
               post PageScanEnable();
            }
            return SUCCESS;
         }
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
  
  /* 
   * HCIBaseband interface
   */

   event result_t HCIBaseband.Command_Complete_Write_Scan_Enable(uint8 Reason) {
      return SUCCESS;
   }

   event result_t HCIBaseband.Command_Complete_Read_Link_Supervision_Timeout(uint8 Reason, tHandle Connection_Handle, uint16 Timeout) {
      return SUCCESS;
   }

   event result_t HCIBaseband.Command_Complete_Write_Current_IAC_LAP(uint8 Status) {
      return SUCCESS;
   }

   /*
    * Timer interface
    */
   event result_t Timer.fired() {
      uint8 i;

      MyTime++;

      /*
       * Simple Handling of timer overflow
       */
      if (MyTime == 0) {
         for(i=0; i<NumConnections; i++) {
            Connections[i].last_attempt = 0;
         }
         MyTime = 1;
      }

      if (!HardwiredOn) {
         return SUCCESS;
      }

      // Check if we need to page a node
      post PageMissingNodes();
      return SUCCESS;
   }

   // HACK : needed temporarily
   command result_t NetworkDiscoveryActive(bool DiscoveryActive) {
       return SUCCESS;
   }
  
   // HACK : needed temporarily
   void SetNetworkDiscovery(bool active) __attribute__ ((C, spontaneous)) {
    call NetworkDiscoveryActive(active);
   }

   event result_t HCIBaseband.Command_Complete_Read_Transmit_Power_Level(
                                                 uint8 Status,
                                                 tHandle Connection_Handle,
                                                 int8_t Transmit_Power_Level) {
     return SUCCESS;
   }

}


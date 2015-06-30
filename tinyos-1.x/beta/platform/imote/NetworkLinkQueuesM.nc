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
 * This module manages the network data traffic for each node.  Multiple
 * applications can be wired on top of this module.  This module maintains
 * a set of queues, one for each BT link in the lower level.  When a packet
 * comes in, it is added to the appropriate link queue to send out over the
 * radio.  This module acts as a crossbar switch, routing packets between
 * multiple applications at the higher levels to multiple radio links at the
 * lower level.
 *
 * This component creates a buffered list of destinations and pointers to
 * packets to send.  If the lower level send fails the destination and packet
 * pointer are saved and retried after all other outstanding packets.  After
 * MAX_NUM_RETRY the packet send fails and a SendDone with a NACK is returned
 * to the upper level.  An InvalidDest is signaled for the channel which is not
 * responding.
 */



includes StatsTypes;
module NetworkLinkQueuesM
{
  provides {
    interface NetworkPacket[uint8 channel];
    interface NetworkPacket as RelayPacket;
    event result_t SuspendDataTraffic (bool status);
  }

  uses {
    interface BTBuffer;
    interface HCIData;
    interface Timer;
    interface NetworkTopology;
    interface HCILinkControl;
    event result_t InvalidDest(uint32 Dest);
    interface StatsLogger;
    interface Memory;
  }
}


implementation
{

#define NEXT_BUFFER(ent, max) (((ent) >= ((max) - 1)) ? 0 : ((ent) + 1))

#define TRACE_DEBUG_LEVEL 0ULL
//#define TRACE_DEBUG_LEVEL DBG_USR1

#define INVALID_HANDLE 0xFFFF


  typedef struct tRetryPacket {
    uint32     DestID;
    char       *Data;      // lower level packet to send (including iMote header
    bool       Valid;      // whether the entry contains a message to send
                           // because messages may be acked out of order
    bool       Queued;     // Whether the packet has been sent to the lower
                           // level and we are waiting for a reply
    uint16     Length;
    uint32     RetryAttempt;
  } tRetryPacket;

  #define MAX_RETRY_PACKETS 40        // arbitrary
  #define MIN_RETRY_PACKETS 2

#if 0		// Switch to BRAM
  tRetryPacket RetryList[MAX_RETRY_PACKETS];
#else
  tRetryPacket *RetryList;
#endif
  uint8        MaxRetryPackets;
  uint8        NumRetryEntries; // Number of outstanding packets
  uint8        NextFreeEntry;   // Candidate for the next retry list to use
  uint8        LastQueuedLink;  // Try to spread messages across links fairly



  #define MAX_PACKET_PER_LINK 40
  #define MAX_LINKS 10

  typedef struct tRetryQueue {
    tHandle  Handle;   // Link handle used by all entries in this queue
    uint8    Head;     // Index of next entry to fill in the RetryIndex array
    uint8    Tail;     // Index of oldest entry in the RetryIndex array
    uint8    RetryIndex[MAX_PACKET_PER_LINK]; // array of indices into RetryList
                       // for this link
  } tRetryQueue;
  // (Head == Tail) => queue is empty

  tRetryQueue  LinkQueues[MAX_LINKS];
  uint8        NumLinks;



  #define RETRY_INTERVAL 200     // 200 ms timer to retry sends

  // For now - don't try to resend packets which get Nack'd by the lower level
  // Need to test whether the connection is still valid before trying to send
  // the packet on this link
  #define MAX_RETRY_ATTEMPTS 0   // # of times to retry sending a packet
    
  uint32       ThisNodeID;
  uint32       PacketCount;
  bool         TimerRunning;
  bool         WaitToSend;    // Whether it is OK to send a packet
  uint8        OutstandingPackets;  // Num packets in lower layer



  // Given a connection handle, return the associated link queue
  tRetryQueue *GetHandleQueue(tHandle Handle) {
    int i;
    for (i = 0; i < NumLinks; i++) {
      if (LinkQueues[i].Handle == Handle) return &(LinkQueues[i]);
    }
    return NULL;
  }



  // Given a link queue, return the RetryList entry for the oldest element
  tRetryPacket *GetQueuePacket(tRetryQueue *queue) {
    return (&(RetryList[queue->RetryIndex[queue->Tail]]));
  }



  void StartTimer() {
    if (TimerRunning == FALSE) {
      call Timer.start(TIMER_REPEAT, RETRY_INTERVAL);
      TimerRunning = TRUE;
    }
  }

  void StopTimer() {
    call Timer.stop();
    TimerRunning = FALSE;
  }



  /*
   * Return the index of an available entry in the RetryList, or
   * MAX_RETRY_PACKETS if the list is full
   */

  uint8 GetFreeRetryListIndex() {
    uint8 i, retval;

    for (i = 0; i < MaxRetryPackets; i++) { 
      if (RetryList[NextFreeEntry].Valid == FALSE) {
        retval = NextFreeEntry;
        NextFreeEntry = NEXT_BUFFER(NextFreeEntry, MaxRetryPackets);
        return retval;
      }
      NextFreeEntry = NEXT_BUFFER(NextFreeEntry, MaxRetryPackets);
    }

    return MaxRetryPackets;
  }



  /*
   * Find the queue for the next hop link to Dest.  If the queue does not
   * exist, then allocate a new one.  Return NULL if there are no more link
   * queues or if there is no next hop mapping for the destination.
   */

  tRetryQueue *GetLinkQueue(uint32 Dest) {
    tHandle        Handle;
    uint8          i, nextHead;
    tRetryQueue    *queue;

    if (call NetworkTopology.GetNextConnection(Dest, NULL, &Handle) == FAIL) {
      return NULL;
    }

    // See if there is an exiting queue for the next hop
    if ((queue = GetHandleQueue(Handle)) != NULL) {
      nextHead = NEXT_BUFFER(queue->Head, MAX_PACKET_PER_LINK);
      if (nextHead == queue->Tail) return NULL;
      return queue;
    }

    // See if there is an empty queue to use for the next hop
    for (i = 0; i < NumLinks; i++) {
      queue = &(LinkQueues[i]);
      if (queue->Head == queue->Tail) { // queue is empty
        queue->Handle = Handle;
        return queue;
      }
    }

    // try to allocate a new one
    if (NumLinks < MAX_LINKS - 1) {
      queue = &(LinkQueues[NumLinks]);
      queue->Handle = Handle;
      NumLinks++;
      return queue;
    }

    // otherwise fail
    return NULL;
  }



  /*
   * Add an entry into the appropriate link queue.  Return value indicates
   * whether an entry was successfully allocated.
   */

  result_t QueueNewMessage(uint32 DestID, uint8 *Data, uint16 Length) {
    uint8           ind;
    tRetryQueue     *queue;
    tRetryPacket    *packet;

    if ((queue = GetLinkQueue(DestID)) == NULL) {
        trace(TRACE_DEBUG_LEVEL,"Failed packet to dest %05X\r\n", DestID);
        return FAIL;
    }

    if ((ind = GetFreeRetryListIndex()) == MaxRetryPackets) {
        trace(TRACE_DEBUG_LEVEL,"Retry Queue full\r\n");
      return FAIL;
    }

    queue->RetryIndex[queue->Head] = ind;
    queue->Head = NEXT_BUFFER(queue->Head, MAX_PACKET_PER_LINK);

    NumRetryEntries++;

    packet = &(RetryList[ind]);
    packet->DestID       = DestID;
    packet->Data         = Data;
    packet->Length       = Length;
    packet->Valid        = TRUE;
    packet->Queued       = FALSE;
    packet->RetryAttempt = 0;
    {
        int size;
        size = queue->Head - queue->Tail;
        size = (queue->Head < queue->Tail) ? size + MAX_PACKET_PER_LINK : size;
        trace(TRACE_DEBUG_LEVEL,"Message %d for %05X channel %d id %d\n", size,  DestID, ((tiMoteHeader *)Data)->channel, *((uint32 *)((uint32) Data + sizeof(tiMoteHeader))));
    }

    if (WaitToSend == TRUE) return SUCCESS;
      
    // If this is the only packet for this link, try to send it now.
    if ((queue->Head == NEXT_BUFFER(queue->Tail, MAX_PACKET_PER_LINK)) &&
        (call HCIData.Send((uint32) Data, queue->Handle, Data, Length)
           == SUCCESS)){
      packet->Queued = TRUE;
      call StatsLogger.BumpCounter(NUM_TOTAL_SEND, 1);
      if (OutstandingPackets == 0) {
         // assume Tx is On for sake of logging
         call StatsLogger.StartTimer(MSEC_MOTE_TX);
      }
      OutstandingPackets++;
    } else {
      StartTimer();
    }

    return SUCCESS;
  }



  void ReleaseQueueEntry(tRetryQueue *queue) {
    tRetryPacket    *packet;

    packet = GetQueuePacket(queue);
    queue->Tail = NEXT_BUFFER(queue->Tail, MAX_PACKET_PER_LINK);
    NumRetryEntries--;
    packet->Valid = FALSE;
    packet->Queued = FALSE;

    if (queue->Head == queue->Tail) queue->Handle = INVALID_HANDLE;

    // reset NumLinks, if necessary
    while ((NumLinks > 0) && (LinkQueues[NumLinks-1].Handle == INVALID_HANDLE)){
      NumLinks--;
    }
  }



  /*
   * Try to send a packet to the lower level and return SUCCESS if a new packet
   * is queued.  Only send a packet on a link which has no outstanding packets
   * to maintain at most one packet per link.
   */

  result_t SendNextBufferedPacket() {
    uint8           i;
    tRetryQueue     *queue;
    tRetryPacket    *packet;

    if (WaitToSend == TRUE) return FAIL;

    for (i = 0; i < NumLinks; i++) {
      queue = &(LinkQueues[LastQueuedLink]);
      if (queue->Head != queue->Tail) {
        packet = GetQueuePacket(queue);

        if (packet->Queued == FALSE) {
          if ((call HCIData.Send((uint32) (packet->Data), queue->Handle,
                 packet->Data, packet->Length)) == SUCCESS) {
            LastQueuedLink = NEXT_BUFFER(LastQueuedLink, NumLinks);
            packet->Queued = TRUE;
            call StatsLogger.BumpCounter(NUM_TOTAL_SEND, 1);
            if (OutstandingPackets == 0) {
               // assume Tx is On for sake of logging
               call StatsLogger.StartTimer(MSEC_MOTE_TX);
            }
            OutstandingPackets++;
            return SUCCESS;
          } else {
            return FAIL;
          }
        }
      }
      LastQueuedLink = NEXT_BUFFER(LastQueuedLink, NumLinks);
    }
    // nothing else to queue, so stop the timer
    StopTimer();
    return FAIL;
  }



  task void DisplayQueueSizes() {
    int i, size;
    tRetryQueue     *queue;
    char str[80];

    sprintf(str, "Queue sizes ");
    for (i = 0; i < NumLinks; i++) {
      queue = &(LinkQueues[i]);
      if (queue->Head < queue->Tail) {
        size = queue->Head + MAX_PACKET_PER_LINK - queue->Tail;
      } else {
        size = queue->Head - queue->Tail;
      }
      if (size < 0) {
        sprintf(str, "%s head=%d, tail=%d, size=%d", str, queue->Head, queue->Tail, size);
      } else {
        sprintf(str, "%s %d", str, size);
      }
    }
    trace(TRACE_DEBUG_LEVEL,"%s \n", str);
  }



  task void SendPackets() {
    SendNextBufferedPacket();
  }



  /*
   * Find the message pointer in the queue for the given handle and remove it.
   * Since there is at most one outstanding packet per link, this should be the
   * oldest entry.  Free up the entry in the RetryList and try to send the next
   * buffered message.
   */

  void MessageDone( tHandle Handle, char *Data) {
    tRetryQueue     *queue;
    tRetryPacket    *packet;

    if ((queue = GetHandleQueue(Handle)) != NULL) {

      packet = GetQueuePacket(queue);
      if (packet->Data == Data) {

        ReleaseQueueEntry(queue);
        post SendPackets();
//        post DisplayQueueSizes();
        return;

      } else {
          trace(TRACE_DEBUG_LEVEL,"Error - Trying to free a resend queue OOO\n");
      }
    }
    trace(TRACE_DEBUG_LEVEL,"Error - Could not find message to de-queue\n");
       
  }



  void Initialize() {
    int i;

    call NetworkTopology.GetNodeID(&ThisNodeID);
    call BTBuffer.Initialize();

    // LN : Allocate space for queues from BRAM, running out of IRAM
    RetryList = (tRetryPacket *) call Memory.alloc(MAX_RETRY_PACKETS * sizeof(tRetryPacket));
    MaxRetryPackets = MAX_RETRY_PACKETS;
    if (RetryList == NULL) {
       TM_SetPio(4);
       TM_SetPio(5);
       TM_SetPio(6);

       // Try minimal amount
       RetryList = (tRetryPacket *) call Memory.alloc(MIN_RETRY_PACKETS * sizeof(tRetryPacket));
       MaxRetryPackets = MIN_RETRY_PACKETS;
       if (RetryList == NULL) {
          // Wait, can't do anything anyway
          while(1);
       }
    }
    
    NumRetryEntries = 0;
    NumLinks = 0;
    NextFreeEntry = 0;
    LastQueuedLink = 0;
    PacketCount = 0;
    OutstandingPackets = 0;

    TimerRunning = FALSE;
    WaitToSend = FALSE;

    for (i = 0; i < MAX_LINKS; i++) {
      LinkQueues[i].Handle = INVALID_HANDLE;
      LinkQueues[i].Head = 0;
      LinkQueues[i].Tail = 0;
    }
  }



/*
 * Start of NetworkPacket interface.
 */

  command result_t NetworkPacket.Initialize[uint8 channel]() {
    Initialize();
    return SUCCESS;
  }



  command result_t NetworkPacket.Send[uint8 Channel]( uint32 Dest, uint8* Data,
                                                      uint16 Length) {
    tiMoteHeader  *ptr;

    ptr = (tiMoteHeader *) ((uint32) Data - sizeof(tiMoteHeader));

    ptr->dest = Dest;
    ptr->source = ThisNodeID;
    ptr->channel = Channel;
    ptr->seq = PacketCount;
    PacketCount++; PacketCount &=0x7FFFFFFF;

    return QueueNewMessage(Dest, (char *) ptr, Length + sizeof (tiMoteHeader));
  }

 

  default event result_t NetworkPacket.SendDone[uint8 Channel](char * data) {
    return SUCCESS;
  }



  default event result_t NetworkPacket.Receive[uint8 Channel]( uint32 Source,
                                                               uint8 *Data,
                                                               uint16 Length) {
    return SUCCESS;
  }



  command char *NetworkPacket.AllocateBuffer[uint8 Channel](uint16 BufferSize) {
    char *buf;
    buf = call BTBuffer.AllocateBuffer(BufferSize + IMOTE_HEADER_SIZE);
    if (buf == NULL) return NULL;
    return (char *) ((uint32) buf + IMOTE_HEADER_SIZE);
  }



  command result_t NetworkPacket.ReleaseBuffer[uint8 Channel](char *BufferPtr) {
    char *buf;
    buf = (char *) ((uint32) BufferPtr - IMOTE_HEADER_SIZE);
    return call BTBuffer.ReleaseBuffer(buf);
  }

/*
 * End of NetworkPacket interface.
 */



/*
 * Start of RelayPacket interface.
 */

  command result_t RelayPacket.Initialize() {
    Initialize();
    return SUCCESS;
  }



  command result_t RelayPacket.Send( uint32 Dest, uint8* Data, uint16 Length) {
    char  *ptr;

    ptr = (char *) ((uint32) Data - sizeof(tiMoteHeader));

    return QueueNewMessage(Dest, ptr, Length + sizeof (tiMoteHeader));
  }

 

  default event result_t RelayPacket.SendDone(char * data) {
    return SUCCESS;
  }



  default event result_t RelayPacket.Receive( uint32 Source,
                                              uint8 *Data,
                                              uint16 Length) {
    return SUCCESS;
  }



  command char *RelayPacket.AllocateBuffer(uint16 BufferSize) {
    char *buf;
    buf = call BTBuffer.AllocateBuffer(BufferSize + IMOTE_HEADER_SIZE);
    if (buf == NULL) return NULL;
    return (char *) ((uint32) buf + IMOTE_HEADER_SIZE);
  }



  command result_t RelayPacket.ReleaseBuffer(char *BufferPtr) {
    char *buf;
    buf = (char *) ((uint32) BufferPtr - IMOTE_HEADER_SIZE);
    return call BTBuffer.ReleaseBuffer(buf);
  }


/*
 * End of RelayPacket interface.
 */



/*
 * Start of HCIData interface.
 */


  void SignalSendDone(tiMoteHeader *headerPtr, char *dataPtr) {
    if (headerPtr->source != ThisNodeID) { // relayed packet
      signal RelayPacket.SendDone(dataPtr);
    } else {
      signal NetworkPacket.SendDone[headerPtr->channel](dataPtr);
    }
  }



  event result_t HCIData.SendDone( uint32 TransactionID,
                                   tHandle Connection_Handle,
                                   result_t Acknowledge) {
    char          *dataPtr;
    tiMoteHeader  *headerPtr;
    tRetryQueue   *queue;
    tRetryPacket  *packet;

    // TransactionID contains pointer to iMoteHeader
    headerPtr = (tiMoteHeader *) TransactionID;
    dataPtr = (char *) ((uint32) headerPtr + sizeof(tiMoteHeader));

    OutstandingPackets--;
    if (OutstandingPackets == 0) {
       // Done sending packets, stop TxOn timer
       call StatsLogger.StopTimerUpdateCounter(MSEC_MOTE_TX);
    }

    if (Acknowledge == SUCCESS) {

      MessageDone( Connection_Handle, (char *) headerPtr);
      SignalSendDone(headerPtr, dataPtr);
      return SUCCESS;

    }
    
    trace(TRACE_DEBUG_LEVEL,"Send fail dest = %05X\n", headerPtr->dest);

    // otherwise requeue message and clear out invalid entries from retry queue

    if ((queue = GetHandleQueue(Connection_Handle)) == NULL) {
      trace(TRACE_DEBUG_LEVEL,"Error - Can't find link queue for handle in SendDone\n");
      return FAIL;
    }

    packet = GetQueuePacket(queue);
    if ((uint32) packet->Data != TransactionID) {

      trace(TRACE_DEBUG_LEVEL,"Error - Wrong data packet returned to SendDone\n");
      ReleaseQueueEntry(queue);
      SignalSendDone(headerPtr, dataPtr);
      return FAIL;

    }

    if (packet->RetryAttempt >= MAX_RETRY_ATTEMPTS) {

      ReleaseQueueEntry(queue);
      SignalSendDone(headerPtr, dataPtr);

    } else {

      packet->RetryAttempt++;
      packet->Queued = FALSE;
      StartTimer();

    }

    return SUCCESS;
  }



  /*
   * Use the channel ID to demux the incoming message.  If the message is not
   * intended for this node send the packet to the relay module.
   */

  event result_t HCIData.ReceiveACL( uint32  TransactionID,
                                     tHandle Connection_Handle,
                                     uint8   *Data,
                                     uint16  DataSize,
                                     uint8   DataFlags) {
    tiMoteHeader    *headerPtr;
    tHandle         NextHandle;
    uint32          NextNodeID;
    uint32          Source;

    call StatsLogger.BumpCounter(NUM_TOTAL_RECV, 1);

    headerPtr = (tiMoteHeader *) Data;

    /*
     * First check whether the Source ID is valid.  If the ID is outside of
     * the known range then something bad happened so drop the packet.
     */

    Source = headerPtr->source;
    if ((Source > 0x90000) || ((Source < 0x85000) && (Source > 256))) {
        trace(TRACE_DEBUG_LEVEL,"Dropping packet with bad source %0X\r\n", Source);
        return SUCCESS;
    }

    /*
     * Drop packets with channel bogus channel ID's
     */
    if (headerPtr->channel > 255) { // arbitrary boundary
        trace(TRACE_DEBUG_LEVEL,"Dropping packet with bad channel %d\r\n", headerPtr->channel);   
        return SUCCESS;
    }

    /*
     * This needs to move to the multi-hop routing layer.  If someone sends
     * this node a message we need to make sure we know how to reply.
     * So add source to the routing table.
     */
    if (call NetworkTopology.GetNextConnection(headerPtr->source, NULL,
          &NextHandle) == FAIL) {
      if (call NetworkTopology.NextHandle2NodeID(Connection_Handle, 
            &NextNodeID) == FAIL) {
          trace(TRACE_DEBUG_LEVEL,"Invalid Receive packet\n");
      } else {
        // add an entry with a very large hop count
        // this should get replaced by the normal routing mechanism
        call NetworkTopology.AddRoute(headerPtr->source, NextNodeID, 0xFFF);
      }
    }

    if (headerPtr->dest == ThisNodeID) {

      signal NetworkPacket.Receive[headerPtr->channel]( headerPtr->source,
                                   &(Data[sizeof(tiMoteHeader)]),
                                   DataSize - sizeof(tiMoteHeader));

    } else { // need to forward this message

      signal RelayPacket.Receive( headerPtr->source,
                                  &(Data[sizeof(tiMoteHeader)]),
                                  DataSize - sizeof(tiMoteHeader));
    }
    return SUCCESS;
  }

/*
 * End of HCIData interface.
 */



/*
 * Start of Timer interface.
 */

  event result_t Timer.fired() {

    post SendPackets();
    return SUCCESS;
  }

/*
 * End of Timer interface
 */

  event result_t SuspendDataTraffic (bool status) {

    WaitToSend = status;
    if (WaitToSend == FALSE) {
      post SendPackets();
      StartTimer();
    }

    return SUCCESS;
  }

  /*
   * Start of HCILinkControl
   */

  event result_t HCILinkControl.Command_Status_Inquiry(uint8 Status) {
    return SUCCESS;
  }

  event result_t HCILinkControl.Inquiry_Result( uint8 Num_Responses,
                                 tBD_ADDR *BD_ADDR_ptr,
                                 uint8 *Page_Scan_Repetition_Mode_ptr,
                                 uint8 *Page_Scan_Period_Mode,
                                 uint8 *Page_Scan_Mode,
                                 uint32 *Class_of_Device,
                                 uint16 *Clock_Offset) {
    return SUCCESS;
  }

  event result_t HCILinkControl.Inquiry_Complete( uint8 Status ) {
    return SUCCESS;
  }

  event result_t HCILinkControl.Command_Complete_Inquiry_Cancel( uint8 Status) {
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
                                     uint32 Class_of_Device,//3 bytes meaningful
                                     uint8 Link_Type) {
    return SUCCESS;
  }

  // Catch disconnect events and clear the appropriate send queue
  event result_t HCILinkControl.Disconnection_Complete( uint8 Status,
                                         tHandleId Connection_Handle,
                                         uint8 Reason) {


    char          *dataPtr;
    tiMoteHeader  *headerPtr;
    tRetryQueue   *queue;
    tRetryPacket  *packet;

    while ((queue = GetHandleQueue(Connection_Handle)) != NULL) {

      packet = GetQueuePacket(queue);
      headerPtr = (tiMoteHeader *) packet->Data;
      dataPtr = (char *) ((uint32) headerPtr + sizeof(tiMoteHeader));
      ReleaseQueueEntry(queue);
      SignalSendDone(headerPtr, dataPtr);

    }

    return SUCCESS;
  }

  /*
   * End of HCILinkControl
   */

}


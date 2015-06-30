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
 * This module manages the network data traffic for each node.
 * Since network command packets appear as data packets to the lower levels
 * they are passed from this component to the Network Command component for
 * processing.  This keeps the interface to the lower level as a pure HCI
 * interface.
 *
 * This component creates a buffered list of destinations and pointers to
 * packets to send.  If the lower level send fails the destination and packet
 * pointer are saved and retried after all other outstanding packets.  After
 * MAX_NUM_RETRY the packet send fails and a SendDone with a NACK is returned
 * to the upper level.
 */

module NetworkDataM
{
  provides {
    interface NetworkPacket[uint8 channel];

    event result_t SuspendDataTraffic (bool status);
  }

  uses {
    interface BTBuffer;
    interface HCIData;
    interface Timer;
    interface NetworkTopology;
    event result_t InvalidDest(uint32 Dest);
  }
}


implementation
{
#define TRACE_DEBUG_LEVEL DBG_PACKET

  // The PacketList contains the list of destinations and packet pointers
  // currently in flight

  // should match constants in NetworkC.nc
  enum uint8 { CHANNEL_DATA=0,
               CHANNEL_RELAY,
               CHANNEL_MONITOR,
               CHANNEL_SCATTERNET_FORMATION,
               CHANNEL_ROUTING,
               CHANNEL_PROPERTIES };

  typedef struct tRetryPacket {
    uint32 DestID;
    char   *Packet;    // lower level packet to send (including iMote header
    bool   Valid;      // whether the entry contains a message to send
                       // necessary because messages may be acked out of order
    bool   Ack;        // whether message has been ack'd by the lower level
    uint16 Length;
    uint32 RetryAttempt;
  } tRetryPacket;

  #define MAX_RETRY_PACKETS 40        // arbitrary
  #define RETRY_INTERVAL 1000          // 1 s timer to retry sends
  #define MAX_RETRY_ATTEMPTS 100      // # of times to retry sending a packet

  tRetryPacket RetryList[MAX_RETRY_PACKETS];
  uint32       RetryHead;              // oldest entry in the retry queue
  uint32       NextRetry;              // next entry to try to send
  uint32       RetryTail;              // next empty slot to fill
  // (RetryHead == RetryTail) => queue is empty

  uint32       ThisNodeID;
  uint32       TimerRunning;

  uint32       PacketCount;
  bool         WaitToSend;    // Whether it is OK to send a packet


/*
 * Start of NetworkPacket interface.
 */

  // Any of the NetworkPacket interfaces can setup the arrays.  Choice of
  // CommandPacket is arbitrary
  command result_t NetworkPacket.Initialize[uint8 channel]() {

    call NetworkTopology.GetNodeID(&ThisNodeID);
    call BTBuffer.Initialize();

    TimerRunning = 0;
    RetryHead = 0;
    NextRetry = 0;
    RetryTail = 0;
    PacketCount = 0;
    WaitToSend = FALSE;

    return SUCCESS;
  }



  int GetRetryIndex(char *data) {
    int ind;

    ind = RetryHead;

    while ((ind != RetryTail) &&              // stop at the end of the list
           ((RetryList[ind].Valid != TRUE) || // find a valid packet
            (RetryList[ind].Packet != data) ||// pointing to by this entry
            (RetryList[ind].Ack != FALSE))) { // which has not been acknowledged
      
      ind = (ind == (MAX_RETRY_PACKETS - 1)) ? 0 : ind + 1;
    }

    if (ind == RetryTail) {
      return -1;
    } else {
      return ind;
    }
  }

int GetSendIndex(char *data) __attribute__ ((C, spontaneous)) {
  return GetRetryIndex(data);
}

  void TestQueueValidity() {
    int i;
    char *data;

    i = RetryHead;
    while (i != RetryTail) {
      if ((RetryList[i].Ack == FALSE) && (RetryList[i].Valid == TRUE)) {
        data = (char *) ((uint32) RetryList[i].Packet + sizeof(tiMoteHeader));
        if (call BTBuffer.IsAllocated(data) != SUCCESS) {
            trace(TRACE_DEBUG_LEVEL,"Unallocated packet in the retry queue\n");
          return;
        }
      }
      i = (i == (MAX_RETRY_PACKETS - 1)) ? 0 : i + 1;
    }
  }



  void AdvanceRetryHead() {
      while ((RetryHead != RetryTail) &&
             // this shouldn't be necessary.  How is NextRetry.Ack true or
             // NextRetry.Valid false?     (RetryHead != NextRetry) &&
             ((RetryList[RetryHead].Ack == TRUE) ||
              (RetryList[RetryHead].Valid == FALSE))) {
          
          if (RetryHead == NextRetry) {
              trace(TRACE_DEBUG_LEVEL,"RetryHead passing NextRetry\n");
          }
          RetryHead = (RetryHead == (MAX_RETRY_PACKETS - 1)) ? 0 : RetryHead + 1;
          
      }
    TestQueueValidity();
  }
  


  void AckQueuedMessage(char *dataPtr) {
    int ind;

    // find entry in Retry queue;

    ind = GetRetryIndex(dataPtr);
    if (ind == -1) {
      trace(TRACE_DEBUG_LEVEL,"Could not find bufferd packet\n");
      return; // entry is not in the queue;
    }

    RetryList[ind].Ack = TRUE;

    ind = (ind == (MAX_RETRY_PACKETS - 1)) ? 0 : ind + 1;

    AdvanceRetryHead();
    return;
  }



  /*
   * Add an entry to the end of the retry queue.  Initialize it to valid and
   * not acknowledged.  Return the queue index on success or -1 on failure.
   */

  result_t AddNewMessage(uint32 DestID, uint8 *Data, uint16 Length) {
    int NextTail;
#if 1 // not yet - now
    tiMoteHeader *headerPtr;
    char *dataPtr;
#endif 

    NextTail = (RetryTail == (MAX_RETRY_PACKETS - 1)) ? 0 : RetryTail + 1;

    if (NextTail == RetryHead) { // queue is full
#if 1 // not yet - now
      headerPtr = (tiMoteHeader *) RetryList[RetryHead].Packet;
      dataPtr = (char *) ((uint32) headerPtr + sizeof(tiMoteHeader));
      AckQueuedMessage((char *) headerPtr);
      if (headerPtr->source != ThisNodeID) { // relayed packet
        signal NetworkPacket.SendDone[CHANNEL_RELAY](dataPtr);
      } else {
        signal NetworkPacket.SendDone[headerPtr->channel](dataPtr);
      }
      trace(TRACE_DEBUG_LEVEL,"Send Queue Full - dropping oldest entry\n");
#endif
      trace(TRACE_DEBUG_LEVEL,"Send Queue Full\n");
      return FAIL;
    } /* else */
    {
      RetryList[RetryTail].DestID = DestID;
      RetryList[RetryTail].Packet = Data;
      RetryList[RetryTail].Length = Length;
      RetryList[RetryTail].Ack = FALSE;
      RetryList[RetryTail].Valid = TRUE;
      RetryList[RetryTail].RetryAttempt = 0;

      RetryTail = NextTail;
    TestQueueValidity();
      return SUCCESS;
    }
  }






  result_t ReQueueMessage(char *Data) {
    int ind;
    tRetryPacket *packet;

    ind = RetryHead;
    while ((ind != RetryTail) && (RetryList[ind].Packet != Data)) {
      ind = (ind == (MAX_RETRY_PACKETS - 1)) ? 0 : ind + 1;
    }

    if (ind == RetryTail) {
      trace(TRACE_DEBUG_LEVEL,"Cannot find message to re-queue\n");
      return FAIL;
    }

    packet = &(RetryList[ind]);
    packet->Valid = FALSE;
    ind = (RetryTail == (MAX_RETRY_PACKETS - 1)) ? 0 : RetryTail + 1; 

    // still room in queue and haven't exceeded retry attempts
    if ((ind != RetryHead) && (packet->RetryAttempt < MAX_RETRY_PACKETS)) {
      RetryList[RetryTail].DestID = packet->DestID;
      RetryList[RetryTail].Packet = packet->Packet;
      RetryList[RetryTail].Length = packet->Length;
      RetryList[RetryTail].Ack = FALSE;
      RetryList[RetryTail].Valid = TRUE;
      RetryList[RetryTail].RetryAttempt = packet->RetryAttempt + 1;

      RetryTail = ind;
    TestQueueValidity();

      return SUCCESS;
    } else {
      trace(TRACE_DEBUG_LEVEL,"Retry queue full\n");
      return FAIL;
    }
  }

    



  // Process the next message indexed by NextRetry.
  // Lookup destination in router table.  Return FAIL and invalidate the entry
  // if the RT entry does not exist.
  // If the lower level send exerts back pressure return FAIL.
  // Otherwise advance the NextRetry index and return SUCCESS.

  result_t SendNextPacket() {
    tHandle NextHandle;
    tRetryPacket *packet;

    packet = &(RetryList[NextRetry]);
    if (call NetworkTopology.GetNextConnection(packet->DestID, NULL,&NextHandle)
      == FAIL) {
      // can't get there from here
      packet->Valid = FALSE;
      NextRetry = (NextRetry == (MAX_RETRY_PACKETS - 1)) ? 0 : NextRetry + 1;
      AdvanceRetryHead();
      
      trace(TRACE_DEBUG_LEVEL,"Invalid Dest %05X\n", packet->DestID);

#if 0 // remove for hard-wired
      signal InvalidDest(packet->DestID); // broadcast invalid dest packet
#endif
      return FAIL;
    }

    TestQueueValidity();
    if ((call HCIData.Send((uint32) packet->Packet, NextHandle, packet->Packet,
                           packet->Length)) == SUCCESS) {

      NextRetry = (NextRetry == (MAX_RETRY_PACKETS - 1)) ? 0 : NextRetry + 1;

    } // otherwise packet gets queued

    return SUCCESS;
  }


  task void SendPackets() {
    uint32 LastRetry;  // make sure that SendNextPacket is making progress
    tiMoteHeader *headerPtr;
    char *dataPtr;

    LastRetry = 0xFFFFFFFF; // enter loop at least once
    // Loop through SendNextPacket until we can't send anymore
    while ((WaitToSend == FALSE) &&
           (LastRetry != NextRetry) &&
           (NextRetry != RetryTail)) {

      LastRetry = NextRetry;
      if (SendNextPacket() == FAIL) { // unknown dest for last retry
        headerPtr = (tiMoteHeader *) RetryList[LastRetry].Packet;
        dataPtr = (char *) ((uint32) headerPtr + sizeof(tiMoteHeader));
        if (headerPtr->source != ThisNodeID) { // relayed packet
          signal NetworkPacket.SendDone[CHANNEL_RELAY](dataPtr);
        } else {
          signal NetworkPacket.SendDone[headerPtr->channel](dataPtr);
        }
      }
    }

    if (NextRetry == RetryTail) { // retry queue is empty
      TimerRunning = 0;
      call Timer.stop();
    }

  }


  command result_t NetworkPacket.Send[uint8 Channel]( uint32 Dest, uint8* Data,
                                                      uint16 Length) {
    tiMoteHeader  *headerPtr;
    bool          RetryPending;

    headerPtr = (tiMoteHeader *) ((uint32) Data - sizeof(tiMoteHeader));

    if (Channel != CHANNEL_RELAY) { //don't over-write relayed header
      headerPtr->dest = Dest;
      headerPtr->source = ThisNodeID;
      headerPtr->channel = Channel;
      headerPtr->seq = PacketCount;
      PacketCount++; PacketCount &=0x7FFFFFFF;
    }

    RetryPending = (NextRetry != RetryTail) ? TRUE : FALSE;

    if (AddNewMessage(Dest, (char *)headerPtr, Length + sizeof (tiMoteHeader))
         != SUCCESS) {
      return FAIL;
    }

    if ((RetryPending == FALSE) && (WaitToSend == FALSE)) {
      // this packet is next in line so try to send it right away.
      if (SendNextPacket() == FAIL) return FAIL;
    }

    if ((NextRetry != RetryTail) && (TimerRunning == 0)) {
      // if a message is pending make sure that the retry timer is on.
      TimerRunning = 1;
      call Timer.start(TIMER_REPEAT, RETRY_INTERVAL);
    }
    return SUCCESS;
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
    return call BTBuffer.AllocateBuffer(BufferSize);
  }



  command result_t NetworkPacket.ReleaseBuffer[uint8 Channel](char *BufferPtr) {
    int ind;
    char *data;

    data = (char *) ((uint32) BufferPtr - sizeof(tiMoteHeader));

    ind = GetRetryIndex(data);
    if ((ind != -1) && (RetryList[ind].Valid == TRUE) &&
       (RetryList[ind].Ack == FALSE)) {
      trace(TRACE_DEBUG_LEVEL,"Releasing a valid buffer in the retry queue\n");
      RetryList[ind].Valid = FALSE;
      AdvanceRetryHead();
    }
      
    if (call BTBuffer.ReleaseBuffer(BufferPtr) == SUCCESS) {
      return SUCCESS;
    } else {
      trace(TRACE_DEBUG_LEVEL,"Releasing unallocated buffer\n");
      return FAIL;
    }
  }

/*
 * End of NetworkPacket interface.
 */




/*
 * Start of HCIData interface.
 */

  event result_t HCIData.SendDone( uint32 TransactionID,
                                   tHandle Connection_Handle,
                                   result_t Acknowledge) {
    char          *dataPtr;
    tiMoteHeader  *headerPtr;

    // TransactionID contains pointer to iMoteHeader
    headerPtr = (tiMoteHeader *) TransactionID;
    dataPtr = (char *) ((uint32) headerPtr + sizeof(tiMoteHeader));

    if (Acknowledge == SUCCESS) {

      AckQueuedMessage((char *) headerPtr);
      if (headerPtr->source != ThisNodeID) { // relayed packet
        signal NetworkPacket.SendDone[CHANNEL_RELAY](dataPtr);
      } else {
        signal NetworkPacket.SendDone[headerPtr->channel](dataPtr);
      }
      post SendPackets();

    } else { // requeue message and clear out invalid entries from retry queue

      if (ReQueueMessage((char *) headerPtr) == SUCCESS) {
        // rely on timer to resend NACK'd packets
        // make sure timer is running
        if (TimerRunning == 0) {
          TimerRunning = 1;
          call Timer.start(TIMER_REPEAT, RETRY_INTERVAL);
        }
      } else {
        if (headerPtr->source != ThisNodeID) { // relayed packet
          signal NetworkPacket.SendDone[CHANNEL_RELAY](dataPtr);
        } else {
          signal NetworkPacket.SendDone[headerPtr->channel](dataPtr);
        }
      }
      AckQueuedMessage((char *) headerPtr);
    }

    return SUCCESS;
  }


  /*
   * Use the channel ID to demux the incoming message.
   * If the message is not intended for this node, overload the channel ID
   * and send the packet to the relay module.  This assumes no app uses the
   * CHANNEL_RELAY channel.
   */

  event result_t HCIData.ReceiveACL( uint32  TransactionID,
                                     tHandle Connection_Handle,
                                     uint8   *Data,
                                     uint16  DataSize,
                                     uint8   DataFlags) {
    tiMoteHeader    *headerPtr;
    tHandle         NextHandle;
    uint32          NextNodeID;

    headerPtr = (tiMoteHeader *) Data;

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

      signal NetworkPacket.Receive[CHANNEL_RELAY]( headerPtr->source,
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
    return SUCCESS;
  }
}


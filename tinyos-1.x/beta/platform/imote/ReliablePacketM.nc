/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/*
 * This module implements a simple reliable packet protocol.  A sequence
 * number is added to the sent packet.  When the destination received
 * the packet, it sends an ACK packet.  The ACK packet consists of only
 * the sequence number, no command field is needed, a 0 payload packet
 * is assumed to be an ACK packet. When this module receives the 
 * ACK, it removes the entry and signals the SendDone to the app.
 * A fixed retry interval is set and retry count is set, the module will
 * continue sending the packet, until an ACK is received, or the retry
 * count is exhausted.
 * Only 4 extra bytes of overhead are used  
 */
module ReliablePacketM {

   provides {
      interface ReliablePacket;
   }

   uses {
      interface NetworkPacket;
      interface Timer;

   }
}

implementation {

//#define TRACE_DEBUG_LEVEL 0ULL	// disable debug
#define TRACE_DEBUG_LEVEL DBG_USR1	// enable debug

#define MAX_PACKETS 8
#define RETRY_INTERVAL 400
#define NUM_RETRIES 60
#define ACK_FLAG 0x80000000	// msb indicates an ACK packet
#define SEQ_MASK 0x7fffffff
#define MAX_SEQ  ACK_FLAG

   uint32 CurrentSeq;
   uint16 Retries;
   uint16 RetryInterval;
   uint8  NumPacketsInProgress;
   uint8  NextSlot;
   bool   TimerRunning;

   typedef struct tSendInfo {
      uint32 seq;
      uint32 dest;
      uint8  *packet;
      uint16 len;
      uint8 retries;   
      uint8 acked;	// Send done returned by lower layer
   } tSendInfo;
   
   tSendInfo PacketInfo[MAX_PACKETS];

   uint8 GetEmptySlot() {
      uint8 i;
      for (i=0; i<MAX_PACKETS; i++) {
         if (PacketInfo[i].dest == 0) {
            return i;
         }
      }
      return MAX_PACKETS;
   }

   /*
    * Find a slot with a specific Dest and seq number.  If the passed dest or seq = 0
    * then it is a don't care in the search
    */
   uint8 FindSlot(uint32 Dest, uint32 Seq) {
      uint8 i;
      for (i=0; i<MAX_PACKETS; i++) {
         if (((PacketInfo[i].dest == Dest) || (Dest == 0)) && 
             ((PacketInfo[i].seq == Seq) || (Seq == 0))) {
            return i;
         }
      }
      return MAX_PACKETS;
   }
   
   void init() {
      uint8 i;
      TimerRunning = false;
      CurrentSeq = 1;
      Retries = NUM_RETRIES;	// call can override
      NumPacketsInProgress = 0;
      NextSlot = 0;
      for (i=0; i<MAX_PACKETS; i++) {
         PacketInfo[i].dest = 0;
      }
   }

   /*
    * Reliable NetworkPacket Interface
    */
   command result_t ReliablePacket.Initialize() {
      init();
      return call NetworkPacket.Initialize();
   }

   command result_t ReliablePacket.SetNumRetries(uint8 NumRetries) {
      Retries = NumRetries;
      return SUCCESS;
   }

   command result_t ReliablePacket.Send(uint32 Destination, uint8 *Data,
                                        uint16 Length) {
      uint8 slot;
      uint32 *Hdr;

      // Check if we have enough space, don't allow 0 size packet
      if ((Length == 0) || (NumPacketsInProgress >= MAX_PACKETS)) {
         trace(TRACE_DEBUG_LEVEL,"RP : can't send\r\n");
         return FAIL;
      }

      // Put in Array and send it out
      slot = GetEmptySlot();
      if (slot == MAX_PACKETS) {
         trace(TRACE_DEBUG_LEVEL,"RP : no slots\r\n");
         return FAIL;
      }

      if (!TimerRunning) {
         atomic {
            call Timer.start(TIMER_REPEAT, RETRY_INTERVAL);
            TimerRunning = true;
         }
      }
   
      // Add sequence to header
      Data = Data - 4;
      Hdr = (uint32 *) Data;
      *Hdr = CurrentSeq;

      PacketInfo[slot].dest = Destination;
      PacketInfo[slot].packet = Data;
      PacketInfo[slot].len = Length+4;
      PacketInfo[slot].seq = CurrentSeq;
      PacketInfo[slot].retries = Retries;
      PacketInfo[slot].acked = 0;
      CurrentSeq++;
      if (CurrentSeq == MAX_SEQ) {
         CurrentSeq = 1;
      }
      NumPacketsInProgress++;

      // Send Packet
      if (call NetworkPacket.Send(Destination, Data, Length+4) == SUCCESS) {
         trace(TRACE_DEBUG_LEVEL,"RP:Sent packet to %5X, Seq %x\r\n", 
               Destination, PacketInfo[slot].seq);
         return SUCCESS;
      }
      
      trace(TRACE_DEBUG_LEVEL,"RP:Failed sending packet, %x to %5X\r\n", 
            PacketInfo[slot].seq, Destination);
      PacketInfo[slot].acked = 1;	// Didn't send it, don't wait for send done
      return FAIL;
   }

   command char *ReliablePacket.AllocateBuffer(uint16 BufferSize) {
      char *Hdr; 
      // Add space for this layer's header, just sequence number
      Hdr = call NetworkPacket.AllocateBuffer(BufferSize+4);
      if (Hdr == NULL) {
        return NULL;
      }
      return (Hdr+4);
   }

   command result_t ReliablePacket.ReleaseBuffer(char *BufferPtr) {
      return call NetworkPacket.ReleaseBuffer(BufferPtr-4);
   }

   /*
    * Regular Network Packet
    */
   event result_t NetworkPacket.SendDone(char *data) {
      uint32 *Hdr;
      uint8 slot;

      Hdr = (uint32 *) data;

      trace(TRACE_DEBUG_LEVEL,"RP:senddone : seq %x\r\n", *Hdr);

      // If ACK packet, just release the buffer
      if ((*Hdr & ACK_FLAG) == ACK_FLAG) {
         call NetworkPacket.ReleaseBuffer(data);
         return SUCCESS;
      }

      // Data Packet, Find the packet, set the Acked flag
      slot = FindSlot(0, *Hdr);		// Dest field is don't care
      if (slot == MAX_PACKETS) {
         trace(TRACE_DEBUG_LEVEL,"RP:senddone : can't find slot %x\r\n", *Hdr);
         call NetworkPacket.ReleaseBuffer(data);
         return SUCCESS;
      }
       
      PacketInfo[slot].acked = 1;
      trace(TRACE_DEBUG_LEVEL,"RP:senddone : packet sent %x\r\n", *Hdr);
      return SUCCESS;
   }

   event result_t NetworkPacket.Receive(uint32 source, uint8 *data, 
                                        uint16 len) {
      uint32 *Hdr;
      uint8 slot;
      uint8 *AckPacket;
      uint32 seq;
      uint32 *seq_ptr;

      Hdr = (uint32 *) data;
      /*
       * check if this is a data packet or an ACK packet
       */
      if ((*Hdr & ACK_FLAG) == ACK_FLAG) {
         /*
          * Only sequence number, ACK packet
          * Find it in the list, and signal send done to app, for now we allow
          * multiple ACKS to go to the app, later we can add book keeping
          */
         
         seq = *Hdr & SEQ_MASK;
         slot = FindSlot(source, seq);		// Dest field is don't care
         if (slot == MAX_PACKETS) {
            trace(TRACE_DEBUG_LEVEL,"RP:ACK, can't find slot, %x\r\n", seq);
            return SUCCESS;
         }

         // Found the packet, send up the send done
         trace(TRACE_DEBUG_LEVEL,"RP:ACK, seq %X\r\n", seq);
         signal ReliablePacket.SendDone(PacketInfo[slot].packet+4, SUCCESS);

         NumPacketsInProgress--;
         PacketInfo[slot].dest = 0;

         if (TimerRunning && (NumPacketsInProgress == 0)) {
            atomic {
               call Timer.stop();
               TimerRunning = false;
            }
         }
        
         return SUCCESS;
      }

      // This is a data packet, send ACK to the other side and send the data up
      seq_ptr = (uint32 *) data;
      seq = *seq_ptr;
      trace(TRACE_DEBUG_LEVEL,"RP:Recv data from %5X, seq %x\r\n", source, seq);

      signal ReliablePacket.Receive(source, data+4, len-4);
      AckPacket = call NetworkPacket.AllocateBuffer(4);
      if (AckPacket == NULL) {
         return SUCCESS;
      }
      seq_ptr = (uint32 *) AckPacket;
      *seq_ptr = seq | ACK_FLAG;
      call NetworkPacket.Send(source, AckPacket, 4);
      return SUCCESS;
   }

   void task SendPackets() {
      uint8 i;
      uint32 *temp;
      if (NumPacketsInProgress == 0) {
         return;
      }

      for (i=0; i<MAX_PACKETS; i++) {
         NextSlot++;
         if (NextSlot == MAX_PACKETS) {
            NextSlot = 0;
         }
         if ((PacketInfo[NextSlot].dest != 0) && (PacketInfo[NextSlot].acked == 1)) {

            if (PacketInfo[NextSlot].retries == 0) {
               // Delete it, and signal to app
               trace(TRACE_DEBUG_LEVEL,"RP : Max retries, dropping packet, %x\r\n", PacketInfo[NextSlot].seq);
               signal ReliablePacket.SendDone(PacketInfo[NextSlot].packet+4, FAIL);

               NumPacketsInProgress--;
               PacketInfo[NextSlot].dest = 0;
               if (TimerRunning && (NumPacketsInProgress == 0)) {
                  atomic {
                     call Timer.stop();
                     TimerRunning = false;
                  }
               }
        
               continue;	// find next slot
            }
        
            if (call NetworkPacket.Send(PacketInfo[NextSlot].dest, 
                                        PacketInfo[NextSlot].packet,
                                        PacketInfo[NextSlot].len) == SUCCESS) {
               PacketInfo[NextSlot].acked = 0;
               PacketInfo[NextSlot].retries--;
               temp = (uint32 *) PacketInfo[NextSlot].packet;
               trace(TRACE_DEBUG_LEVEL,"RP : retrying packet slot %d, %x, %x\r\n", 
                     NextSlot, PacketInfo[NextSlot].seq, *temp);

               return;
            }
         }
      }
   }

   /*
    * Start of Timer interface.
    */

   event result_t Timer.fired() {
      post SendPackets();
      return SUCCESS;
   }
}

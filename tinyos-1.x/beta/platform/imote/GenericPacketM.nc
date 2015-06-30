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
 * This component implements a shim layer to isolate the Reliable Transport
 * component from the differences between the Berkeley motes and the imote
 */

module GenericPacketM {

   provides {
      interface GenericPacket;
      interface StdControl as Control;
   }

   uses {
      interface NetworkPacket;
      command result_t iMoteToTOSAddr(uint32 Imote_Addr, uint16 *TOSAddr);
      command result_t TOSToIMoteAddr(uint16 TOSAddr, uint32 *Imote_Addr);

   }
}

implementation {

#define TRACE_DEBUG_LEVEL DBG_PACKET


/*
 * Use 100 for now, 16 for iMote header, 4 for L2CAP header, 
 * DM3 is 121 B
 */
#define MAX_PACKET_PAYLOAD 100	

// Save the payload sizes in an array for now
#define MAX_NUM_PACKETS 8

   uint8 *Packets[MAX_NUM_PACKETS];
   uint8  Sizes[MAX_NUM_PACKETS];
   uint8  NumPackets;

   void AddPacket(uint8 *Packet, uint8 PayloadSize) {
      uint8 i;
      for (i=0; i < MAX_NUM_PACKETS; i++) {
         if (Packets[i] == NULL) {
            // empty slot
            Packets[i] = Packet;
            Sizes[i] = PayloadSize;
            NumPackets++;
            return;
         }
      }
   }

   void RemovePacket(uint8 *Packet) {
      uint8 i;
      for (i=0; i < MAX_NUM_PACKETS; i++) {
         if (Packets[i] == Packet) {
            // Found packet
            Packets[i] = NULL;
            NumPackets--;
            return;
         }
      }
   }

   uint8 GetPacketSize(uint8 *Packet) {
      uint8 i;
      for (i=0; i < MAX_NUM_PACKETS; i++) {
         if (Packets[i] == Packet) {
            return Sizes[i];
         }
      }
      return 0;
   }
   
   command result_t Control.init() {
      uint8 i;
      for (i=0; i < MAX_NUM_PACKETS; i++) {
         Packets[i] = NULL;
      }
      NumPackets = 0;
      return SUCCESS;
   }

   command result_t Control.start() {
      return SUCCESS;
   }

   command result_t Control.stop() {
      return SUCCESS;
   }

   command uint16 GenericPacket.GetMaxPayloadSize(wsnAddr dest) {
      return MAX_PACKET_PAYLOAD; 
   }

   command uint8 *GenericPacket.AllocateBuffer(wsnAddr Dest, 
                                                    uint16 PayloadSize) {
      uint8 *Packet;
      trace(TRACE_DEBUG_LEVEL,"GenericPacket Allocate %X len %d\n\r", Dest, PayloadSize);
      
      if (NumPackets >= MAX_NUM_PACKETS) {
         return NULL;
      }

      Packet = call NetworkPacket.AllocateBuffer(PayloadSize);
      if (Packet != NULL) {
         AddPacket(Packet, PayloadSize);
      }
      return Packet;
   }       

   command result_t GenericPacket.FreeBuffer(uint8 *Buffer) {
       trace(TRACE_DEBUG_LEVEL,"GenericPacket Free\n\r");
       
       RemovePacket(Buffer);
      return call NetworkPacket.ReleaseBuffer(Buffer);
   }

   command uint8 *GenericPacket.GetPayloadStart(uint8 *Buffer, 
                                                   uint16 *PayloadSizePtr) {
      *PayloadSizePtr = (uint16) GetPacketSize(Buffer);
      return Buffer;
   }

   command result_t GenericPacket.Send(wsnAddr addr, uint8 *Buffer, 
                                       uint16 PayloadSize) {
      uint32 temp;
      trace(TRACE_DEBUG_LEVEL, "GenericPacket send %x len %d data %x %x %x %x %x %x %x %x %x %x %x\n\r", 
            addr, PayloadSize, Buffer[0], Buffer[1], Buffer[2], Buffer[3], 
            Buffer[4], Buffer[5], Buffer[6], Buffer[7], Buffer[8], 
            Buffer[9], Buffer[10]);
      
      call TOSToIMoteAddr((uint16)addr, &temp);
      return call NetworkPacket.Send(temp, Buffer, PayloadSize);
   }

   /*
    * NetworkPacket Interface
    */
   event result_t NetworkPacket.SendDone(char *data) {
  
       trace(TRACE_DEBUG_LEVEL,"GenericPacket Send Done \n\r");
       
       signal GenericPacket.SendDone(data, SUCCESS);
      return SUCCESS;
   }

   event result_t NetworkPacket.Receive(uint32 source, uint8 *data, 
                                        uint16 len) {
      /* 
       * TODO : For now assume the data will only be valid in the context
       * of the receive.  Currently the ReliableTransportM and the app
       * will ensure this, we need a better solution
       */
      uint16 temp;
      
      trace(TRACE_DEBUG_LEVEL,"GenericPacket Receive %x len %d data %x %x %x %x %x %x %x %x %x %x %x\n\r", 
            source, len, data[0], data[1], data[2], data[3], data[4], data[5], 
            data[6], data[7], data[8],data[9], data[10]);
      
      call iMoteToTOSAddr(source, &temp);
      signal GenericPacket.Receive((wsnAddr)temp, data, len);
      return SUCCESS;
   }

}



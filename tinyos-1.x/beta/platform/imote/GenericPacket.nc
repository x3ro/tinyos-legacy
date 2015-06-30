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

includes WSN;
interface GenericPacket {

   /*
    * This command returns the maximum allowed payload size.  This is basically 
    * calculated from the maximum radio packet size - all the lower layer headers.
    * 
    * @return Maximum payload size size in bytes.
    */
   command uint16_t GetMaxPayloadSize(wsnAddr dest);


   /*
    * This command returns a buffer large enough to hold the requested payload size + all the 
    * lower layer headers.  The PayloadSize is assumed to be smaller or equal to the maximum
    * payload size returned by GetMaxPayloadSize.  The pointer returned by this function should
    * be treated as a packet handle.  No assumptions can be made about the location of the payload
    * within this packet.  To get the start of the payload, GetPayloadStart should be called.

    * @param PayloadSize The requested payload size in bytes. Passing 0 implies send the max possible
    * @return A buffer handle if successful, NULL if failed to allocate the buffer.
    */
   command uint8_t *AllocateBuffer(wsnAddr Dest, uint16_t PayloadSize);       


   /*
    * This command is called to free a buffer that was previously allocated using the
    * AllocateBuffer command.  The buffer pointer passed needs to match the buffer returned
    * by the AllocateBuffer.  
    *
    * @param Buffer The buffer handle returned by the AllocateBuffer command
    * @return SUCCESS if the Buffer handle passed is valid.  FAIL otherwise.
    */
   command result_t FreeBuffer(uint8_t *Buffer);


   /*
    * This command is used to get a pointer to the start of the payload.  The caller can
    * use this command to access the payload bytes.
    *
    * @param Buffer The buffer handle returned by the AllocateBuffer command.
    * @param PayloadSizePtr The command returns the PayloadSize of the passed Buffer. 
    * @return Ptr to the start of the Payload if the Buffer passed is valid, NULL otherwise.
    */
   command uint8_t *GetPayloadStart(uint8_t *Buffer, uint16_t *PayloadSizePtr);


   /*
    * This command is used to send a packet to the specified destination.
    *
    * @param Dest The destination address (MHOP destination). 
    * @param Buffer The buffer handle returned by the AllocateBuffer command.
    * @param PayloadSize The payload size in bytes.
    * @return SUCCESS if packet accepted by the lower layer.  FAIL otherwise.
    */
   command result_t Send(wsnAddr addr, uint8_t *Buffer, uint16_t PayloadSize);

   
   /*
    * This event is signaled by the lower layer to indicate the the packet was sent
    * out.  The caller is free to modify/release the buffer.
    *
    * @param Buffer The buffer handle returned by the AllocateBuffer command.
    */ 
   event result_t SendDone(uint8_t *Buffer, result_t success);


   /*
    * This event is signaled by the lower layer to indicate the receipt of a packet.
    * The buffer is valid until FreeBuffer is called.
    * Note, GetPayloadStart needs to be called to access the payload.
    *
    * @param Source The source of the packet (MHOP source).
    * @param Buffer The buffer handle.
    * @param PayloadSize The payload size in bytes.
    */

    event result_t Receive(wsnAddr Source, uint8_t *Buffer, uint16_t PayloadSize);   
}


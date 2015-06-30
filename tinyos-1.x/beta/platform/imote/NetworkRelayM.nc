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
 * This module manages network traffic not intended for this node.
 * The current default behavior is to forward the data to the destination
 * This module relies on the lower levels to retry on failure.
 */



module NetworkRelayM
{
  provides {
    interface StdControl as Control;
  }

  uses {
    interface NetworkPacket;
  }
}


implementation
{
#define TRACE_DEBUG_LEVEL 0ULL

  task void SendQueuedBuffers();
  #define MAX_RELAY_BUFFERS 50

  typedef struct tRelayBuffer {
    char    *data;
    uint16  length;
  } tRelayBuffer;


  tRelayBuffer    RelayBuffer[MAX_RELAY_BUFFERS]; // array of buffers to send
  int             RelayBufferCount;               // number of buffers pending


  command result_t Control.init() {

    int i;

    RelayBufferCount = 0;
    for (i = 0; i < MAX_RELAY_BUFFERS; i++) {
      RelayBuffer[i].data = NULL;
      RelayBuffer[i].length = 0;
    }

    return SUCCESS;
  } 



  command result_t Control.start() {
    call NetworkPacket.Initialize();
    return SUCCESS;
  }



  command result_t Control.stop() {
    return SUCCESS;
  }


/*
 * End of StdControl interface.
 */



/*
 * Start of NetworkPacket interface.
 */

  event result_t NetworkPacket.SendDone(char * data) {

    call NetworkPacket.ReleaseBuffer(data);
    post SendQueuedBuffers();

    return SUCCESS;
  }


  task void SendQueuedBuffers() {
    tiMoteHeader     *HeaderPtr;
    uint16           Length;
    char             *Data;
    uint32           i;

    for (i = 0; i < RelayBufferCount; i++) {

      Data = RelayBuffer[i].data;
      HeaderPtr = (tiMoteHeader *) ((uint32)Data - sizeof(tiMoteHeader));
      Length = RelayBuffer[i].length;

      if (call NetworkPacket.Send(HeaderPtr->dest, Data, Length) != SUCCESS) {
        call NetworkPacket.ReleaseBuffer(Data);
        
        trace(TRACE_DEBUG_LEVEL,"Relay send to %05X failed, dropping packet\n\r", HeaderPtr->dest);
      }
      RelayBuffer[i].data = NULL;
        
    }
    RelayBufferCount = 0; 
  }



  event result_t NetworkPacket.Receive( uint32 Source, uint8 *Data,
                                        uint16 Length) {
    
    char             *buffer;
    int              i;
    tiMoteHeader     *ReceiveHeaderPtr, *SendHeaderPtr;

    if (RelayBufferCount == (MAX_RELAY_BUFFERS - 1)) {
      // ran out of buffers
      post SendQueuedBuffers();
      trace(TRACE_DEBUG_LEVEL, "Relay Buffers full, dropping packet from %05X\n\r", Source);
      return FAIL;
    }

    buffer = call NetworkPacket.AllocateBuffer(Length);
    if (buffer == NULL ) {
        trace(TRACE_DEBUG_LEVEL, "Relay out of memory, dropping packet from %05X\n\r", Source);
        return FAIL;
    }

    // copy payload to relay
    for (i = 0; i < Length; i++) buffer[i] = Data[i];

    SendHeaderPtr = (tiMoteHeader *) ((uint32)buffer - sizeof(tiMoteHeader));
    ReceiveHeaderPtr = (tiMoteHeader *) ((uint32)Data - sizeof(tiMoteHeader));

    // copy header to relay
    SendHeaderPtr->source = ReceiveHeaderPtr->source;
    SendHeaderPtr->dest = ReceiveHeaderPtr->dest;
    SendHeaderPtr->channel = ReceiveHeaderPtr->channel;
    SendHeaderPtr->seq = ReceiveHeaderPtr->seq;

    RelayBuffer[RelayBufferCount].length = Length;
    RelayBuffer[RelayBufferCount].data = buffer;
    RelayBufferCount++;

    post SendQueuedBuffers();

    return SUCCESS;
  }

/*
 * End of NetworkPacket interface.
 */

}


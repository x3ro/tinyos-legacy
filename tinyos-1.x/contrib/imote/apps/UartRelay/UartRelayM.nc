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

module UartRelayM {

  provides interface StdControl;

  uses {
    interface StdControl as UARTControl;
    interface SendVarLenPacket as UARTSend;
    interface ReceiveData as UARTReceive;

    interface StdControl as NetworkControl;
    interface NetworkCommand;
    interface NetworkPacket;
    interface NetworkHardwired;
  }
}

implementation
{

  #define MASTER 0x85100
  #define SLAVE 0x85018

  uint32 ThisNodeID;
  uint32 Dest;

  // Try to buffer uart characters to forward over the radio
  #define MAX_RADIO_BUFFER_LENGTH 128
  char RadioBuffer[MAX_RADIO_BUFFER_LENGTH]; 

  int RadioBufferLength;
  bool RadioPacketPending;


  command result_t StdControl.init() {

    call UARTControl.init();
    call NetworkControl.init();
    call NetworkCommand.SetAppName("UartRelay");
    call NetworkPacket.Initialize();
    call NetworkHardwired.init();

    RadioBufferLength = 0;
    RadioPacketPending = FALSE;
    return SUCCESS;

  }



  command result_t StdControl.start() {

    call NetworkControl.start();
    call UARTControl.start();
    call NetworkHardwired.AddConnection(MASTER, SLAVE);
    call NetworkHardwired.start();
    call NetworkCommand.GetMoteID(&ThisNodeID);
    if (ThisNodeID == MASTER) {
      Dest = SLAVE;
      call NetworkCommand.SetProperty(NETWORK_PROPERTY_ACTIVE_ROUTING);
    }
    if (ThisNodeID == SLAVE) Dest = MASTER;

    return SUCCESS;
  }

  command result_t StdControl.stop() {

    call UARTControl.stop();
    return SUCCESS;

  }


/*
 * Start NetworkPacket interface
 */

  void SendRadioPacket() {
    char *buffer;
    int i;

    buffer = call NetworkPacket.AllocateBuffer(RadioBufferLength);
    if (buffer == NULL) {
      RadioBufferLength = 0;
      return;
    }
    for (i = 0; i < RadioBufferLength; i++) {
      buffer[i] = RadioBuffer[i];
    }
    if (call NetworkPacket.Send(Dest, buffer, RadioBufferLength) == FAIL) {
      call NetworkPacket.ReleaseBuffer(buffer);
    } else {
      RadioPacketPending = TRUE;
    }
    RadioBufferLength = 0;
  }


  task void SendPendingPacket() {

    if (RadioPacketPending == TRUE) return;
    SendRadioPacket();
  }


  event result_t NetworkPacket.SendDone(char *data) {

    call NetworkPacket.ReleaseBuffer(data);
    post SendPendingPacket();
    RadioPacketPending = FALSE;

    return SUCCESS;
  }

  event result_t NetworkPacket.Receive( uint32 Source,
                                        uint8  *Data,
                                        uint16 Length) {

    call UARTSend.send(Data, Length);
    return SUCCESS;

  }

/*
 * End NetworkPacket interface
 */

/*
 * Start of UARTSend interface
 */

  event result_t UARTSend.sendDone(uint8_t* packet, result_t success) {
    return SUCCESS;
  }

/*
 * End of UARTSend interface
 */

/*
 * Start of UARTReceive
 */
  event result_t UARTReceive.receive(uint8_t* buffer, uint32_t numBytesRead) {
    int i;

    for (i = 0; i < numBytesRead; i++) {
      if (RadioBufferLength < MAX_RADIO_BUFFER_LENGTH) {
        RadioBuffer[RadioBufferLength++] = buffer[i];
      }
    }

    if (RadioPacketPending == FALSE) SendRadioPacket();

    return SUCCESS;
      
  }

/*
 * End of UARTReceive
 */

/*
 * Start of NetworkCommand interface.
 */

  event result_t NetworkCommand.CommandResult( uint32 Command, uint32 value) {
     return SUCCESS;
  }

/*
 * End of NetworkCommand interface.
 */

}  


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


#define TRANSFER_DATA 1
module PingPongM {

  provides interface StdControl;

  uses {
    interface StdControl as NetworkControl;
    interface NetworkCommand;
    interface NetworkPacket;
    interface NetworkHardwired;
    interface Leds8;
  }
}

implementation
{

    uint32 ThisNodeID;
    uint32 OtherNodeID;
    uint8 *Packet;
    uint8 num;
    bool  master;

  #define NODE1 0x85018
  #define NODE2 0x85100

  command result_t StdControl.init() {

    result_t ok;
    ok = call NetworkControl.init();
    call NetworkCommand.SetAppName("PingPong");
    call NetworkPacket.Initialize();
    call NetworkHardwired.init();
    num = 0;

    return ok;
  }



  command result_t StdControl.start() {

    result_t ok;
    uint8 i;

    ok = call NetworkControl.start();

    call NetworkCommand.GetMoteID(&ThisNodeID);
    Packet = call NetworkPacket.AllocateBuffer(100);
    for (i=0; i<100; i++) {
        Packet[i] = i;
    }

    if (ThisNodeID == NODE1) {
        OtherNodeID = NODE2;
        master = true;
    } else {
        OtherNodeID = NODE1;
        master = false;
    }
    call NetworkHardwired.AddConnection(NODE1, NODE2);

    call NetworkHardwired.start();

    return ok;
  }



  command result_t StdControl.stop() {

    result_t ok;
    
    ok = call NetworkControl.stop();

    return ok;
  }



  event result_t NetworkPacket.Receive( uint32 Source,
                                      uint8  *Data,
                                      uint16 Length) {

#if TRANSFER_DATA
       num++;
       if (num < 100) {
          call Leds8.bitOff(4);
          call Leds8.bitOn(5);
          call Leds8.bitOff(6);
       } else if (num < 200) {
          call Leds8.bitOff(4);
          call Leds8.bitOff(5);
          call Leds8.bitOn(6);
       } else {
           num = 0;
       }
       call NetworkPacket.Send(OtherNodeID, Packet, 100);
#endif

    return SUCCESS;
  }

  event result_t NetworkPacket.SendDone(char *data) {
    return SUCCESS;
  }



/*
 * Start of NetworkCommand interface.
 */

  event result_t NetworkCommand.CommandResult( uint32 Command, uint32 value) {
    // do nothing
      switch(Command) {
      case COMMAND_NEW_NODE_CONNECTION:
          call Leds8.bitOff(4);
          call Leds8.bitOff(5);
          call Leds8.bitOn(6);
          
#if TRANSFER_DATA
          if (master) {
              call NetworkPacket.Send(OtherNodeID, Packet, 100);
          }
#endif
          break;

      case COMMAND_NODE_DISCONNECTION:
          call Leds8.bitOff(4);
          call Leds8.bitOn(5);
          call Leds8.bitOff(6);
          break;
      }

      

    return SUCCESS;
  }

/*
 * End of NetworkCommand interface.
 */
}  



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


#include "app.h"

module LedChainM {
  uses {
    interface StdControl as NetworkControl;
    interface NetworkCommand;
    interface NetworkPacket;
    interface Timer as LedTimer;
    interface Leds8;
#if HARDWIRED_NETWORK
    interface NetworkHardwired;
#endif
  }

  provides interface StdControl;
}

implementation {

#include "./motelib.h" // needed for TOSBuffer declaration
#define NULL_NODE  0xFFFF
#define IM_BLACK   0x00
#define IM_BLUE    0x10
#define IM_RED     0x20
#define IM_GREEN   0x40
#define IM_MAGENTA 0x30
#define IM_YELLOW  0x60
#define IM_CYAN    0x50
#define IM_WHITE   0x70

#define BASE_INTERVAL  100 // 100ms base timer
#define T_WAIT          20 // (x base) 2s wait time
#define T_LED            2 // (x base) 200ms led pulse length

#define MULTICOLOR FALSE

#define TOTAL_CONNECTIONS 64


    typedef struct tConnectionType {
        uint32 master;
        uint32 slave;
    } tConnectionType;

    tConnectionType Connections[TOTAL_CONNECTIONS];
    uint32 i, Previous, Next;
    uint32 ThisNodeID;
    uint32 LedColor;      // 2-bit encoding of the LED drivers; 0 is not used
    uint32 PulseDuration; // pulse length
    uint32 retry, packet, self, tw, tl;
    char   *buffer;
    
/*
 * Start of StdControl interface.
 */

#define LC_HEAD 0x85018

  command result_t StdControl.init() {

    call NetworkControl.init();
    call NetworkCommand.SetAppName("Led Chain");

#if HARDWIRED_NETWORK
    call NetworkHardwired.init();
    for (i = 0; i < TOTAL_CONNECTIONS; i++) {
        Connections[i].slave = 0;
        Connections[i].master = 0;
    }

#if 1
    /*
     * Simple line [*S-0-M-1-S-2-M-3-S]
     */

        Connections[0].master = 0x85071;
        Connections[0].slave = LC_HEAD;
        Connections[1].master = Connections[0].master;
        Connections[1].slave = 0x85104;
        Connections[2].master = 0x85105;
        Connections[2].slave = Connections[1].slave;
        Connections[3].master = Connections[2].master;
        Connections[3].slave = 0x85172;
#endif

#if 0
    /*
     *          *S   S   S   S
     *            \  |    \  |
     *             1 2     5 6
     *              \|      \|
     * 2D array [S-0-M-3-S-4-M]
     */
        Connections[0].slave = 0x85196;
        Connections[0].master = 0x85182;
        Connections[1].slave = LC_HEAD;
        Connections[1].master = Connections[0].master;
        Connections[2].slave = 0x85071;
        Connections[2].master = Connections[0].master;
        Connections[3].slave = 0x85174;
        Connections[3].master = Connections[0].master;
        Connections[4].slave = Connections[3].slave;
        Connections[4].master = 0x85172;
        Connections[5].slave = 0x85104;
        Connections[5].master = Connections[4].master;
        Connections[6].slave = 0x85105;
        Connections[6].master = Connections[4].master;
#endif

#endif

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call NetworkControl.start();
    call NetworkCommand.SetProperty(NETWORK_PROPERTY_APP_LED_CHAIN);
    call NetworkCommand.SetProperty(NETWORK_PROPERTY_ACTIVE_ROUTING);
    Previous = (uint32) NULL_NODE;
    Next = (uint32) NULL_NODE;
    call NetworkCommand.GetMoteID(&ThisNodeID);
    packet = 0;
    self = 1; // autonomous operation
    tw = 0;
    tl = 0;
    call LedTimer.start(TIMER_REPEAT, BASE_INTERVAL);

#if HARDWIRED_NETWORK
    for (i = 0; i < TOTAL_CONNECTIONS; i++) {
       call NetworkHardwired.AddConnection(Connections[i].master, Connections[i].slave);
    }
    call NetworkHardwired.start();
#endif

    LedColor = IM_GREEN;
    PulseDuration = (uint32) T_LED;
    if (ThisNodeID == LC_HEAD) {
        LedColor = IM_RED;

#if !HARDWIRED_NETWORK
        call NetworkCommand.SetProperty(NETWORK_PROPERTY_CLUSTER_HEAD);
#endif

    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call NetworkControl.stop();
    return SUCCESS;
  }

/*
 * End of StdControl interface.
 */

/*
 * Start of NetworkPacket interface.
 */

  event result_t NetworkPacket.SendDone(char *data) {
    call NetworkPacket.ReleaseBuffer(data);
    return SUCCESS;
  }

  void ProcessNewNodeFound(uint32 Node) {

    if (Node < ThisNodeID) {
      if ((Previous == (uint32) NULL_NODE) || (Previous < Node)) {
        Previous = Node;
      }
      self = 0; // stop autonomous operation
    } else if (ThisNodeID < Node) {
      if ((Next == (uint32) NULL_NODE) || (Node < Next)) {
        Next = Node;
      }
    }
    return;
  }

  event result_t NetworkPacket.Receive( uint32 Source,
                                        uint8  *Data,
                                        uint16 Length) {

    LedColor = ((uint32 *) Data)[0];
    PulseDuration = ((uint32 *) Data)[1];
    packet++;
    return SUCCESS;
  }

/*
 * End of NetworkPacket interface.
 */

/*
 * Start of NetworkCommand interface.
 */

  event result_t NetworkCommand.CommandResult(uint32 Command, uint32 value) {
      switch (Command) {
      case COMMAND_NEW_NODE_CONNECTION: // new node found
          if (call NetworkCommand.IsPropertySupported(value, NETWORK_PROPERTY_APP_LED_CHAIN)) {
              ProcessNewNodeFound(value);
          } else {
              call NetworkCommand.PermanentlyDisconnectNetworkNodes(value);
          }
          break;

      case COMMAND_NODE_DISCONNECTION:
          // reset colors
          LedColor = IM_YELLOW;
          PulseDuration = T_LED;
          if (ThisNodeID == LC_HEAD) {
              LedColor = IM_RED;
          }
          if (value == Previous) {  // This node has become a new head
              Previous = (uint32) NULL_NODE;
              self = 1;  // restart autonomous operation
          }
          if (value == Next) {
              Next = (uint32) NULL_NODE;
          }
          break;
    default:
    }
    return SUCCESS;
  }

/*
 * End of NetworkCommand interface.
 */

/*
 * Start of LedTimer interface.
 */

  event result_t LedTimer.fired() {

      tw++;
      if (((tw > T_WAIT) && (self == 1)) || (packet > 0)) {
          tl++;
          if (tl == 1) { // Led on
              if (Previous == (uint32) NULL_NODE) {
                  if (MULTICOLOR == TRUE) { // head node can change color
                      if (LedColor == IM_RED) {
                          LedColor = IM_MAGENTA;
                      } else if (LedColor == IM_MAGENTA) {
                          LedColor = IM_BLUE;
                      } else if (LedColor == IM_BLUE) {
                          LedColor = IM_CYAN;
                      } else if (LedColor == IM_CYAN) {
                          LedColor = IM_GREEN;
                      } else if (LedColor == IM_GREEN) {
                          LedColor = IM_YELLOW;
                      } else if (LedColor == IM_YELLOW) {
                          LedColor = IM_RED;
                      } else if (LedColor == IM_WHITE) {
                          LedColor = IM_BLACK;
                      } else if (LedColor == IM_BLACK) {
                          LedColor = IM_WHITE;
                      }
                  }
              }
              if (LedColor & 0x10) call Leds8.bitOn(4); else call Leds8.bitOff(4);
              if (LedColor & 0x20) call Leds8.bitOn(5); else call Leds8.bitOff(5);
              if (LedColor & 0x40) call Leds8.bitOn(6); else call Leds8.bitOff(6);
          } else if (tl > T_LED) { // Led off
              call Leds8.bitOff(4);
              call Leds8.bitOff(5);
              call Leds8.bitOff(6);
              if (Next != (uint32) NULL_NODE) { // we are not last in chain
                  buffer = call NetworkPacket.AllocateBuffer(8);
                  if (buffer != NULL) {
                      ((uint32 *)buffer)[0] = LedColor;
                      ((uint32 *)buffer)[1] = PulseDuration;
                      if (call NetworkPacket.Send(Next, buffer, 8) == FAIL ) {
                          call NetworkPacket.ReleaseBuffer(buffer);
                      }
                  }
              }
              tl = 0;
              tw = 0;
              if (packet > 0) {
                  packet = 0;
              }
          }
      }
      return SUCCESS;
  }

/*
 * End of LedTimer interface.
 */

}

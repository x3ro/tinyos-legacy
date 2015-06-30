/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors:  Andrew Christian
 *           20 January 2005
 */

includes Message;
includes UIP;

module EchoServerM {
  provides interface StdControl;

  uses {
    interface StdControl as IPLayerStdControl;
    interface UIP;
    interface Client;
    interface UDPClient;
 
    interface Leds;
  }
}

implementation {
  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call Leds.init();
    return call IPLayerStdControl.init();
  }

  command result_t StdControl.start() {
    call IPLayerStdControl.start();
    call UDPClient.listen(7);           // Regular ECHO port
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return call IPLayerStdControl.stop();
  }

  /***************** A basic echoing UDP server ******************************/
  
  uint8_t g_data[128];

  event void UDPClient.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len )
  {
    if (len > 128)
      len = 128;

    call Leds.yellowOn();

    memcpy(g_data, buf, len);
    call UDPClient.sendTo( addr, g_data, len );
  }

  event void UDPClient.sendDone()
  {
    call Leds.yellowOff();
  }

  event void Client.connected( bool isConnected ) 
  {
    if (isConnected)
      call Leds.greenOn();
    else
      call Leds.greenOff();
  }
}

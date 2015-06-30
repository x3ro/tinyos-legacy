/*
 * Copyright (c) 2005 Hewlett-Packard Company
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
 *
 * Test communication of SIPLite over 'SIPLite' style sockets
 *
 * Author:   Andrew Christian <andrew.christian@hp.com>
 *           March 2005
 */

module TestSIPLiteM {
  provides {
    interface StdControl;
  }

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as SIPLiteStdControl;
    interface UIP;
    interface Client;
    interface Leds;

    interface SIPLiteServer;
    interface Timer;
  }
}

implementation {
  enum {
    MEDIA_TYPE_FULL = 1,
    MEDIA_TYPE_PART = 2
  };

  int g_current;
  int g_timer_count;

  char outbuf[100];
  const char foo[] = "This is some sample data to send.  This is just random data to fill out a string.";
  

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    g_current = 0;
    g_timer_count = 0;

    call Leds.init();
    call IPStdControl.init();
    call SIPLiteStdControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call SIPLiteStdControl.start();
    call Timer.start( TIMER_REPEAT, 205 );  // 5Hz
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    call SIPLiteStdControl.stop();
    return call IPStdControl.stop();
  }

  /*****************************************
   *  SIPLiteServer interface
   *****************************************/

  event void SIPLiteServer.addStream( int mediaType )
  {
    switch (mediaType) {
    case 1:
      call Leds.greenOn();
      break;
    case 2:
      call Leds.yellowOn();
      break;
    default:
      call Leds.redOn();
      break;
    }
  }

  event void SIPLiteServer.dropStream( int mediaType )
  {
    switch (mediaType) {
    case 1:
      call Leds.greenOff();
      break;
    case 2:
      call Leds.yellowOff();
      break;
    default:
      call Leds.redOff();
      break;
    }
  }

  event void SIPLiteServer.sendDone()
  {
    g_current++;
    if ( g_current < 3 && (g_timer_count % 4)== 0 )
      call SIPLiteServer.send(g_current, outbuf, 80);
    else
      g_current = 0;
  }

  /*****************************************
   *  Stream timer fires frequently to simulate data
   *****************************************/

  event result_t Timer.fired()
  {
    g_timer_count++;
    if ( g_current == 0 ) {
      g_current = 1;

      *((int *)outbuf) = g_timer_count;
      strncpy( outbuf + 2, foo, 98 );
      call SIPLiteServer.send(g_current, outbuf, 80);
    }
    return SUCCESS;
  }

  /*****************************************
   *  Client interface
   *****************************************/

  event void Client.connected( bool isConnected )
  {
  }
}

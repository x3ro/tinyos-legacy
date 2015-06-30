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

includes NVTParse;
includes msp430baudrates;

module AccelAppM {
  provides {
    interface StdControl;
  }

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as SIPLiteStdControl;

    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface UIP;
    interface Client;
    interface Leds;

    interface SIPLiteServer;
    interface Accel;
    interface StdControl as AccelStdControl;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  enum {
    MEDIA_TYPE_OFF        = 0,
    MEDIA_TYPE_FULL       = 1,
  };

  int              g_current_media_type;
  struct AccelData g_data;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    g_current_media_type = 0;

    call Leds.init();

    call PVStdControl.init();
    call IPStdControl.init();

    call AccelStdControl.init();
    call TelnetStdControl.init();
    call SIPLiteStdControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();
    call SIPLiteStdControl.start();
    call AccelStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call AccelStdControl.stop();
    call SIPLiteStdControl.stop();
    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  /*****************************************
   *  Client interface
   *****************************************/

  event void Client.connected( bool isConnected ) 
  {
    if (isConnected)
      call Leds.greenOn();
    else
      call Leds.greenOff();
  }

  /*****************************************
   *  SIPLiteServer interface
   *****************************************/

  event void SIPLiteServer.addStream( int mediaType )
  {
  }

  event void SIPLiteServer.dropStream( int mediaType )
  {
  }

  void sendNextMediaType()
  {
    g_current_media_type++;
    switch (g_current_media_type) {
    case MEDIA_TYPE_FULL:
      call SIPLiteServer.send(g_current_media_type, (const char *) &g_data, sizeof(g_data));
      break;
    default:
      g_current_media_type = MEDIA_TYPE_OFF;
      return;
    }
  }

  event void SIPLiteServer.sendDone()
  {
    sendNextMediaType();
  }

  /*****************************************
   *  Accel interface
   *****************************************/

  event void Accel.data_received()
  {
    if ( g_current_media_type == MEDIA_TYPE_OFF) {
      const struct AccelData *data = call Accel.get();
      memcpy( &g_data, data, sizeof(g_data));
      call Accel.release();

      sendNextMediaType();
    }
  }
}

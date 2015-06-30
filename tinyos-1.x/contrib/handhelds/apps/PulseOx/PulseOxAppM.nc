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

#ifndef LITE
includes web_site;
#endif

module PulseOxAppM {
  provides {
    interface StdControl;
    interface ServiceView;
  }

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as SIPLiteStdControl;
#ifndef LITE
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;
    interface StdControl as HTTPStdControl;
    interface StdControl as SVStdControl;
#endif

    interface UIP;
    interface Client;
    interface Leds;
#ifndef LITE
    interface HTTPServer;
#endif
    interface SIPLiteServer;

    interface PulseOx;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  enum {
    MEDIA_TYPE_OFF        = 0,
    MEDIA_TYPE_FULL       = 1,
    MEDIA_TYPE_PULSE_ONLY = 2,
  };

  int             g_current_media_type;
  struct XpodData g_pox;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    g_current_media_type = 0;

    call Leds.init();

#ifndef LITE
    call PVStdControl.init();
    call SVStdControl.init();
#endif
    call IPStdControl.init();

    call PulseOx.init();
#ifndef LITE
    call TelnetStdControl.init();
    call HTTPStdControl.init();
#endif
    call SIPLiteStdControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
#ifndef LITE
    call SVStdControl.start();
    call TelnetStdControl.start();
    call HTTPStdControl.start();
#endif
    call SIPLiteStdControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call SIPLiteStdControl.stop();
#ifndef LITE
    call SVStdControl.stop();
    call HTTPStdControl.stop();
    call TelnetStdControl.stop();
#endif
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
      call SIPLiteServer.send(g_current_media_type, (const char *) &g_pox, sizeof(g_pox));
      break;
    case MEDIA_TYPE_PULSE_ONLY:
      call SIPLiteServer.send(g_current_media_type, (const char *) &g_pox, sizeof(struct XpodDataShort));
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
   *  PulseOx interface
   *****************************************/

  event void PulseOx.data_received()
  {
    if ( g_current_media_type == MEDIA_TYPE_OFF) {
      const struct XpodData *xd = call PulseOx.get();
      memcpy( &g_pox, xd, sizeof(g_pox));
      call PulseOx.release();

      // Turn on the yellow light when we have a valid pulse
      if ( xd->heart_rate_display < 511 )
	call Leds.yellowOn();
      else
	call Leds.yellowOff();

      sendNextMediaType();
    }
  }

  /*****************************************
   *  Web Server interface
   *****************************************/

#ifndef LITE 
  event struct TSPStack * HTTPServer.eval_function( struct TSPStack *sptr, uint8_t cmd, 
						    char *tmpbuf, int tmplen )
  {
    switch (cmd) {
    case FUNCTION_POX_LOCK:
      call PulseOx.get();
      break;

    case FUNCTION_POX_UNLOCK:
      call PulseOx.release();
      break;

    case FUNCTION_POX_PERFUSION:
      --sptr;
      switch ( (g_pox.status_pleth[sptr->value].status & 0x06) >> 1 ) {
      case 0:
	strncpy( tmpbuf, "#FFFFFF", tmplen );
	break;
      case 1:
	strncpy( tmpbuf, "#88FF88", tmplen );  // Green
	break;
      case 2:
	strncpy( tmpbuf, "#FF4444", tmplen ); // Red
	break;
      case 3:
	strncpy( tmpbuf, "#FFFF00", tmplen ); // Yellow
	break;
      }
      sptr->value = (int) tmpbuf;
      sptr->type = TSP_TYPE_STRING;
      return sptr + 1;

    case FUNCTION_POX_STATUS:
      --sptr;
      sptr->value = (int) g_pox.status_pleth[ sptr->value ].status;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_PLETH:
      --sptr;
      sptr->value = (int) g_pox.status_pleth[ sptr->value ].pleth;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_NUMBER:
      snprintf(tmpbuf, tmplen, "%lu", g_pox.number);
      sptr->value = (int) tmpbuf;
      sptr->type = TSP_TYPE_STRING;
      return sptr + 1;

    case FUNCTION_POX_HEARTRATE:
      sptr->value = g_pox.heart_rate;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_EXT_HEARTRATE:
      sptr->value = g_pox.extended_heart_rate;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_HEARTRATE_DISPLAY:
      sptr->value = g_pox.heart_rate_display;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_EXT_HEARTRATE_DISPLAY:
      sptr->value = g_pox.extended_heart_rate_display;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_SPO2:
      sptr->value = g_pox.spo2;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_SPO2_DISPLAY:
      sptr->value = g_pox.spo2_display;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_SPO2_SLEW:
      sptr->value = g_pox.spo2_slew;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_SPO2_BEAT_TO_BEAT:
      sptr->value = g_pox.spo2_beat_to_beat;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_POX_REVISION:
      sptr->value = g_pox.firmware_rev;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;
    }

    // We can reach this from a function above failing.  Push
    // an 'integer = 0' onto the stack and return it.
    sptr->value = 0;
    sptr->type = TSP_TYPE_INTEGER;
    return sptr + 1;
  }
#endif

#if 1
  /*****************************************
   *  ServiceView interface
   *****************************************/

  const struct Service s_POXServices[] = {
    { "pulseox", "siplight", "online", 5062 },
    { NULL, 0, NULL }
  };

  struct ServiceList g_POXServiceList = { "pox", &s_POXServices[0] };

  command result_t ServiceView.init()
  {
    signal ServiceView.add( &g_POXServiceList );
    return SUCCESS;
  }
#endif
}

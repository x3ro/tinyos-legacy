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
 */

/*
 * Copyright (c) 2004 Hewlett-Packard Company
 * All rights reserved
 *
 * Authors:  Andrew Christian
 *           20 January 2005
 */

includes EKG;

includes msp430baudrates;
includes web_site;

module EKGAppM {
  provides {
    interface StdControl;
    interface ParamView;
    interface ServiceView;
  }

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;
    interface StdControl as SVStdControl;
    interface StdControl as HTTPStdControl;
    interface StdControl as SIPLiteStdControl;

    interface UIP;
    interface Client;
    interface Leds;
    interface NTPClient;
    interface HTTPServer;
    interface SIPLiteServer;
    interface Time;

    interface EKG;
    interface PatientView;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  enum {
    MEDIA_TYPE_OFF        = 0,
    MEDIA_TYPE_FULL       = 1,
    MEDIA_TYPE_PULSE_ONLY = 2,
  };

  uint16_t g_current_media_type;
  struct EKGData g_ekg;
  uint8_t g_uid[6];
  struct tm g_tm;
  time_t g_timer;
  
  char g_timestring[128];
  int16_t g_timestamp_received;
  int16_t g_datasets_received;
  int16_t g_bytes_received;
  int16_t g_bytes_sent;
  int16_t g_datasets_sent;
  int16_t g_datasets_done;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    g_current_media_type = 0;

    call Leds.init();

    call PVStdControl.init();
    call SVStdControl.init();
    call TelnetStdControl.init();
    call IPStdControl.init();

    call EKG.init();
    call HTTPStdControl.init();
    call SIPLiteStdControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call UIP.init(IP);                // IP is a #define variable from the Makefile
    call SVStdControl.start();
    call TelnetStdControl.start();
    call HTTPStdControl.start();
    call SIPLiteStdControl.start();
    call Time.time(&g_timer);
    //call Time.localtime(&g_timer, &g_tm);
    //call Time.asctime(&tm, g_timestring, sizeof(g_timestring));
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call SIPLiteStdControl.stop();
    call HTTPStdControl.stop();
    call TelnetStdControl.stop();
    call SVStdControl.stop();
    return call IPStdControl.stop();
  }

  /*****************************************
   *  Client interface
   *****************************************/

  event void Client.connected( bool isConnected ) 
  {
    if (isConnected) {
      call Leds.greenOn();
      call NTPClient.setup(NTP_IP, 123, 123, 6);
    }
    else
      call Leds.greenOff();
  }


  event void NTPClient.timestampReceived( uint32_t *seconds, uint32_t *fraction )
  {
    g_timestamp_received++;
    g_timer = *seconds;
  }


  /*****************************************
   *  SIPLiteServer interface
   *****************************************/

  event void SIPLiteServer.addStream( int mediaType )
  {
    g_current_media_type = mediaType;
    call EKG.start(g_current_media_type);
  }

  event void SIPLiteServer.dropStream( int mediaType )
  {
    call EKG.stop();
  }

  void sendNextMediaType()
  {
    switch (g_current_media_type) {
    case 1:
    case 2:
      g_datasets_sent++;
      call SIPLiteServer.send(g_current_media_type, (const char *) &g_ekg, sizeof(g_ekg));
      break;
    default:
      g_current_media_type = MEDIA_TYPE_OFF;
      return;
    }
  }

  event void SIPLiteServer.sendDone()
  {
    g_datasets_done++;
    //sendNextMediaType();    
  }

  /*****************************************
   *  EKG interface
   *****************************************/

  event void EKG.data_received()
  {
    g_datasets_received++;
    if ( g_current_media_type != MEDIA_TYPE_OFF) {
      const struct EKGData *xd = call EKG.get();
      memcpy( &g_ekg, xd, sizeof(g_ekg));
      g_bytes_received += sizeof(g_ekg);
      call EKG.release();

      sendNextMediaType();
    }
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_EKGApp[] = {
    { "datasets", PARAM_TYPE_UINT32, &g_datasets_received },
    { "sent", PARAM_TYPE_UINT32, &g_datasets_sent },
    { "done", PARAM_TYPE_UINT32, &g_datasets_done },
    { "bytesin",    PARAM_TYPE_UINT32, &g_bytes_received },
    { "bytesout",    PARAM_TYPE_UINT32, &g_bytes_sent },
    { "media_type",    PARAM_TYPE_UINT16, &g_current_media_type },
    { "timestamps",    PARAM_TYPE_UINT16, &g_timestamp_received },
    { "timer",    PARAM_TYPE_UINT32, &g_timer },
    { "year",    PARAM_TYPE_UINT16, &g_tm.tm_year },
    { "mon",    PARAM_TYPE_UINT16, &g_tm.tm_mon },
    { "day",    PARAM_TYPE_UINT16, &g_tm.tm_mday },
    { "hour",    PARAM_TYPE_UINT16, &g_tm.tm_hour },
    { "min",    PARAM_TYPE_UINT16, &g_tm.tm_min },
    /* { "timestring",    PARAM_TYPE_STRING, &g_timestring[0] }, */
    { NULL, 0, NULL }
  };

  struct ParamList g_EKGAppList = { "ekgapp", &s_EKGApp[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_EKGAppList );
    return SUCCESS;
  }

  /*****************************************
   *  Web Server interface
   *****************************************/

  event struct TSPStack * HTTPServer.eval_function( struct TSPStack *sptr, uint8_t cmd, 
						    char *tmpbuf, int tmplen )
  {
    switch (cmd) {
    case FUNCTION_EKG_LOCK:
      call EKG.get();
      break;

    case FUNCTION_EKG_UNLOCK:
      call EKG.release();
      break;

    case FUNCTION_EKG_STATUS:
      --sptr;
      sptr->value = (int) 22;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_EKG_SAMPLES_PER_PACKET:
      sptr->value = (int) 64;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_EKG_NUMBER:
      snprintf(tmpbuf, tmplen, "%lu", g_ekg.number);
      sptr->value = (int) tmpbuf;
      sptr->type = TSP_TYPE_STRING;
      return sptr + 1;

    case FUNCTION_EKG_SAMPLE:
      --sptr;
      sptr->value = (int) g_ekg.samples[ sptr->value ];
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    }

    // We can reach this from a function above failing.  Push
    // an 'integer = 0' onto the stack and return it.
    sptr->value = 0;
    sptr->type = TSP_TYPE_INTEGER;
    return sptr + 1;
  }

  /*****************************************
   *  PatientView interface
   *****************************************/

  event void PatientView.changed() {
    const struct Patient *patientInfo = call PatientView.getPatientInfo();
    // copy bits where we need them
  }

  /*****************************************
   *  ServiceView interface
   *****************************************/

  const struct Service s_EKGServices[] = {
    { "ekg", "siplight", "online", 5062 },
    { NULL, 0, NULL }
  };

  struct ServiceList g_EKGServiceList = { "ekg", &s_EKGServices[0] };

  command result_t ServiceView.init()
  {
    signal ServiceView.add( &g_EKGServiceList );
    return SUCCESS;
  }

  event void Time.tick() { }

}

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
 * Authors:  Andrew Christian
 *           Jamey Hicks
 *           March 2005
 */

includes msp430baudrates;

module TestTimeM {
  provides {
    interface StdControl;
    interface ParamView;
  }

  uses {
    interface StdControl as IPStdControl;
    interface StdControl as TelnetStdControl;
    interface StdControl as PVStdControl;

    interface UIP;
    interface Client;
    interface Leds;
    interface NTPClient;
    interface Time;
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
  time_t g_timer = 0x4239cbc2L;
  
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
    call TelnetStdControl.init();
    call IPStdControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call IPStdControl.start();
    call TelnetStdControl.start();
    call Time.time(&g_timer);
    g_timer = 3320074405ul;
    call Time.localtime(&g_timer, &g_tm);
    call Time.asctime(&g_tm, g_timestring, sizeof(g_timestring));
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call TelnetStdControl.stop();
    return call IPStdControl.stop();
  }

  event void Time.tick() { call Leds.redToggle(); }

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


  event void NTPClient.timestampReceived( uint32_t *seconds, uint32_t *fraction )
  {
    g_timestamp_received++;
    g_timer = *seconds;
    call Time.localtime(&g_timer, &g_tm);
    call Time.asctime(&g_tm, g_timestring, sizeof(g_timestring));
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_TestTime[] = {
    { "timestamps",    PARAM_TYPE_UINT16, &g_timestamp_received },
    { "timer",    PARAM_TYPE_UINT32, &g_timer },
    { "year",    PARAM_TYPE_UINT16, &g_tm.tm_year },
    { "mon",    PARAM_TYPE_UINT16, &g_tm.tm_mon },
    { "day",    PARAM_TYPE_UINT16, &g_tm.tm_mday },
    { "hour",    PARAM_TYPE_UINT16, &g_tm.tm_hour },
    { "min",    PARAM_TYPE_UINT16, &g_tm.tm_min },
    { "timestring",    PARAM_TYPE_STRING, &g_timestring[0] },
    { NULL, 0, NULL }
  };

  struct ParamList g_TestTimeList = { "test", &s_TestTime[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_TestTimeList );
    return SUCCESS;
  }

}

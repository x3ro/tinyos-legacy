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
 *  A query interface for services
 * 
 *  Jamey Hicks
 *  March 2005
 */

includes ServiceView;

module ServiceQueryM {
  provides {
    interface ServiceQuery;
    interface ParamView;
  } 
  uses {
    interface UDPClient;
    interface Client;
    interface Leds;
    interface Timer;
  }
}
implementation {

  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));
  int g_errors = 0;
  int g_sent = 0;
  int g_timeout = 0;
  int g_received = 0;
  int g_connected = 0;

  struct ServiceQuery g_service_info;

  enum {
    OUTBUF_LEN = 80
  };

  char g_query_out[OUTBUF_LEN];
  int   g_query_out_len;
  int g_retries;
  struct udp_address g_servicedb_address = { { 255, 255, 255, 255 }, 4111 };

  char g_sname[32];
  char g_stype[32];
  char g_deviceid[32];
  char g_patientid[32];
  int8_t g_expires;

  static uint8_t g_device_id[24];
  enum {
    STATUS_IDLE = 0,
    STATUS_SENDING = 1,
    STATUS_QUERY_SERVICE = 2
  };
  static int16_t g_flags;

  void query_service();

  /*****************************************
   *  ServiceQuery
   *****************************************/

  event void Client.connected(bool isConnected) {
    if (isConnected) {

      call UDPClient.listen(4113);
      g_connected  = 1;
    } else {
      g_connected = 0;
    }
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_SQ[] = {
    { "sent", PARAM_TYPE_UINT16, &g_sent },
    { "timeout", PARAM_TYPE_UINT16, &g_timeout },
    { "received", PARAM_TYPE_UINT16, &g_received },
    { "errors", PARAM_TYPE_UINT16, &g_errors },
    { "flags", PARAM_TYPE_UINT16, &g_flags },
    { "q_sname", PARAM_TYPE_STRING, &g_sname },
    { "q_stype", PARAM_TYPE_STRING, &g_stype },
    { "q_patientid", PARAM_TYPE_STRING, &g_patientid },
    { "q_deviceid", PARAM_TYPE_STRING, &g_deviceid },
    { "query", PARAM_TYPE_STRING, &g_query_out },
    { "querylen", PARAM_TYPE_UINT16, &g_query_out_len },
    { "sname", PARAM_TYPE_STRING, &g_service_info.sname[0] },
    { "stype", PARAM_TYPE_STRING, &g_service_info.stype[0] },
    { "status", PARAM_TYPE_STRING, &g_service_info.status[0] },
    { "ipaddr", PARAM_TYPE_STRING, &g_service_info.ipaddr[0] },
    { "port", PARAM_TYPE_UINT16, &g_service_info.port },
    { "deviceid", PARAM_TYPE_STRING, &g_service_info.deviceid[0] },
    { NULL, 0, NULL }
  };

  struct ParamList g_SQList = { "sq", &s_SQ[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_SQList );
    return SUCCESS;
  }


  /*
   * UDPClient
   */	

  void query_service() {
    g_flags |= STATUS_QUERY_SERVICE;
    if (!g_connected)
      return;
    if ((g_flags & STATUS_SENDING) == 0) {
      char *out = g_query_out;
      char *outmax = out + OUTBUF_LEN;

      call Leds.yellowOn();
      out += snprintf(out, outmax - out, "QUERY service\r\n");
      out += snprintf(out, outmax - out, "SVN: %s\r\n", g_sname);
      out += snprintf(out, outmax - out, "SVT: %s\r\n", g_stype);
      //out += snprintf(out, outmax - out, "PID: %s\r\n", g_patientid);
      //out += snprintf(out, outmax - out, "DID: %s\r\n", g_deviceid);

      g_query_out_len = out - g_query_out;

      if (call UDPClient.sendTo( &g_servicedb_address, g_query_out, g_query_out_len ) == SUCCESS) {
	g_sent++;
	g_flags |=  STATUS_SENDING;
      } else {
	g_errors++;
      }
    }
  }

  event void UDPClient.sendDone() { 
    g_flags &= ~STATUS_SENDING;
  }

  /* failed to send or time to resend */
  event result_t Timer.fired() {
    g_timeout++;
    if (g_retries++ < 3) {
      call Timer.start(TIMER_ONE_SHOT, 5*1024);
      query_service();
    }
    return SUCCESS;
  }

  event void UDPClient.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len ) {
    int got_answers = 5;
    char *line = buf;
    char *bufmax = buf+len;
    char *next_line = mark_line(buf, bufmax);
    char *token2 = NULL;
    char *token = next_token(line, &token2, ' ');
    int i = 0;

    g_received++;

    if ((g_flags & STATUS_QUERY_SERVICE) == 0)
      return;

    call Leds.greenOn();

    if (strcmp(token, "200") != 0)
      return;

    memset(&g_service_info, 0, sizeof(g_service_info));
    while (got_answers && next_line && (i++ < 10)) {
      line = next_line;
      next_line = mark_line(line, bufmax);
      token = next_token(line, &token2, ':');

      if (strcmp(token, "SVN") == 0) {
	strncpy(g_service_info.sname, skip_white(token2), sizeof(g_service_info.sname));
	got_answers--;
      } else if (strcmp(token, "SVT") == 0) {
	strncpy(g_service_info.stype, skip_white(token2), sizeof(g_service_info.stype));
	got_answers--;
      } else if (strcmp(token, "IP") == 0) {
	strncpy(g_service_info.ipaddr, skip_white(token2), sizeof(g_service_info.ipaddr));
	got_answers--;
      } else if (strcmp(token, "Port") == 0) {
	g_service_info.port = atou(skip_white(token2));
	got_answers--;
      } else if (strcmp(token, "Status") == 0) {
	strncpy(g_service_info.status, skip_white(token2), sizeof(g_service_info.status));
	got_answers--;
      }
#if 0
      else if (strcmp(token, "DID") == 0) {
	strncpy(g_service_info.deviceid, skip_white(token2), sizeof(g_service_info.deviceid));
	got_answers--;
      }  
#endif
    }
    if (!got_answers) {
      g_flags &= ~STATUS_QUERY_SERVICE;
      signal ServiceQuery.serviceFound(&g_service_info);
    }
  }

  /*****************************************
   *  ServiceQuery interface
   *****************************************/

  command result_t ServiceQuery.startQuery(const char *sname, const char *stype, const char *patientid, const char *deviceid, int expires)
  {
    if (sname)
      strncpy(g_sname, sname, sizeof(g_sname));
    else
      strncpy(g_sname, "*", sizeof(g_sname));
    if (stype)
      strncpy(g_stype, stype, sizeof(g_stype));
    else
      strncpy(g_stype, "*", sizeof(g_stype));
    if (patientid)
      strncpy(g_patientid, patientid, sizeof(g_patientid));
    else
      strncpy(g_patientid, "*", sizeof(g_patientid));
    if (deviceid)
      strncpy(g_deviceid, deviceid, sizeof(g_deviceid));
    else
      strncpy(g_deviceid, "*", sizeof(g_deviceid));
    g_expires = expires;
    g_retries = 0;
    query_service();
    call Timer.start(TIMER_ONE_SHOT, 5*1024);
    return SUCCESS;
  }

  command result_t ServiceQuery.stopQuery()
  {
    g_flags &= ~STATUS_QUERY_SERVICE;
    call Timer.stop();
  }

}

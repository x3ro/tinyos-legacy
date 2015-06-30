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
 *  A generic interface for service views that can handle Telnet commands
 * 
 *  Jamey Hicks
 *  Andrew Christian
 *  March 2005
 */

includes NVTParse;

#ifndef DTYPE
#error dtype unspecified
#endif

module PatientViewM {
  provides {
    interface PatientView;
    interface ParamView;
  }
  uses {
    interface UDPClient;
    interface Client;
    interface UIP;
    interface Timer;
    interface Leds;
  }
}
implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));
  struct ServiceList *g_servicelist = NULL;
  int g_errors = 0;
  int g_sent = 0;
  int g_timeout = 0;
  int g_received = 0;

  struct ServiceList *g_register_service = NULL; /* next one to advertise to registrar */

  enum {
    OUTBUF_LEN = 80
  };

  char g_registrar_out[OUTBUF_LEN];
  int   g_registrar_out_len;
  struct Patient g_patient_info;

  static uint8_t g_device_id[24];
  enum {
    STATUS_IDLE = 0,
    STATUS_SENDING = 1,
    STATUS_PATIENT_CHANGED = 8,
    STATUS_QUERY_PATIENTID = 16
  };
  static int16_t g_flags = 0;


  /*****************************************
   *  PatientView
   *****************************************/

  command const struct Patient *PatientView.getPatientInfo()
  {
    return (const struct Patient *)&g_patient_info;
  }

  command result_t PatientView.setPatientID(const char *patient_id, int len) 
  {
    if (len > sizeof(g_patient_info.id))
      len = sizeof(g_patient_info.id);
    memcpy(g_patient_info.id, patient_id, len);
    g_flags |= STATUS_PATIENT_CHANGED;
    signal PatientView.changed();
    return SUCCESS;
  }

  command result_t PatientView.setPatientName(const char *patient_name, int len) 
  {
    if (len > sizeof(g_patient_info.name))
      len = sizeof(g_patient_info.name);
    memcpy(g_patient_info.name, patient_name, len);
    g_flags |= STATUS_PATIENT_CHANGED;
    signal PatientView.changed();
    return SUCCESS;
  }

  default event void PatientView.changed() { }

  void query_patientid();

  event void Client.connected(bool isConnected) {
    if (isConnected) {
      uint8_t buf[8];
      int o = 0;
      int i;

      call Client.get_mac_address(buf);
      for (i = 0; i < 8; i++) {
	if (0 && i > 0)
	  g_device_id[o++] = ':';
	o += snprintf(g_device_id + o, sizeof(g_device_id) - o, "%02x", buf[i]);
      }
      call UDPClient.listen(4112);
      g_flags |= (STATUS_QUERY_PATIENTID);
      query_patientid();
    }
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_PV[] = {
    { "sent", PARAM_TYPE_UINT16, &g_sent },
    { "timeout", PARAM_TYPE_UINT16, &g_timeout },
    { "received", PARAM_TYPE_UINT16, &g_received },
    { "errors", PARAM_TYPE_UINT16, &g_errors },
    { "flags", PARAM_TYPE_UINT16, &g_flags },
    { "outlen", PARAM_TYPE_UINT16, &g_registrar_out_len },
    { "patientid", PARAM_TYPE_STRING, &g_patient_info.id[0] },
    { "name", PARAM_TYPE_STRING, &g_patient_info.name[0] },
    { NULL, 0, NULL }
  };

  struct ParamList g_PVList = { "pv", &s_PV[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_PVList );
    return SUCCESS;
  }


  /*
   * UDPClient
   */	

  void query_patientid() 
  {
    struct udp_address addr;

    g_flags |= STATUS_QUERY_PATIENTID;

    if (!call Client.is_connected())
      return;

    if ((g_flags & STATUS_SENDING) == 0) {
      char *out = g_registrar_out;
      char *outmax = out + OUTBUF_LEN;

      out += snprintf(out, outmax - out, "QUERY patient\r\n");
      out += snprintf(out, outmax - out, "DID: %s\r\n", g_device_id);
      out += snprintf(out, outmax - out, "DTYPE: %s\r\n", DTYPE);

      g_registrar_out_len = out - g_registrar_out;

      memcpy(addr.ip, infomem->registrar_ip, 4 );
      addr.port = infomem->registrar_port;

      call Timer.start(TIMER_ONE_SHOT, 5*1024);

      if (call UDPClient.sendTo( &addr, g_registrar_out, out - g_registrar_out ) == SUCCESS) {
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
    call Timer.start(TIMER_ONE_SHOT, 5*1024);
    query_patientid();
    return SUCCESS;
  }

  event void UDPClient.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len ) {
    int got_answers = 2;
    char *line = buf;
    char *bufmax = buf+len;
    char *next_line = mark_line(buf, bufmax);
    char *token2 = NULL;
    char *token = next_token(line, &token2, ' ');
    int i = 0;

    call Timer.start(TIMER_ONE_SHOT, 60*1024L);
    g_received++;

    if (strcmp(token, "200") != 0)
      return;

    while (got_answers && next_line && (i++ < 10)) {
      line = next_line;
      next_line = mark_line(line, bufmax);
      token = next_token(line, &token2, ':');

      if (strcmp(token, "PID") == 0) {
	strncpy(g_patient_info.id, skip_white(token2), sizeof(g_patient_info.id));
	got_answers--;
      } else if (strcmp(token, "Name") == 0) {
	strncpy(g_patient_info.name, skip_white(token2), sizeof(g_patient_info.name));
	got_answers--;
      }
    }
    if (!got_answers) {
      g_flags &= ~STATUS_QUERY_PATIENTID;
      signal PatientView.changed();
    }
  }
}

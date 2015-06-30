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
 *
 *  A generic interface for service views that can handle Telnet commands
 * 
 *  Jamey Hicks
 *  Andrew Christian
 *  March 2005
 */

includes NVTParse;

#ifndef REGISTRAR_IP
#error registrar_ip unspecified
#define REGISTRAR_IP 255, 255, 255, 255
#endif
#ifndef DTYPE
#error dtype unspecified
#endif

module ServiceViewM {
  provides {
    interface DeviceView;
    interface ParamView;
    interface StdControl;
  }
  uses {
#ifndef LITE
    interface Telnet as TelnetShow;
#endif
    interface UDPClient;
    interface ServiceView;
    interface Client;
    interface UIP;
    interface Timer;
    interface Leds;
  }
}
implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));
  struct ServiceList *g_servicelist;
  int g_service_count;
  int g_errors;
  int g_sent;
  int g_done;
  int g_timeout;
  int g_received;
  int g_connected;
  struct ServiceList *g_register_service; /* next one to advertise to registrar */

  enum {
    OUTBUF_LEN = 80
  };

  char g_registrar_out[OUTBUF_LEN];
  int   g_registrar_out_len;
  struct udp_address g_registrar_address = { { REGISTRAR_IP }, 4111 };

  static uint8_t g_device_id[24];
  static uint8_t g_ipaddr[16];
#ifdef DTYPE
  static uint8_t g_dtype[16] = DTYPE;
#else
  static uint8_t g_dtype[16];
#endif
  enum {
    STATUS_IDLE = 0,
    STATUS_SENDING = 1,
    STATUS_DEVICE_CHANGED = 2,
    STATUS_SERVICE_CHANGED = 4,
  };
  static int16_t g_flags = 0;
#ifndef LITE
  void register_device();
#endif

   /*****************************************
    *  StdControl interface
    *****************************************/

  command result_t StdControl.init() {
    call UDPClient.listen(4111);
    return call ServiceView.init();
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

 /*****************************************
   *  DeviceView
   *****************************************/

  command result_t DeviceView.init() {
    g_flags = STATUS_IDLE;
  }


  command result_t DeviceView.setDeviceid(const uint8_t *device_id, int len) {
#ifndef LITE
    if (len > sizeof(g_device_id))
      len = sizeof(g_device_id);
    memcpy(g_device_id, device_id, len);
    g_flags |= STATUS_DEVICE_CHANGED;
    register_device();
#endif
    return SUCCESS;
  }
  default event void DeviceView.changed() {
  
  }

  /*****************************************
   *  ServiceView
   *****************************************/

  void register_service();
  default command result_t ServiceView.init() { return SUCCESS; }

  event void ServiceView.add( struct ServiceList *plist )
  {
    plist->next = g_servicelist;
    g_servicelist = plist;
    g_register_service = g_servicelist;
    g_service_count++;
    register_service();
  }

  event void ServiceView.changed( struct ServiceList *plist )
  {
    g_register_service = g_servicelist;
    register_service();
  }

  event void ServiceView.remove( struct ServiceList *entry )
  {
    struct ServiceList *slist = g_servicelist;
    g_service_count--;
    if (slist == entry) {
      g_servicelist = entry->next;
    } else {
      struct ServiceList *prev = slist;
      slist = slist->next;
      while (slist && slist != entry) {
	prev = slist;
	slist = slist->next;
      }
      if (prev && slist && slist == entry) {
	prev->next = slist->next;
      }
    }
    g_register_service = g_servicelist;
    register_service();
  }

  event void Client.connected(bool isConnected) {
    if (isConnected) {
      uint8_t buf[8];
      struct ip_address ipaddr;
      int o = 0;
      int i;

      call Client.get_mac_address(buf);
      for (i = 0; i < 8; i++) {
	if (0 && i > 0)
	  g_device_id[o++] = ':';
	o += snprintf(g_device_id + o, sizeof(g_device_id) - o, "%02x", buf[i]);
      }
      call UIP.getAddress(&ipaddr);
      o = 0;
      for (i = 0; i < 4; i++) {
	if (i > 0)
	  g_ipaddr[o++] = '.';
	o += snprintf(g_ipaddr + o, sizeof(g_ipaddr) - o, "%d", ipaddr.addr[i]);
      }

      call UDPClient.listen(4111);
      g_connected  = 1;
      g_flags |= (STATUS_DEVICE_CHANGED|STATUS_SERVICE_CHANGED);
      g_register_service = g_servicelist;
#ifndef LITE
      register_device();
#else
      register_service();
#endif
    } else {
      g_connected = 0;
    }
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_SV[] = {
    { "count", PARAM_TYPE_UINT16, &g_service_count },
    { "list", PARAM_TYPE_UINT16, &g_servicelist },
    { "sent", PARAM_TYPE_UINT16, &g_sent },
    { "done", PARAM_TYPE_UINT16, &g_done },
    { "timeout", PARAM_TYPE_UINT16, &g_timeout },
    { "received", PARAM_TYPE_UINT16, &g_received },
    { "errors", PARAM_TYPE_UINT16, &g_errors },
    { "flags", PARAM_TYPE_UINT16, &g_flags },
    { "outlen", PARAM_TYPE_UINT16, &g_registrar_out_len },
    { NULL, 0, NULL }
  };

  struct ParamList g_SVList = { "sv", &s_SV[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_SVList );
    return SUCCESS;
  }

#ifndef LITE
  /*****************************************
   *  Telnet
   *****************************************/

  char * display_slist( struct ServiceList *plist, char *out, char *outmax )
  {
    const struct Service *p = plist->list;

    for ( ; p->name ; p++ ) {
      out += snprintf( out, outmax - out, "Service: %s;", p->name );
      out += snprintf( out, outmax - out,"type=%s;", p->type);
      out += snprintf( out, outmax - out,"port=%u;", p->port);
      out += snprintf( out, outmax - out,"expires=%u\r\n", p->expires);
    }

    return out;
  }

  event const char * TelnetShow.token() { return "services"; }
  event const char * TelnetShow.help() { return "Show statistics from various counters using ServiceView interface.\r\n"; }

  event char * TelnetShow.process( char *in, char *out, char *outmax )
  {
    struct ServiceList *plist;
    char *next;
    char *name = next_token(in, &next, ' ');

    if ( *name ) {
      for ( plist = g_servicelist ; plist ; plist = plist->next ) {
	if ( strcmp(plist->name, name) == 0 ) 
	  return display_slist( plist, out, outmax );
      }
    }

    if (name)
      out += snprintf( out, outmax - out, "I couldn't show '%s'\r\n", name);
    out += snprintf( out, outmax - out, "Valid choices are:" );
    
    for ( plist = g_servicelist ; plist ; plist = plist->next ) 
      out += snprintf( out, outmax - out, " %s", plist->name);
    
    out += snprintf( out, outmax - out, "\r\n");
    out += snprintf( out, outmax - out, "%s\r\n", g_registrar_out);
    out += snprintf( out, outmax - out, "%d\r\n", strlen(g_registrar_out));
    return out;
  }
#endif  

  /*
   * UDPClient
   */	

#ifndef LITE
  void register_device() {
    if (!g_connected)
      return;
    if ((g_flags & STATUS_SENDING) == 0) {
      char *out = g_registrar_out;
      char *outmax = out + OUTBUF_LEN;

      g_flags |= STATUS_SENDING;
      out += snprintf(out, outmax - out, "REGISTER device\r\n");
      out += snprintf(out, outmax - out, "DID: %s\r\n", g_device_id);
      out += snprintf(out, outmax - out, "IP: %s\r\n", g_ipaddr);
      out += snprintf(out, outmax - out, "Type: %s\r\n", g_dtype);

      g_registrar_out_len = out - g_registrar_out;

      call Timer.start(TIMER_ONE_SHOT, 5*1024);
      if (call UDPClient.sendTo( &g_registrar_address, g_registrar_out, out - g_registrar_out ) == SUCCESS) {
	g_sent++;
	g_flags |=  STATUS_SENDING;
	g_flags &= ~STATUS_DEVICE_CHANGED;
      } else {
	g_errors++;
      }
    }
  }
#endif

  void register_service() {
    if (!g_connected)
      return;
    if ((g_flags & STATUS_SENDING) == 0 && g_register_service) {
      struct ServiceList *slist = g_register_service;
      char *out = g_registrar_out;
      char *outmax = out + OUTBUF_LEN;

      out += snprintf(out, outmax - out, "REGISTER service\r\n");
      out += snprintf(out, outmax - out, "DID: %s\r\n", g_device_id);
      out += snprintf(out, outmax - out, "SVP: %u\r\n", slist->list->port);
      out += snprintf(out, outmax - out, "SVT: %s\r\n", slist->list->type);
      out += snprintf(out, outmax - out, "SVN: %s\r\n", slist->name);
      if (slist->list->status)
	out += snprintf(out, outmax - out, "Status: %s\r\n", slist->list->status);
      if (slist->list->expires)
	out += snprintf(out, outmax - out, "Expires: %d\r\n", slist->list->expires);
      g_registrar_out_len = out - g_registrar_out;

      g_register_service = slist->next;

      call Timer.start(TIMER_ONE_SHOT, 5*1024);
      if (call UDPClient.sendTo( &g_registrar_address, g_registrar_out, out - g_registrar_out ) == SUCCESS) {
	g_flags |=  STATUS_SENDING;
	g_sent++;
	if (g_register_service == NULL)
	  g_flags &= ~STATUS_SERVICE_CHANGED;
      } else {
	g_errors++;
      }
    }
  }

  event void UDPClient.sendDone() { 
    g_flags &= ~STATUS_SENDING;
    g_done++;
    call Timer.stop();
    call Timer.start(TIMER_ONE_SHOT, 10*1024);
    if (g_flags & STATUS_SERVICE_CHANGED)
      register_service();
#ifndef LITE
    else if (g_flags & STATUS_DEVICE_CHANGED)
      register_device();
#endif
  }

  /* failed to send or time to resend */
  event result_t Timer.fired() {
    g_flags &= STATUS_SENDING;

    g_timeout++;
    if (g_flags & STATUS_DEVICE_CHANGED)
      register_service();
#ifndef LITE
    else if (g_flags & STATUS_DEVICE_CHANGED)
      register_device();
#endif
    return SUCCESS;
  }

  event void UDPClient.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len ) { }

}

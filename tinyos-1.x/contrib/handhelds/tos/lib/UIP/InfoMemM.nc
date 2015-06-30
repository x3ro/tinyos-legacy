/**
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
 *  Telnet client that displays information memory.
 *  This is NOT a param view client for the simple reason
 *  that the infomem pointer can be moved.
 *
 *  Author:  Andrew Christian <andrew.christian@hp.com>
 *           April 2005
 *
 */

includes InfoMem;

module InfoMemM {
  uses interface Telnet;
}
implementation {

  event const char *Telnet.token() { return "infomem"; }
  event const char *Telnet.help() { return "Show data in information memory"; }

  event char *Telnet.process( char *in, char *out, char *outmax )
  {
    out += snprintf( out, outmax - out, "Version:\t%d.%d\r\n", infomem->version >> 8, infomem->version & 0xff);
    out += snprintf( out, outmax - out, "Mac:\t%02x:%02x:%02x:%02x:%02x:%02x:%02x:%02x\r\n", 
		     infomem->mac[0], infomem->mac[1],
		     infomem->mac[2], infomem->mac[3],
		     infomem->mac[4], infomem->mac[5],
		     infomem->mac[6], infomem->mac[7]);
    out += snprintf( out, outmax - out, "IP:\t%d.%d.%d.%d\r\n", 
		    infomem->ip[0], infomem->ip[1], infomem->ip[2], infomem->ip[3]);
    out += snprintf( out, outmax - out, "SSID:\t%s\r\n", infomem->ssid);
    out += snprintf( out, outmax - out, "PanID:\t0x%04x\r\n", infomem->pan_id);
    out += snprintf( out, outmax - out, "Registrar:\t%02x.%02x.%02x.%02x %d\r\n", 
		     infomem->registrar_ip[0], infomem->registrar_ip[1], 
		     infomem->registrar_ip[2], infomem->registrar_ip[3],
		     infomem->registrar_port );
    out += snprintf( out, outmax - out, "NTP:\t%02x.%02x.%02x.%02x\r\n", 
		     infomem->ntp_ip[0], infomem->ntp_ip[1], 
		     infomem->ntp_ip[2], infomem->ntp_ip[3] );
    out += snprintf( out, outmax - out, "GMT offset:\t%d minutes\r\n", infomem->gmt_offset_minutes);
    return out;
  }
}

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
 *
 *  A Telnet interface to CPU registers
 *
 *  Include this in your program by wiring (from the top level):
 *      RegisterM.Telnet -> TelnetM.Telnet[unique("Telnet")];
 *
 *
 *  Copyright (c) 2005 Hewlett-Packard Company
 *  All rights reserved
 *
 *  Authors: Andrew Christian <andrew.christian@hp.com>
 *           April 2005
 */

module RegisterM {
  uses interface Telnet;
}
implementation {
  event const char * Telnet.token() { return "reg"; }
  event const char * Telnet.help() { return "Display register information"; }

  enum {
    PORT_TYPE_INTERRUPTS,
    PORT_TYPE_PLAIN,
    PORT_TYPE_SINGLE,
  };

  struct PortType {
    uint8_t type;
    uint8_t base;
    char *name;
  };

  const struct PortType s_ports[] = {
    { PORT_TYPE_INTERRUPTS, P1IN_, "p1" },
    { PORT_TYPE_INTERRUPTS, P2IN_, "p2" },
    { PORT_TYPE_PLAIN, P3IN_, "p3" },
    { PORT_TYPE_PLAIN, P4IN_, "p4" },
    { PORT_TYPE_PLAIN, P5IN_, "p5" },
    { PORT_TYPE_PLAIN, P6IN_, "p6" },
    { PORT_TYPE_SINGLE, BCSCTL1_, "bcsctl1" },
    { PORT_TYPE_SINGLE, BCSCTL2_, "bcsctl2" },
    { PORT_TYPE_SINGLE, DCOCTL_, "dcoctl" },
  };
  
  int match_reg( char *in, char *out, char *outmax )
  {
    const struct PortType *p;
    int i;

    for ( i = 0, p = s_ports ; i < (sizeof(s_ports) / sizeof(struct PortType)) ; i++, p++ ) {
      if ( strcmp(in,p->name) == 0 ) {
	switch (p->type) {
	case PORT_TYPE_INTERRUPTS:
	  return snprintf( out, outmax - out, "%s IN=%02x OUT=%02x DIR=%02x IFG=%02x"
			   " IES=%02x IE=%02x SEL=%02x\r\n",in,
			   *((uint8_t *) ((int)p->base)),
			   *((uint8_t *) ((int)p->base + 1)),
			   *((uint8_t *) ((int)p->base + 2)),
			   *((uint8_t *) ((int)p->base + 3)),
			   *((uint8_t *) ((int)p->base + 4)),
			   *((uint8_t *) ((int)p->base + 5)),
			   *((uint8_t *) ((int)p->base + 6)));

	case PORT_TYPE_PLAIN:
	  return snprintf( out, outmax - out, "%s IN=%02x OUT=%02x DIR=%02x SEL=%02x\r\n",in,
			   *((uint8_t *) ((int)p->base)),
			   *((uint8_t *) ((int)p->base + 1)),
			   *((uint8_t *) ((int)p->base + 2)),
			   *((uint8_t *) ((int)p->base + 3)));

	case PORT_TYPE_SINGLE:
	  return snprintf( out, outmax - out, "%s VALUE=%02x\r\n",in,
			   *((uint8_t *) ((int)p->base)));

	}
      }
    }

    return 0;
  }

  event char * Telnet.process( char *in, char *out, char *outmax )
  {
    const struct PortType *p;
    char *next = in;
    int i;
    int good = 0;
    int bad = 0;
    
    while ((in = next_token( next, &next, ' ' )) != NULL ) {
      i = match_reg( in, out, outmax );
      if ( i ) { 
	out += i;
	good++;
      }
      else {
	out += snprintf( out, outmax-out, "%s Unrecognized register\r\n", in );
	bad++;
      }
    }

    if ( good == 0 || bad > 0 ) {
      out += snprintf( out, outmax - out, "Valid registers:");
      for ( i = 0, p = s_ports ; i < (sizeof(s_ports) / sizeof(struct PortType)) ; i++, p++ )
	out += snprintf( out, outmax - out, " %s", p->name );
      out += snprintf( out, outmax - out, "\r\n");
    }
    return out;
  }
}

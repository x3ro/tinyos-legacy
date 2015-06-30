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
 *  A generic interface for parameter views that can handle Telnet commands
 * 
 *  Andrew Christian
 *  10 March 2005
 */

module ParamViewM {
  provides {
    interface StdControl;
    interface ParamList;
  }
  uses {
    interface Telnet as TelnetShow;
    interface ParamView;
  }
}
implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));
  struct ParamList *g_paramlist = NULL;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    return call ParamView.init();
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /*****************************************
   *  ParamView
   *****************************************/

  default command result_t ParamView.init() { return SUCCESS; }

  event void ParamView.add( struct ParamList *plist )
  {
    plist->next = g_paramlist;
    g_paramlist = plist;
  }

  command struct ParamList *ParamList.getParamList() {
    return g_paramlist;
  }

  /*****************************************
   *  Telnet
   *****************************************/

  int display_param_value( char *out, int len, const struct Param *p )
  {
    int nchars = 0;
    switch (p->type) {
      case PARAM_TYPE_UINT8:
	nchars = snprintf( out, len,"%u", *((uint8_t *)p->ptr));
	break;
      case PARAM_TYPE_UINT16:
	nchars = snprintf( out, len,"%u", *((uint16_t *)p->ptr));
	break;
      case PARAM_TYPE_UINT32:
	nchars = snprintf( out, len,"%lu", *((uint32_t *)p->ptr));
	break;
      case PARAM_TYPE_STRING: {
	const char *string = (char *)p->ptr;
	nchars = snprintf( out, len,"%s", string);
      } break;
      case PARAM_TYPE_INT8:
	nchars = snprintf( out, len,"%d", *((int8_t *)p->ptr));
	break;
      case PARAM_TYPE_INT16:
	nchars = snprintf( out, len,"%d", *((int16_t *)p->ptr));
	break;
      case PARAM_TYPE_HEX8:
	nchars = snprintf( out, len,"0x%02x", (*((int8_t *)p->ptr)) & 0x00ff);
	break;
      case PARAM_TYPE_HEX16:
	nchars = snprintf( out, len,"0x%04x", *((int16_t *)p->ptr));
	break;
      }
    return nchars;
  }

  command int ParamList.displayParamValue( char *out, int len, const struct Param *param )
  {
    return display_param_value(out, len, param);
  }

  char * display_plist( struct ParamList *plist, char *out, char *outmax )
  {
    const struct Param *p = plist->list;

    for ( ; p->name ; p++ ) {
      out += snprintf( out, outmax - out, "%s\t", p->name );
      out += display_param_value( out, outmax - out, p );
      out += snprintf( out, outmax - out, "\r\n" );
    }

    return out;
  }

  event const char * TelnetShow.token() { return "show"; }
  event const char * TelnetShow.help() { return "Show statistics from various counters using ParamView interface.\r\n"; }

  event char * TelnetShow.process( char *in, char *out, char *outmax )
  {
    struct ParamList *plist;
    char *next;
    char *name = next_token(in, &next, ' ');

    if ( *name ) {
      for ( plist = g_paramlist ; plist ; plist = plist->next ) {
	if ( strcmp(plist->name, name) == 0 ) 
	  return display_plist( plist, out, outmax );
      }
    }

    out += snprintf( out, outmax - out, "I couldn't show '%s'\r\nValid choices are:", name );
    
    for ( plist = g_paramlist ; plist ; plist = plist->next ) 
      out += snprintf( out, outmax - out, " %s", plist->name);
    
    out += snprintf( out, outmax - out, "\r\n");
    return out;
  }
  
}

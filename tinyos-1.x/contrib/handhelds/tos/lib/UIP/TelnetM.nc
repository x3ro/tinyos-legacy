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
 * A modular interface to Telnet
 *
 * Authors:  Andrew Christian
 *           20 January 2005
 */

includes NVTParse;

module TelnetM {
  provides {
    interface StdControl;
    interface Telnet[uint8_t i];
  }

  uses {
    interface TCPServer;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  enum {
    IN_BUFFER_LENGTH    = 60,
    OUT_BUFFER_LENGTH   = 300,
    TELNET_SERVER_COUNT = 1,     // Number of simultaneous connection
    
    COUNT_TELNET_USERS = uniqueCount("Telnet"),

    T_STATE_IDLE   = 0,       // Listening, available for connection
    T_STATE_ACTIVE = 1,       // Actively reading characters
    T_STATE_CR     = 2        // Actively reading, just saw a '\r'
  }; 

  struct TelnetState {
    int     state;
    char    in[ IN_BUFFER_LENGTH ];
    int     in_length;      // How many bytes are in the input buffer

    char    out[ OUT_BUFFER_LENGTH ];
    int     out_length;     // How many bytes are in the output buffer
    int     write_length;   // Last write request length
  };

  struct TelnetStats {
    uint16_t connect;
    uint16_t failed;   // Failed connections
    uint16_t commands;
    uint16_t bad_commands;
  };

  struct TelnetState g_state[ TELNET_SERVER_COUNT ];
  struct TelnetStats g_stats;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    int i;
    for ( i = 0 ; i < TELNET_SERVER_COUNT ; i++ )
      g_state[i].state = 0;

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call TCPServer.listen(23);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  default event const char * Telnet.token[uint8_t num]() { return NULL; }
  default event const char * Telnet.help[uint8_t num]() { return NULL; }
  default event char * Telnet.process[uint8_t num]( char *in, char *out, char *outmax ) { return out; }

  /*******************************************************************************/

  char * add_prompt( char *out, char *outmax )
  {
    return out + snprintf(out, outmax - out, "Mote> ");
  }

  char * handle_help( char *in, char *out, char *outmax )
  {
    char *p, *next;
    int i;

    p = next_token( in, &next, ' ' );
    if (p) {
      for ( i = 0 ; i < COUNT_TELNET_USERS ; i++ ) {
	if ( strcmp(signal Telnet.token[i](), p ) == 0 ) {
	  out += snprintf(out, outmax - out, " %s", signal Telnet.help[i]());
	  return add_prompt(out,outmax);
	}
      }
    }

    out += snprintf(out, outmax - out, "Commands: help quit");

    for ( i = 0 ; i < COUNT_TELNET_USERS ; i++ ) 
      out += snprintf(out, outmax - out, " %s", signal Telnet.token[i]());

    out += snprintf(out, outmax - out, "\r\n");
    return add_prompt(out, outmax);
  }

  /**
   * We have a null-terminated line
   * It may have nothing in it.
   * Return the number of bytes written
   */

  char * process_incoming( char *in, char *out, char *outmax )
  {
    char *p, *next;
    int i;

    p = next_token( in, &next, ' ' );
    if (!p)
      return add_prompt( out, outmax );

    if (strcmp(p, "quit") == 0)
      return NULL;

    if (strcmp(p, "help") == 0 || strcmp(p,"?") == 0)
      return handle_help(next, out, outmax);

    for ( i = 0 ; i < COUNT_TELNET_USERS ; i++ ) {
      if ( strcmp(signal Telnet.token[i](), p) == 0 ) {
	out = signal Telnet.process[i]( next, out, outmax );
	if (out)
	  out = add_prompt( out, outmax );
	return out;
      }
    }

    out += snprintf( out, outmax - out, "I didn't understand that.\r\nType '?' for help\r\n");
    return add_prompt( out, outmax );
  }

  /*******************************************************************************/

  event void TCPServer.connectionMade( void *token )
  {
    struct TelnetState *ts = g_state;
    int i;
    char *out, *outmax;
    int len;

    for ( i = 0 ; i < TELNET_SERVER_COUNT ; i++, ts++ ) {
      if ( ts->state == T_STATE_IDLE ) {
	ts->state        = T_STATE_ACTIVE;
	ts->in_length    = 0;
	*((struct TelnetState **)token) = ts;

	out = ts->out;
	outmax = ts->out + OUT_BUFFER_LENGTH;
	out += snprintf( out, outmax - out, "Featherweight command shell\r\nType '?' for help\r\n");
	out = add_prompt( out, outmax );

	len = (out - (char *)ts->out);
	ts->out_length   = len;
	ts->write_length = len;
	call TCPServer.write( token, ts->out, len );
	
	g_stats.connect++;
	return;
      }
    }
    
    g_stats.failed++;
    call TCPServer.close(token);
  }

  event void TCPServer.writeDone( void *token )
  {
    struct TelnetState *ts = *((struct TelnetState **)token);
    int len = ts->out_length - ts->write_length;

    if ( len )   // Shift the characters over in the buffer
      memcpy( ts->out, ts->out + ts->write_length, len );

    ts->write_length = len;
    ts->out_length   = len;

    if ( len )
      call TCPServer.write( token, ts->out, len );
  }

  enum {
    T_IAC  = 255,
    T_DONT = 254,
    T_DO   = 253,
    T_WONT = 252,
    T_WILL = 251,

    T_SE  = 240,  // Subnegotiation End
    T_NOP = 241,  // No Operation
    T_DM  = 242,  // Data Mark
    T_BRK = 243,  // Break
    T_IP  = 244,  // Interrupt process
    T_AO  = 245,  // Abort output
    T_AYT = 246,  // Are You There
    T_EC  = 247,  // Erase Character
    T_EL  = 248,  // Erase Line
    T_GA  = 249,  // Go Ahead
    T_SB =  250,  // Subnegotiation Begin

    T_NULL = 0,

    OPT_BINARY = 0,   // 8-bit data
    OPT_ECHO   = 1,   // Echo
    OPT_RCP    = 2,   // Prepare to reconnect
    OPT_SGA    = 3,   // Suppress go ahead
    OPT_NAMS   = 4,   // Approximate message size
    OPT_STATUS = 5,   // Give status
    OPT_TM     = 6,   // Timing mark
    OPT_RCTE   = 7,   // Remote controlled transmission and echo
    OPT_NAOL   = 8,   // negotiate about output line width
    OPT_NAOP   = 9,   // negotiate about output page size
    OPT_NAOCRD = 10,   // negotiate about CR disposition
    OPT_NAOHTS = 11,   // negotiate about horizontal tabstops
    OPT_NAOHTD = 12,   // negotiate about horizontal tab disposition
    OPT_NAOFFD = 13,   // negotiate about formfeed disposition
    OPT_NAOVTS = 14,   // negotiate about vertical tab stops
    OPT_NAOVTD = 15,   // negotiate about vertical tab disposition
    OPT_NAOLFD = 16,   // negotiate about output LF disposition
    OPT_XASCII = 17,   // extended ascii character set
    OPT_LOGOUT = 18,   // force logout
    OPT_BM     = 19,   // byte macro
    OPT_DET    = 20,   // data entry terminal
    OPT_SUPDUP = 21,   // supdup protocol
    OPT_SUPDUPOUTPUT = 22,   // supdup output
    OPT_SNDLOC = 23,   // send location
    OPT_TTYPE  = 24,   // terminal type
    OPT_EOR    = 25,   // end or record
    OPT_TUID   = 26,   // TACACS user identification
    OPT_OUTMRK = 27,   // output marking
    OPT_TTYLOC = 28,   // terminal location number
    OPT_VT3270REGIME = 29,   // 3270 regime
    OPT_X3PAD  = 30,   // X.3 PAD
    OPT_NAWS   = 31,   // window size
    OPT_TSPEED = 32,   // terminal speed
    OPT_LFLOW  = 33,   // remote flow control
    OPT_LINEMODE = 34,   // Linemode option
    OPT_XDISPLOC = 35,   // X Display Location
    OPT_OLD_ENVIRON = 36,   // Old - Environment variables
    OPT_AUTHENTICATION = 37,   // Authenticate
    OPT_ENCRYPT = 38,   // Encryption option
    OPT_NEW_ENVIRON = 39,   // New - Environment variables
  };

  /*
   * Receive data from the client.
   * Copy a single line at a time and process.
   * Also handle Telnet special characters
   */

  event void TCPServer.dataAvailable( void *token, uint8_t *buf, uint16_t len )
  {
    struct TelnetState *ts = *((struct TelnetState **)token);
    char *in      = ts->in + ts->in_length;
    char *out     = ts->out + ts->out_length;
    int   state   = ts->state;

    if ( state == T_STATE_IDLE )
      return;

    while (len--) {
      uint8_t c = *buf++;

      switch (state) {
      case T_STATE_ACTIVE: // Normal reading state
	switch (c) {
	case 0:
	  break;
	case T_IAC:
	  state = T_IAC;
	  break;
	default:
	  if ( (in - ts->in) < IN_BUFFER_LENGTH ) 
	    *in++ = c;
	  if (c == '\r')
	    state = T_STATE_CR;
	  break;
	}
	break;

      case T_STATE_CR:              // Just after a CR
	switch (c) {
	case 0:
	  state = T_STATE_ACTIVE;
	  break;
	case T_IAC:
	  state = T_IAC;
	  break;
	default:
	  if ( (in - ts->in) < IN_BUFFER_LENGTH ) 
	    *in++ = c;

	  if ( c == '\n') {
	    *(in - 2) = 0;   // Null terminate the line
	    out = process_incoming(ts->in, out, ts->out + OUT_BUFFER_LENGTH);
	    if ( !out ) {
	      call TCPServer.close(token);
	      ts->state = T_STATE_IDLE;
	      return;
	    }
	    in = ts->in;   // Reset the in buffer
	  }

	  state = T_STATE_ACTIVE;  // Set back to normal state
	  break;
	}
	break;

      case T_IAC:           // Just after IAC
	switch (c) {
	case T_DO:
	case T_DONT:
	case T_WILL:
	case T_WONT:
	  state = c; 
	  break;

	case T_IAC:
	  if ( (in - ts->in) < IN_BUFFER_LENGTH ) 
	    *in++ = c;
	  state = T_STATE_ACTIVE;
	  break;

	case T_SB:  // Subnegotiation begin
	case T_SE:  // Subnegotiation end
	default:
	  // For the moment, just dump it
	  state = T_STATE_ACTIVE;
	  break;
	}
	break;

      case T_DO: 
      case T_DONT:
	switch (c) {
	default:   // By default, we reply 'WONT'
	  if ((out - ts->out) <= (OUT_BUFFER_LENGTH - 3)) {
	    *out++ = T_IAC;
	    *out++ = T_WONT;
	    *out++ = c;
	  }
	  state = T_STATE_ACTIVE;
	  break;
	}
	break;

      case T_WILL:
      case T_WONT:
	switch (c) {
	default:   // By default, we reply 'WONT'
	  if ((out - ts->out) <= (OUT_BUFFER_LENGTH - 3)) {
	    *out++ = T_IAC;
	    *out++ = T_DONT;
	    *out++ = c;
	  }
	  state = T_STATE_ACTIVE;
	  break;
	}
	break;
      }
    }

    // We've run out of characters.  Stash the state
    ts->state      = state;
    ts->in_length  = in - ts->in;
    ts->out_length = out - ts->out;

    // Start a write if there's no data already queued up
    if ( ts->write_length == 0 && ts->out_length ) {  
      ts->write_length = ts->out_length;
      call TCPServer.write( token, ts->out, ts->out_length );
    }
  }

  event void TCPServer.connectionFailed( void *token, uint8_t reason )
  {
    struct TelnetState *ts = *((struct TelnetState **)token);
    ts->state = 0;
  }
}

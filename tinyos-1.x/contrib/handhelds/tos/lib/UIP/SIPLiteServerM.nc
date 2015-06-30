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
 *  Send an RPT-lite data stream to whomever requests
 *
 *  Andrew Christian <andrew.christian@hp.com>
 *  10 March 2005 
 *
 * Types of packets we understand: INVITE
 * Set 'expires' to 0 to hangup.
 *
 * Commands to the server...
 *
 *       COMMAND SIPLITE/1.0
 *       Expires: NUMBER
 *       Call-ID: OPAQUE
 *
 *       m=PORTNUM x x x x
 *
 * 
 * Responses from the server
 *
 *       SIPLITE/1.0 200 OK
 *       Expires: NUMBER
 *       Call-ID: OPAQUE
 * 
 *       m=PORTNUM x
 */

includes NVTParse;

module SIPLiteServerM {
  provides {
    interface StdControl;
    interface SIPLiteServer;
    interface ParamView;
  }
  uses {
    interface Timer as TimerMaster;

    interface UDPClient as UDPMaster;
    interface UDPClient as UDPStream;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  struct SIPLiteServerStats {
    uint16_t connect;
    uint16_t reconnect;
    uint16_t bad_request;
    uint32_t packets_sent;
  };

  struct SIPLiteServerStats g_stats;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() 
  {
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    call TimerMaster.start( TIMER_REPEAT, 1024 );
    call UDPMaster.listen( 5062 );    // Listen to the SIP port for now
    call UDPStream.listen( 5063 );    // Bind this for convenience
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    call TimerMaster.stop();
    call UDPMaster.listen(0);   // Shut him off
    return SUCCESS;
  }

  /*****************************************
   *  UDP Master functions
   *****************************************/

  enum {
    FIRST_LINE,
    SIPLITE_LINE,
    SDP_LINE,

    SIPLITE_INVITE = 1,

    SIPLITE_CALL_ID_LEN = 10,
  };

  struct SIPLiteCommand {
    int       cmd;
    uint16_t  expires;
    uint16_t  port;
    int       protocol;
    char      call_id[ SIPLITE_CALL_ID_LEN ];
  };

  enum {
    SLC_STATE_IDLE   = 0,   // Not in use
    SLC_STATE_ACTIVE = 1,   // In active use
    SLC_STATE_ERROR  = 2,   // Used to send an error response
    SLC_STATE_HANGUP = 3,   // We're hanging up this connection
    SLC_MASK         = 0x03,

    SLC_PENDING_COMMAND = 0x8000,
    SLC_PENDING_DATA    = 0x4000,

    MAX_SIPLITE_CONNECTIONS = 3,
    OUTBUF_LEN = 80
  };

  struct SIPLiteConnection {
    int  state;
    struct SIPLiteCommand cmd;
    struct udp_address addr;
  };

  struct SIPLiteConnection g_connections[ MAX_SIPLITE_CONNECTIONS ];

  char g_command_out[OUTBUF_LEN];
  const char *g_data_out;
  int   g_data_out_len;

  struct SIPLiteConnection *g_active_conn;   // The g_connection that is sending a command frame
  struct SIPLiteConnection *g_active_data;  // Points to the g_connection that is sending a data frame

  /*
   * Parse an incoming message
   */

  int parse_message( struct SIPLiteCommand *cmd, char *buf, char *buf_max )
  {
    char *token;
    char *next;
    char *next_line;

    int line = FIRST_LINE;

    while (buf < buf_max) {
      next_line = mark_line(buf, buf_max);  // 0 terminate this line, return pointer to next line

      switch (line) {
      case FIRST_LINE:
	token = next_token( buf, &next, ' ' );
	if ( token ) {
	  if ( strcmp(token, "INVITE") == 0 ) {
	    cmd->cmd = SIPLITE_INVITE;
	  }
	}
	line = SIPLITE_LINE;
	break;

      case SIPLITE_LINE:
	if (!*buf) 
	  line = SDP_LINE;
	else {
	  token = next_token( buf, &next, ':' );
	  if ( token ) {
	    if (strcmp(token, "Call-ID") == 0) {
	      strncpy( cmd->call_id, skip_white( next ), SIPLITE_CALL_ID_LEN );
	    }
	    else if ( strcmp(token, "Expires") == 0 ) {
	      cmd->expires = atou(skip_white(next));
	    }
	  }
	}
	break;

      case SDP_LINE:
	token = next_token(buf,&next, '=');
	if (token && strcmp(token, "m") == 0 ) {
	  token = next_token(next,&next,' ');
	  if ( token ) {
	    cmd->port = atou(token);
	    token = next_token(next,&next, ' ');
	    if ( token )
	      cmd->protocol = atoi(token);
	  }
	}
	break;
      }

      buf = next_line;
    }

    return ( cmd->cmd && cmd->port > 0 && cmd->protocol && cmd->call_id[0] );
  }

  int count_connections( int protocol )
  {
    int i;
    int count = 0;
    struct SIPLiteConnection *slc = g_connections;

    for ( i = 0 ; i < MAX_SIPLITE_CONNECTIONS ; i++, slc++ ) {
      if ((slc->state & SLC_MASK) == SLC_STATE_ACTIVE && slc->cmd.protocol == protocol )
	count++;
    }
    return count;
  }

  struct SIPLiteConnection * find_free()
  {
    int i;
    struct SIPLiteConnection *slc = g_connections;

    for ( i = 0 ; i < MAX_SIPLITE_CONNECTIONS ; i++, slc++ ) {
      if (slc->state == SLC_STATE_IDLE)
	return slc;
    }
    return NULL;
  }

  struct SIPLiteConnection * find_existing( const struct udp_address *addr, const struct SIPLiteCommand *cmd )
  {
    int i;
    struct SIPLiteConnection *slc = g_connections;

    for ( i = 0 ; i < MAX_SIPLITE_CONNECTIONS ; i++, slc++ ) {
      if ((slc->state & SLC_MASK) == SLC_STATE_ACTIVE
	  && slc->addr.ip[0] == addr->ip[0] 
	  && slc->addr.ip[1] == addr->ip[1] 
	  && slc->addr.ip[2] == addr->ip[2] 
	  && slc->addr.ip[3] == addr->ip[3] 
	  && slc->addr.port == addr->port
	  && strcmp(slc->cmd.call_id,cmd->call_id) == 0)
	return slc;
    }

    return NULL;
  }

  /* 
   * Send a response to a command.  This can be an error or a normal acknowledgement
   */

  void send_command_response( struct SIPLiteConnection *conn )
  {
    char *out = g_command_out;
    char *out_max = out + OUTBUF_LEN;
    
    out += snprintf( out, out_max - out, "SIPLITE/1.0 ");
    if ( (conn->state & SLC_MASK) == SLC_STATE_ERROR ) 
      out += snprintf(out, out_max - out, "400 Bad Request\r\n");
    else
      out += snprintf(out, out_max - out, "200 OK\r\n");

    out += snprintf(out, out_max - out, "Expires: %u\r\n", conn->cmd.expires);
    out += snprintf(out, out_max - out, "Call-ID: %s\r\n", conn->cmd.call_id);

    if ( (conn->state & SLC_MASK) == SLC_STATE_ACTIVE ) {
      out += snprintf(out, out_max - out, "\r\nm=%u %d\r\n", conn->cmd.port, conn->cmd.protocol);
    }
    else {
      out += snprintf(out, out_max - out, "\r\n");
    }

    g_active_conn = conn;
    call UDPMaster.sendTo( &conn->addr, g_command_out, out - g_command_out );
  }

  /*
   * Process a received UDP packet
   */

  event void UDPMaster.sendDone()
  {
    int i;
    struct SIPLiteConnection *conn = g_connections;
    
    if ( g_active_conn->state == SLC_STATE_ERROR || g_active_conn->state == SLC_STATE_HANGUP )
      g_active_conn->state = SLC_STATE_IDLE;

    for ( i = 0 ; i < MAX_SIPLITE_CONNECTIONS ; i++, conn++ ) {
      if ( conn->state & SLC_PENDING_COMMAND ) {
        conn->state &= ~SLC_PENDING_COMMAND;
	send_command_response( conn );
	return;
      }
    }

    g_active_conn = NULL;
  }

  /*
   * Packet received on the command interface
   */

  event void UDPMaster.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len )
  {
    struct SIPLiteCommand cmd;
    struct SIPLiteConnection *conn;

    memset(&cmd,0,sizeof(cmd));

    if (!parse_message( &cmd, buf, buf + len )) {  // Bad message
      g_stats.bad_request++;
      conn = find_free();
      if (!conn)
	return;

      conn->state = SLC_STATE_ERROR;
      conn->addr  = *addr;
      conn->cmd   = cmd;
    }
    else {
      int delta   = 0;   // Number of connections we're adding or subtracting
      int current = count_connections( cmd.protocol );

      conn = find_existing(addr, &cmd);  // Only finds ACTIVE connections
      
      if ( !conn ) {
	conn = find_free();
	if (!conn)   // No space...drop it
	  return;
	delta = 1;
	g_stats.connect++;
	conn->addr  = *addr;
	conn->cmd   = cmd;
	conn->state = SLC_STATE_ACTIVE;
      }
      else {
	g_stats.reconnect++;
      }

      conn->cmd.expires = cmd.expires;
      if ( conn->cmd.expires == 0 ) {
	conn->state = SLC_STATE_HANGUP;
	--delta;  // Could be dropping a connection that we just added
      }

      if ( current > 0 && (current + delta) == 0)
	signal SIPLiteServer.dropStream( conn->cmd.protocol );
      else if ( current == 0 && delta > 0)
	signal SIPLiteServer.addStream( conn->cmd.protocol );
    }
     
    if ( !g_active_conn )
      send_command_response( conn );
    else
      conn->state |= SLC_PENDING_COMMAND;
  }

  void send_data( struct SIPLiteConnection *dc )
  {
    struct udp_address addr = dc->addr;
    
    g_stats.packets_sent++;
    g_active_data = dc;
    addr.port = dc->cmd.port;
    call UDPStream.sendTo( &addr, g_data_out, g_data_out_len );
  }

  event void UDPStream.sendDone()
  {
    int i;
    struct SIPLiteConnection *conn = g_connections;
    
    for ( i = 0 ; i < MAX_SIPLITE_CONNECTIONS ; i++, conn++ ) {
      if ( conn->state & SLC_PENDING_DATA ) {
        conn->state &= ~SLC_PENDING_DATA;
	send_data( conn );
	return;
      }
    }

    g_active_data = NULL;
    signal SIPLiteServer.sendDone();
  }

  /*
   * Return how many active streams using this protocol
   */

  command int SIPLiteServer.countStream( int protocol )
  {
    return count_connections( protocol );
  }

  /*
   * A new type of data packet is ready to be sent out.  Mark all connections
   * with this type as data_pending
   */

  command void SIPLiteServer.send( int protocol, const char *buf, int len )
  {
    int i;
    struct SIPLiteConnection *conn = g_connections;
    struct SIPLiteConnection *dc   = NULL;
    
    for ( i = 0 ; i < MAX_SIPLITE_CONNECTIONS ; i++, conn++ ) {
      if ( (conn->state & SLC_MASK) == SLC_STATE_ACTIVE && conn->cmd.protocol == protocol ) {
	conn->state |= SLC_PENDING_DATA; 
	dc = conn;
      }
    }

    if ( dc ) {
      dc->state &= ~SLC_PENDING_DATA;
      g_data_out = buf;
      g_data_out_len = len;
      send_data(dc);
    }
    else {
      signal SIPLiteServer.sendDone();
    }
  }

  event void UDPStream.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len )
  {
  }

  /*****************************************
   *  Master timer fires once per second
   *****************************************/

  event result_t TimerMaster.fired()
  {
    int i;
    struct SIPLiteConnection *conn = g_connections;
    
    for ( i = 0 ; i < MAX_SIPLITE_CONNECTIONS ; i++, conn++ ) {
      if ( conn->cmd.expires > 0) {
	conn->cmd.expires--;
	if ( conn->cmd.expires == 0) {
	  if ( g_active_conn == conn )   // We might have been in the process of sending a message
	    conn->state = SLC_STATE_HANGUP;
	  else 
	    conn->state = SLC_STATE_IDLE;

	  signal SIPLiteServer.dropStream( conn->cmd.protocol );
	}
      }
    }

    return SUCCESS;
  }

  /*****************************************************************/

  const struct Param s_SIPLite[] = {
    { "connect",   PARAM_TYPE_UINT16, &g_stats.connect },
    { "reconnect", PARAM_TYPE_UINT16, &g_stats.reconnect },
    { "bad",       PARAM_TYPE_UINT16, &g_stats.bad_request },
    { "sent",      PARAM_TYPE_UINT32, &g_stats.packets_sent },
    { NULL, 0, NULL }
  };

  struct ParamList g_SIPLite   = { "siplite",   &s_SIPLite[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_SIPLite );
    return SUCCESS;
  }

}

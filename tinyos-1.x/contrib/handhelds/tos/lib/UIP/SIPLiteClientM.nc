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
 * Library for connecting to a SIPLite server
 *
 * Author: Andrew Christian <andrew.christian@hp.com>
 *         14 March 2005
 */

includes NVTParse;
includes SIPLiteClient;

module SIPLiteClientM {
  provides {
    interface StdControl;
    interface SIPLiteClient;
  }

  uses {
    interface Timer;
    interface UDPClient as UDPControl;
    interface UDPClient as UDPStream;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  enum {
    FIRST_LINE,
    SIPLITE_LINE,
    SDP_LINE,

    SIPLITE_CALL_ID_LEN = 10,
  };

  enum {
    EXPIRE_TIME = 10,
    LOCAL_STREAM_PORT = 5062,
    OUTBUF_LEN = 80
  };

  enum {
    STATE_IDLE,        // Not connected
    STATE_PRE_TRYING,  // Waiting for a 'sendDone' response to my invite
    STATE_TRYING,      // Waiting for either a response or a timeout
    STATE_CONNECTED,   // Have active connection
    STATE_CONNECTED_REINVITE,  // Waiting for a 'sendDone' response to my invite
    STATE_CONNECTED_HANGUP,    // Trying to hang up the connection
  };

  struct SIPLiteResponse {
    uint16_t code;
    uint16_t expires;
    uint16_t port;     // The port I specify I will receive on 
    int      protocol;
    char     call_id[ SIPLITE_CALL_ID_LEN ];
  };

  char g_command_out[OUTBUF_LEN];
  int  g_media_type;
  int  g_expires;
  int  g_timeout;
  int  g_state;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() 
  {
    g_state = STATE_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    call Timer.start( TIMER_REPEAT, 1024 );
    call UDPStream.listen( LOCAL_STREAM_PORT );  
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    call Timer.stop();
    call UDPControl.listen(0);   // Shut him off
    return SUCCESS;
  }

  /*****************************************
   *  Messaging
   *****************************************/

  /*
   * Parse an incoming message
   */

  int parse_response( struct SIPLiteResponse *resp, char *buf, char *buf_max )
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
	if ( token && strcmp(token, "SIPLITE/1.0") == 0 ) {
	  token = next_token( next, &next, ' ');
	  if ( token )
	    resp->code = atou(token);
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
	      strncpy( resp->call_id, skip_white( next ), SIPLITE_CALL_ID_LEN );
	    }
	    else if ( strcmp(token, "Expires") == 0 ) {
	      resp->expires = atou(skip_white(next));
	    }
	  }
	}
	break;

      case SDP_LINE:
	token = next_token(buf,&next, '=');
	if (token && strcmp(token, "m") == 0 ) {
	  token = next_token(next,&next,' ');
	  if ( token ) {
	    resp->port = atou(token);
	    token = next_token(next,&next, ' ');
	    if ( token )
	      resp->protocol = atoi(token);
	  }
	}
	break;
      }

      buf = next_line;
    }
    // Just return if it seems to be well formated
    return ( resp->code 
	     && resp->port == LOCAL_STREAM_PORT 
	     && resp->protocol == g_media_type 
	     && resp->call_id[0] );
  }

  /*
   * Request a data stream
   */

  result_t send_invite( int expires )
  {
    char *out = g_command_out;
    out += snprintf( out, OUTBUF_LEN,
		     "INVITE SIPLITE/1.0\r\nExpires: %u\r\nCall-ID: CHANGEME\r\n\r\nm=%u %d\r\n",
		     expires, LOCAL_STREAM_PORT, g_media_type);
    
    return call UDPControl.send( g_command_out, out - g_command_out );
  }

  /*****************************************
   *  SIPLiteClient interface
   *****************************************/

  command result_t SIPLiteClient.connect( uint8_t octet1, uint8_t octet2, 
					  uint8_t octet3, uint8_t octet4, 
					  uint16_t port, int media_type )
  {
    struct udp_address addr;

    if ( g_state != STATE_IDLE )
      return FAIL;

    addr.ip[0] = octet1; addr.ip[1] = octet2; addr.ip[2] = octet3; addr.ip[3] = octet4;
    addr.port = port;
    g_media_type = media_type;

    call UDPControl.connect( &addr );
    if ( send_invite( EXPIRE_TIME ) == FAIL )
      return FAIL;
    
    g_state = STATE_PRE_TRYING;
    return SUCCESS;
  }

  command result_t SIPLiteClient.close()
  {
    switch (g_state) {
    case STATE_CONNECTED:
      send_invite(0);
      g_state = STATE_IDLE;
      signal SIPLiteClient.connectionFailed( SIPLITE_CLIENT_CLOSED );
      return SUCCESS;

    case STATE_CONNECTED_REINVITE:
      g_state = STATE_CONNECTED_HANGUP;
      return SUCCESS;
    }

    return FAIL;
  }

  /*****************************************
   *  Packets from the UDP layer
   *****************************************/

  event void UDPControl.sendDone()
  {
    switch (g_state) {
    case STATE_PRE_TRYING:
      g_state   = STATE_TRYING;
      g_timeout = 2;  // About two seconds
      break;

    case STATE_CONNECTED_REINVITE:
      g_state   = STATE_CONNECTED;
      g_timeout = 2;
      break;

    case STATE_CONNECTED_HANGUP:
      send_invite(0);
      g_state = STATE_IDLE;
      signal SIPLiteClient.connectionFailed( SIPLITE_CLIENT_CLOSED );
      break;
    }
  }

  event void UDPControl.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len )
  {
    struct SIPLiteResponse resp;
    int good;

    memset(&resp, 0, sizeof(resp));
    good = parse_response(&resp,buf,buf+len);

    switch ( g_state ) {
    case STATE_TRYING:
      if ( good && resp.expires > 0 ) {
	g_state = STATE_CONNECTED;
	g_expires = resp.expires;
	g_timeout = g_expires / 2;
	signal SIPLiteClient.connectDone( TRUE );
      }
      break;

    case STATE_CONNECTED:
      if ( !good || resp.expires == 0 ) {
	g_state   = STATE_IDLE;
	g_timeout = 0;
	signal SIPLiteClient.connectionFailed( good ? SIPLITE_CLIENT_EXPIRED : SIPLITE_CLIENT_MSG_ERROR );
      }
      else {
	g_expires = resp.expires;
	g_timeout = g_expires / 2;
      }
      break;
    }
  }

  event void UDPStream.sendDone()
  {
  }

  event void UDPStream.receive( const struct udp_address *addr, uint8_t *buf, uint16_t len )
  {
    signal SIPLiteClient.dataAvailable( buf, len );
  }

  /*****************************************
   *  Timer fires when we need to re-register
   *****************************************/

  event result_t Timer.fired()
  {
    if ( g_expires )
      g_expires--;

    if (!g_timeout)   // Don't decrement if already 0
      return SUCCESS;

    if (--g_timeout)    // Hasn't timed out yet
      return SUCCESS;

    // We've timed out

    switch (g_state) {
    case STATE_TRYING:
      g_state = STATE_IDLE;
      signal SIPLiteClient.connectDone( FALSE );
      break;

    case STATE_CONNECTED:
      if ( g_expires ) {  // There's still time
	g_timeout = 2;    
	send_invite( EXPIRE_TIME );
      }
      else {
	g_state = STATE_IDLE;
	signal SIPLiteClient.connectionFailed( SIPLITE_CLIENT_EXPIRED );
      }
      break;
    }
    return SUCCESS;
  }
}




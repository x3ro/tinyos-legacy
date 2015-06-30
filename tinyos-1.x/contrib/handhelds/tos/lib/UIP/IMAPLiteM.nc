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
 * Library for retrieving messages
 *
 * Author:  Andrew Christian <andrew.christian@hp.com>
 *          16 March 2005
 *
 *
 * Client commands and server responses (all in NVT format).
 *
 *
 * 1.  SELECT
 *    
 *   Arguments:  <mailbox_name> [MAXID <max_msg_id>]
 *   Responses:  EXISTS <n>  (required)
 *               UNSEEN <n>  (if MAXID specified)
 *      Result:  OK - select completed
 *               NO - select failed (no such mailbox?)
 *
 *   The SELECT command selects a mailbox to view.  The EXISTS response
 *   returns the number of messages in the mailbox.  If you provide the
 *   optional 'max_msg_id' argument, the UNSEEN response will be returned.
 *   It contains the number of messages with msg_id > 'max_msg_id'
 *
 *  Example:   C: SELECT INBOX_200             (select inbox for long_address=200)
 *             S: OK EXISTS 8
 *
 *             C: SELECT INBOX_201 MAXID 342
 *             S: OK EXISTS 7 UNSEEN 2
 * 
 * 
 * 2.  FETCH
 *
 *   Arguments:  msg_id [FLAGS HEADER]
 *   Responses:  <msg_id> <timestamp> <message content>
 *      Result:  OK - message retrieved
 *               NO - message does not exist
 *
 *   The FETCH command retrieves a message from the mailbox by msg_id.
 *   It returns the first message with msg_id >= the specified msg_id.
 *   The message string may not contain \r\n sequences.
 *   If FLAGS HEADER is specified, we only return the msg_id
 *
 *  Example:   C: FETCH 342
 *             S: OK 343 1245234 This is a message from Jose. How are you?
 *
 *             C: FETCH 343 FLAGS HEADER
 *             S: OK 343
 * 
 *
 * 3.  STORE
 *
 *   Arguments:  msg_id FLAGS DELETE
 *   Responses:  OK, NO
 *
 *  The STORE command changes information about the message in the main
 *  database.  In our case, it is only used to delete messages.  Note that
 *  it take a msg_id.  
 *
 *  Example:   C: STORE 343 FLAGS DELETE
 *             S: OK
 *
 *
 *  4.  APPEND
 *
 *    Arguments:  <timestamp> <message content>
 *    Responses:  <msg_id>
 *       Result:  OK, NO
 *
 *   Add a new message to the database.
 *
 *   Example:  C: APPEND 123412351 This is a message I left on the clipboard.
 *             S: OK 344
 *
 *
 *
 */

includes NVTParse;

module IMAPLiteM {
  provides {
    interface StdControl;
    interface IMAPLite;
    interface ParamView;
  }

  uses {
    interface TCPClient;
    interface Leds;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  enum {
    MAX_MSG_COUNT = 20,
    LOCAL_ID      = 0x8000,        // Flag for a locally-generated ID
  };
  
  int                g_cursor;
  int                g_message_count;
  struct TextMessage g_messages[ MAX_MSG_COUNT ];

  int      g_remove_count;
  uint16_t g_remove[ MAX_MSG_COUNT ];   // Messages to be removed

  enum {
    STATE_IDLE = 0,     // Not connected
    STATE_CONNECTING,
    STATE_SELECT,       // Executing a SELECT command
    STATE_FETCH,        // Executing a FETCH command
    STATE_FETCH_VALIDATE,   // Validating existing messages (a FETCH)
    STATE_REMOVE,       // Executing a STORE command
    STATE_APPEND,       // Executing an APPEND command
    STATE_DONE,

    STATE_MASK = 0x7fff,
    STATE_CR   = 0x8000,  // Set this bit for the receive state machine

    BUF_LEN    = TEXT_MESSAGE_MAX_LEN + 25,  // The fetch command is worst case
  };

  struct IMAPClientState {
    char buf[BUF_LEN];
    int  buf_len;
    int  state;

    int exists;  // Number of messagse on the server
    int unseen;  // Number of messages the server is claiming unseen

    uint16_t msg_id;
  };

  struct IMAPClientState g_ics;

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() 
  {
    return SUCCESS;
  }

  command result_t StdControl.start() 
  {
    return SUCCESS;
  }

  command result_t StdControl.stop() 
  {
    call TCPClient.close();
    return SUCCESS;
  }

  /*****************************************
   *  Utility functions
   *****************************************/

  uint16_t find_unique_local_id()
  {
    int      i;
    uint16_t id = LOCAL_ID | 0x0001;
    struct TextMessage *msg = g_messages;
    
    for ( i = 0 ; i < g_message_count ; i++, msg++ ) {
      if ( msg->id == id )
	id++;
    }
    
    return id;
  }

  uint16_t find_max_msg_id()
  {
    int      i;
    uint16_t id = 0;
    struct TextMessage *msg = g_messages;
    
    for ( i = 0 ; i < g_message_count ; i++, msg++ ) {
      if ( !(msg->id & LOCAL_ID) && msg->id > id )
	id = msg->id;
    }
    
    return id;
  }

  uint16_t next_msg_id_after( uint16_t id )
  {
    int i;
    struct TextMessage *msg = g_messages;
    uint16_t next_id = 0xffff;   // Start out at MAXIMUM
    
    for ( i = 0 ; i < g_message_count ; i++, msg++ ) {
      if ( msg->id > id && msg->id < next_id )
	next_id = msg->id;
    }
    
    return next_id;
  }

  struct TextMessage *find_first_local()
  {
    int      i;
    struct TextMessage *msg = g_messages;
    
    for ( i = 0 ; i < g_message_count ; i++, msg++ ) {
      if ( msg->id & LOCAL_ID )
	return msg;
    }
    return NULL;
  }

  struct TextMessage * insert_message( uint16_t id )
  {
    int i;
    struct TextMessage *msg = g_messages;
    
    for ( i = 0 ; i < g_message_count && msg->id < id ; i++, msg++ )
      ;
    
    // We're adding to the end
    if ( i == g_message_count ) {
      g_message_count++;
      msg->id = id;
      return msg;
    }

    // Uh...we seem to already have this message.  Just overwrite it.
    if ( msg->id == id ) 
      return msg;

    // We need to move a few (and fix the cursor)
    memmove( msg + 1, msg, (char *)(&g_messages[g_message_count]) - (char *)msg);
    msg->id = id;
    if ( g_cursor >= i )
      g_cursor++;
    g_message_count++;
    return msg;
  }

  bool remove_message( uint16_t id )
  {
    int i;
    struct TextMessage *msg = g_messages;
    
    for ( i = 0 ; i < g_message_count ; i++, msg++ ) {
      if ( msg->id == id ) {
	g_message_count--;
	memmove( msg, msg + 1, (char *)(&g_messages[g_message_count]) - (char *)msg);

	if ( g_cursor > i ) 
	  g_cursor--;

	return TRUE;
      }
    }

    return FALSE;
  }

  bool sort_in_message( struct TextMessage *msg_b )
  {
    int i;
    struct TextMessage tmp;
    struct TextMessage *msg = g_messages;
    
    // Check if I need to move it DOWN in the list
    for ( i = 0 ; msg != msg_b ; i++, msg++ ) {
      if ( msg->id > msg_b->id ) {
	// I need to move msg_b to where msg is.
	tmp = *msg_b;
	memmove( msg + 1, msg, msg_b - msg );
	*msg = tmp;
	return TRUE;
      }
    }

    // Check if I need to move it UP in the list
    for ( i++, msg++ ; i < g_message_count && msg->id < msg_b->id; i++, msg++ ) 
      ;

    // 'i' should be pointing to the first message that has msg->id > msg_b->id
    --msg;
    if ( msg_b != msg ) {
      tmp = *msg_b;
      memmove( msg_b + 1, msg_b, msg - msg_b );
      *msg = tmp;
      return TRUE;
    }

    return FALSE;
  }

  /*****************************************
   *  IMAP Lite interface
   *****************************************/

  command result_t IMAPLite.update( uint8_t octet1, uint8_t octet2, uint8_t octet3, uint8_t octet4, uint16_t port )
  {
    result_t result;

    if ( g_ics.state != STATE_IDLE )
      return FAIL;

    result = call TCPClient.connect( octet1, octet2, octet3, octet4, port );

    if ( result == SUCCESS )
      g_ics.state = STATE_CONNECTING;

    return result;
  }

  command int IMAPLite.count_msgs() 
  {
    return g_message_count;
  }

  command int IMAPLite.get_cursor()
  {
    return g_cursor;
  }

  command int IMAPLite.set_cursor( int i )
  {
    if ( i >= g_message_count )
      i = g_message_count - 1;

    if ( i < 0 )
      i = 0;

    g_cursor = i;
    return g_cursor;
  }

  command int IMAPLite.id_to_index( uint16_t id )
  {
    int i;
    struct TextMessage *msg = g_messages;
    
    for ( i = 0 ; i < g_message_count ; i++, msg++ ) {
      if ( msg->id == id )
	return i;
    }

    return -1;
  }

  command const struct TextMessage *IMAPLite.get_msg_by_index( int i )
  {
    if ( i < 0 || i >= g_message_count )
      return NULL;

    return g_messages + i;
  }

  command const struct TextMessage *IMAPLite.get_msg_by_id( uint16_t id )
  {
    int i;
    struct TextMessage *msg = g_messages;
    
    for ( i = 0 ; i < g_message_count ; i++, msg++ ) {
      if ( msg->id == id )
	return msg;
    }
    return NULL;
  }

  command uint16_t IMAPLite.add_msg( uint32_t timestamp, const char *text )
  {
    struct TextMessage *msg;

    if ( g_message_count >= MAX_MSG_COUNT )
      return 0;

    call Leds.yellowToggle();

    msg = &g_messages[g_message_count];
    msg->timestamp = timestamp;
    strncpy( msg->text, text, TEXT_MESSAGE_MAX_LEN - 1 );
    msg->text[TEXT_MESSAGE_MAX_LEN-1] = 0;
    msg->id = find_unique_local_id();
    g_message_count++;

    signal IMAPLite.changed( CHANGED_MSG_ADDED );

    return msg->id;
  }

  command void IMAPLite.remove_msg( uint16_t id )
  {
    if ( remove_message( id )) {
      // Put non-local messages on the remove list
      if ( (id & LOCAL_ID) == 0 )
	g_remove[ g_remove_count++ ] = id;

      signal IMAPLite.changed( CHANGED_MSG_DELETED );
    }
  }

  /*****************************************
   *  Communication functions
   *****************************************/

  void close_connection( int reason )
  {
    g_ics.state = STATE_DONE;
    call TCPClient.close();
  }

  void send_select()
  {
    int len;

    g_ics.exists = -1;
    g_ics.unseen = -1;
    g_ics.state  = STATE_SELECT;

#ifndef MAILBOX
    len = snprintf(g_ics.buf, BUF_LEN, "SELECT mailbox1 MAXID %u\r\n", find_max_msg_id());
#else
    len = snprintf(g_ics.buf, BUF_LEN, "SELECT " MAILBOX " MAXID %u\r\n", find_max_msg_id());
#endif

    call TCPClient.write( g_ics.buf, len );
  }

  void send_fetch( uint16_t id )
  {
    int len;

    g_ics.msg_id = id;
    g_ics.state  = STATE_FETCH;

    len = snprintf(g_ics.buf, BUF_LEN, "FETCH %u\r\n", id);
    call TCPClient.write( g_ics.buf, len );
  }

  void send_fetch_validate( uint16_t id )
  {
    int len;

    g_ics.msg_id = id;
    g_ics.state  = STATE_FETCH_VALIDATE;

    len = snprintf(g_ics.buf, BUF_LEN, "FETCH %u FLAGS HEADER\r\n", id + 1);
    call TCPClient.write( g_ics.buf, len );
  }

  void send_remove( uint16_t id )
  {
    int len;

    g_ics.msg_id  = id;
    g_ics.state = STATE_REMOVE;

    len = snprintf(g_ics.buf, BUF_LEN, "STORE %u FLAGS DELETE\r\n", id);
    call TCPClient.write( g_ics.buf, len );
  }

  void send_append( struct TextMessage *msg )
  {
    int len;
    
    g_ics.msg_id = msg->id;
    g_ics.state  = STATE_APPEND;

    len = snprintf(g_ics.buf, BUF_LEN, "APPEND %lu %s\r\n", msg->timestamp, msg->text);
    call TCPClient.write( g_ics.buf, len );
  }

  /**
   * Process a result line from the server
   */

  void process_select( int ok, char *next )
  {
    char *p, *p2;
    struct TextMessage *msg;

    if (!ok)
      return close_connection( UPDATE_SERVER_ERROR );

    while ( (p  = next_token( next, &next, ' ')) != NULL &&
	    (p2 = next_token( next, &next, ' ')) != NULL) {
      if (strcmp(p,"EXISTS") == 0)
	g_ics.exists = atoi(p2);
      else if (strcmp(p,"UNSEEN") == 0)
	g_ics.unseen = atoi(p2);
      else
	return close_connection( UPDATE_SERVER_ERROR );
    }

    if ( g_remove_count ) 
      return send_remove( g_remove[--g_remove_count] );

    msg = find_first_local();
    if ( msg )
      return send_append( msg );
    
    if ( g_ics.unseen > 0 )
      return send_fetch( find_max_msg_id() + 1 );

    if ( g_ics.exists != g_message_count )
      return send_fetch_validate( 0 );
    
    return close_connection( UPDATE_CHANGE );
  }

  /*
   * We've asked to receive a new message.
   * Add it to our list.
   */

  uint16_t last_msg_id;
  uint32_t last_timestamp;

  void process_fetch( int ok, char *next )
  {
    char *p1, *p2;
    struct TextMessage *msg;
    uint16_t msg_id;

    if (!ok)
      return send_select();

    if ( (p1 = next_token( next, &next, ' ')) == NULL ||
	 (p2 = next_token( next, &next, ' ')) == NULL) 
      return close_connection( UPDATE_SERVER_ERROR );

    if ( g_message_count >= MAX_MSG_COUNT )
      return close_connection( UPDATE_OUT_OF_SPACE );

    /* Add message here */
    msg_id = atou(p1);
    last_msg_id = msg_id;
    msg = insert_message( msg_id );
    msg->timestamp = atoul(p2);
    last_timestamp = msg->timestamp;
    strncpy( msg->text, next, TEXT_MESSAGE_MAX_LEN - 1);
    msg->text[TEXT_MESSAGE_MAX_LEN - 1] = 0;  // Just in case

    /* Generate appropriate update events */
    signal IMAPLite.changed( CHANGED_MSG_ADDED | CHANGED_FROM_SERVER );

    /* Fetch any remaining message or run a select again */
    if ( --g_ics.unseen ) 
      return send_fetch( msg_id + 1 );

    return send_select();
  }

  /*
   * We're walking our list of known messages looking for
   * messages that have been deleted or added.
   *
   * The basic strategy is to increase g_ics.msg_id from 0
   * until we can't find any larger messages.
   */

  void process_fetch_validate( int ok, char *next )
  {
    char *p;
    uint16_t msg_id;
    uint16_t msg_id_2;

    if ( !ok ) {  // No message with ID > g_ics.msg_id exists
      msg_id = find_max_msg_id();  // Look at our biggest message
      if ( msg_id > g_ics.msg_id && remove_message( msg_id ))
	signal IMAPLite.changed( CHANGED_MSG_DELETED | CHANGED_FROM_SERVER );
      return send_select();
    }

    if ( (p = next_token( next, &next, ' ')) == NULL)
      return close_connection( UPDATE_SERVER_ERROR );

    msg_id   = atou(p);  // Will be > g_ics.msg_id
    msg_id_2 = next_msg_id_after( g_ics.msg_id );

    if ( msg_id == msg_id_2 ) 
      return send_fetch_validate( msg_id );

    if ( msg_id < msg_id_2 )   // There's a message on the server we don't have
      return send_fetch( msg_id );   

    // msg_id > msg_id_2....hence msg_id_2 is an extra message

    if ( remove_message( msg_id_2 ) )
      signal IMAPLite.changed( CHANGED_MSG_DELETED | CHANGED_FROM_SERVER );
    return send_select();
  }

  /*
   * We've removed a message from the server.
   * Note that this DOESN'T affect the local list
   */

  void process_remove( int ok, char *next )
  {
    if ( g_remove_count ) 
      return send_remove( g_remove[--g_remove_count] );

    return send_select();
  }

  /*
   * We've added a local message to the server
   */

  void process_append( int ok, char *next )
  {
    uint16_t msg_id;
    struct TextMessage *msg = g_messages;
    char *p;
    int i;
    
    if ( !ok || (p = next_token(next,&next,' ')) == NULL )
      return close_connection( UPDATE_SERVER_ERROR );

    msg_id = atou(p);

    for ( i = 0 ; i < g_message_count ; i++, msg++ ) {
      if ( msg->id == g_ics.msg_id ) {  // Found the old message
	msg->id = msg_id;
	if ( sort_in_message(msg) )
	  signal IMAPLite.changed( CHANGED_MSG_ORDER | CHANGED_FROM_SERVER );
	break;
      }
    }

    msg = find_first_local();
    if ( msg )
      return send_append( msg );

    return send_select();
  }


  void process_input_line()
  {
    char *p, *next;
    int ok;

    p = next_token( g_ics.buf, &next, ' ' );
    if (!p) 
      return close_connection( UPDATE_SERVER_ERROR );

    ok = (strcmp(p,"OK") == 0);
    if (!ok && strcmp(p,"NO")) 
      return close_connection( UPDATE_SERVER_ERROR );

    switch ( (g_ics.state & STATE_MASK)) {
    case STATE_SELECT:
      return process_select(ok,next);

    case STATE_FETCH:
      return process_fetch(ok,next);

    case STATE_FETCH_VALIDATE:
      return process_fetch_validate(ok,next);

    case STATE_REMOVE:
      return process_remove(ok,next);

    case STATE_APPEND:
      return process_append(ok,next);
    }
  }

  /*****************************************
   *  TCPClient interface
   *****************************************/

  event void TCPClient.connectionMade( uint8_t status )
  {
    // We only get this call if the connection was actually made
    send_select();
  }

  event void TCPClient.writeDone()
  {
  }

  /*
   * We assume that writing is complete before reading begins (so we re-use the buffer for sending) 
   */

  bool find_line( uint8_t *buf, uint16_t len )
  {
    int    state   = (g_ics.state & STATE_CR);
    char  *outbuf  = g_ics.buf + g_ics.buf_len;
    int    buf_len = g_ics.buf_len;

    while (len--) {
      uint8_t c = *buf++;

      if ( buf_len < BUF_LEN ) {
	*outbuf++ = c;
	buf_len++;
      }
	    
      if ( !state && c == '\r')
	state = STATE_CR;
      else if ( c == '\n' ) {
	if ( state ) {  // End of line
	  *(outbuf - 2) = 0;  // Null terminate and discard balance
	  g_ics.buf_len = 0;   // Set this up for the next line
	  return TRUE;
	}
	state = 0;  // Set back to normal state
      }
    }

    // If we get here, we've run out of characters
    // Stash our current state
    g_ics.state   = (g_ics.state & STATE_MASK) | state;
    g_ics.buf_len = buf_len;
    return FALSE;
  }

  event void TCPClient.dataAvailable( uint8_t *buf, uint16_t len )
  {
    if ( find_line( buf, len ))
      process_input_line();
  }

  event void TCPClient.connectionFailed( uint8_t reason )
  {
    g_ics.state = STATE_IDLE;
    signal IMAPLite.updateDone();
  }

  /*****************************************************************/

  const struct Param s_IMAP[] = {
    { "state",    PARAM_TYPE_UINT16, &g_ics.state   },
    { "buf_len",  PARAM_TYPE_UINT16, &g_ics.buf_len },
    { "exists",   PARAM_TYPE_UINT16, &g_ics.exists },
    { "unseen",   PARAM_TYPE_UINT16, &g_ics.unseen },
    { "count",    PARAM_TYPE_UINT16, &g_message_count },
    { "msg_id[0]", PARAM_TYPE_UINT16, &g_messages[0].id },
    { "last_msg_id", PARAM_TYPE_UINT16, &last_msg_id },
    { "last_timestamp", PARAM_TYPE_UINT16, &last_timestamp },
    { NULL, 0, NULL }
  };

  struct ParamList g_IMAPList   = { "imap",   &s_IMAP[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_IMAPList );
    return SUCCESS;
  }

}

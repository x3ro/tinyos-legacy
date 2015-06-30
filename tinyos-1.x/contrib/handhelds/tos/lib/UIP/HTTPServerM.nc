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
 * Authors:  Andrew Christian
 *           20 January 2005
 */

includes web_site;
includes ParamView;

module HTTPServerM {
  provides {
    interface StdControl;
    interface HTTPServer;
    interface ParamView;
  }

  uses {
    interface TCPServer;
  }
}

implementation {
  extern int snprintf(char *str, size_t size, const char *format, ...) __attribute__ ((C));

  enum {
    WSS_BUF_LEN  = 100,
    WSS_ARGS_LEN = 60,

    WSS_STATE_RX = 0x8000,  // Low byte is line number we're on
    WSS_STATE_HTML_MODE = 0x4000,

    WSS_COUNT = 2,   // How many simultaneous connections we can handle

    TSP_STK_LEN  = 10,
    TSP_TMP_LEN  = 6,
  };

  enum {
    BYTE_CODE_EOF           = 0,    // Stops execution
    BYTE_CODE_PRINT         = 1,    // output TOS
    BYTE_CODE_POP           = 2,    // Drop TOS
    BYTE_CODE_JUMP_IF_FALSE = 3,    // Branch on false to LOCATION (2 bytes)
    BYTE_CODE_JUMP_IF_TRUE  = 4,    // Branch on true to LOCATION (2 bytes)
    BYTE_CODE_JUMP          = 5,    // Branch always to LOCATION (2 bytes)
    BYTE_CODE_ASSIGN        = 6,    // Store TOS in global N (byte)
    BYTE_CODE_PUSH_VAR      = 7,    // Copy global N (byte)               -> TOS
    BYTE_CODE_PUSH_CONST    = 8,    // Copy 2 bytes as int                -> TOS
    BYTE_CODE_PUSH_STRING   = 9,    // Copy LOCATION (2 bytes) as string  -> TOS
    BYTE_CODE_ADD           = 10,   // TOS1 + TOS  -> TOS
    BYTE_CODE_SUBTRACT      = 11,   // TOS1 - TOS  -> TOS
    BYTE_CODE_LOGICAL_NOT   = 12,   // not TOS     -> TOS
    BYTE_CODE_LT            = 13,   // TOS1 < TOS  -> TOS
    BYTE_CODE_GT            = 14,   // TOS1 > TOS  -> TOS
    BYTE_CODE_EQ            = 15,   // TOS1 == TOS -> TOS
    BYTE_CODE_NE            = 16,   // TOS1 != TOS -> TOS
    BYTE_CODE_LE            = 17,   // TOS1 <= TOS -> TOS
    BYTE_CODE_GE            = 18,   // TOS1 >= TOS -> TOS
    BYTE_CODE_MULTIPLY      = 19,   // TOS1 * TOS  -> TOS
    BYTE_CODE_DIVIDE        = 20,   // TOS1 / TOS  -> TOS
    BYTE_CODE_MOD           = 21,   // TOS1 % TOS  -> TOS
    BYTE_CODE_UNARY_MINUS   = 22,   // - TOS       -> TOS
    BYTE_CODE_CALLFUNC      = 23,   // Execute function N (byte)
    BYTE_CODE_PUSH          = 24,   // Push N (byte) cleared items on the stack
  };

  struct WebServerState {
    const struct WebPage *page;

    int  state;               // Current state (high-bit set = RX)
    char buf[WSS_BUF_LEN];    // Working copy of data going out
    int  buf_len;             // Of the buffer
    char args[WSS_ARGS_LEN];  // Arguments passed to the web page

    // These data structures have to do with TSP (active pages)
    const uint8_t   *pc;                  // Program counter (offset from page->data)
    struct TSPStack  stk[TSP_STK_LEN];    // TSP stack
    struct TSPStack *stk_ptr;             // Pointer into the stack
    char             tmp[TSP_TMP_LEN];    // A little space for writing numbers
    const char      *ptr;                 // A pointer to the current string being returned
  };

  struct WebStats {
    uint16_t connect;
    uint16_t failed;
    uint16_t bad_request;
    uint16_t request_overrun;
    uint16_t page_not_found;
  };

  struct WebStats       g_stats;
  struct WebServerState g_server_state[ WSS_COUNT ];

  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    int i;
    for ( i = 0 ; i < WSS_COUNT ; i++ )
      g_server_state[i].state = 0;

    memset(&g_stats, 0, sizeof(g_stats));

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call TCPServer.listen(80);
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /***************** TSP functions *************************/

  void initTSP( struct WebServerState *wss )
  {
    wss->pc      = wss->page->data;
    wss->stk_ptr = wss->stk;
    wss->ptr     = NULL;
  }

  struct TSPStack * eval_function( struct TSPStack *sptr, struct WebServerState *wss, uint8_t i )
  {
    int t, t2;
    char *args;

    switch (i) {
    case FUNCTION_ATOI:
      if ( (--sptr)->type == TSP_TYPE_STRING ) {
	sptr->value = atoi((char *) sptr->value);
	sptr->type = TSP_TYPE_INTEGER;
      }
      return sptr + 1;

    case FUNCTION_INTP:
      --sptr;
      sptr->value = ( sptr->type == TSP_TYPE_INTEGER );
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_STRINGP:
      --sptr;
      sptr->value = ( sptr->type == TSP_TYPE_STRING );
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_PMODE:
      t = (--sptr)->value;
      if ( t == 1 )
      	wss->state |= WSS_STATE_HTML_MODE;
      else
      	wss->state &= ~WSS_STATE_HTML_MODE;
      break;  // Let the default case return a value

    case FUNCTION_HTTP_GET_ARGCOUNT:
      args = wss->args;
      for ( t = 0 ; *args ; t++ )
	args += *args;
      sptr->value = t;
      sptr->type = TSP_TYPE_INTEGER;
      return sptr + 1;

    case FUNCTION_HTTP_GET_ARGNAME:
      args = wss->args;
      t2 = (--sptr)->value;  // Index 
      for ( t = 0 ; *args && t < t2 ; t++ )
	args += *args;

      if ( t == t2 ) {
	sptr->value = (int) (args + 1); // This will be the arg name
	sptr->type = TSP_TYPE_STRING;
	return sptr + 1;
      }
      break;

    case FUNCTION_HTTP_GET_ARGVALUE:
      args = wss->args;
      t2 = (--sptr)->value;  // Index 
      for ( t = 0 ; *args && t < t2 ; t++ )
	args += *args;

      if ( t == t2 ) {
	t2 = strlen(args + 1) + 1; // Bytes used in the name
	if ( *args >= 3 + t2 ) {   
	  sptr->value = (int) args + 1 + t2;
	  sptr->type = TSP_TYPE_STRING;
	  return sptr + 1;
	}
      }
      break;  // Let the default case handle it

    case FUNCTION_HTTP_GET_VALUEBYNAME:
      args = wss->args;
      --sptr;
      for ( t = 0 ; *args && strcmp((char *)sptr->value,args + 1) ; t++ ) 
	args +=*args;

      if ( *args ) {
	t2 = strlen(args + 1) + 1; // Bytes used in the name
	sptr->value = (int) args + 1 + t2;
	sptr->type = TSP_TYPE_STRING;
	return sptr + 1;
      }
      break;

    default:
      return signal HTTPServer.eval_function( sptr, i, wss->tmp, TSP_TMP_LEN );
    }

    // We can reach this from a function above failing.  Push
    // an 'integer = 0' onto the stack and return it.
    sptr->value = 0;
    sptr->type = TSP_TYPE_INTEGER;
    return sptr + 1;
  }

  int processTSP( struct WebServerState *wss )
  {
    struct TSPStack *sptr = wss->stk_ptr;
    const uint8_t *pc = wss->pc;
    uint8_t bc;
    int tmp;
    struct TSPStack *tptr;

    while ((bc = *pc++) != 0) {
      switch (bc) {
      case BYTE_CODE_PRINT:    // output TOS
	sptr--;
	switch (sptr->type) {
	case TSP_TYPE_INTEGER:
	  wss->ptr = wss->tmp;
	  snprintf(wss->tmp, TSP_TMP_LEN, "%d", sptr->value);
	  break;
	case TSP_TYPE_STRING:
	  wss->ptr = (uint8_t *) sptr->value;
	  break;
	}
	wss->stk_ptr = sptr;
	wss->pc = pc;
	return 1;

      case BYTE_CODE_POP:    // Drop TOS
	--sptr;
	break;

	// JUMPS do NOT alter the stack
      case BYTE_CODE_JUMP_IF_FALSE:    // Branch on false to LOCATION (2 bytes)
	tmp = (((int) *pc) << 8) + ((int) *(pc+1));
	tptr = sptr - 1;
	if ( (tptr->type == TSP_TYPE_INTEGER && tptr->value == 0) ||
	     (tptr->type == TSP_TYPE_STRING && wss->page->data[tptr->value] == 0 ))
	  pc = wss->page->data + tmp;
	else
	  pc += 2;
	break;

      case BYTE_CODE_JUMP_IF_TRUE:    // Branch on true to LOCATION (2 bytes)
	tmp = (((int) *pc) << 8) + ((int) *(pc+1));
	tptr = sptr - 1;
	if ( (tptr->type == TSP_TYPE_INTEGER && tptr->value != 0) ||
	     (tptr->type == TSP_TYPE_STRING && wss->page->data[tptr->value] != 0 ))
	  pc = wss->page->data + tmp;
	else
	  pc += 2;
	break;

      case BYTE_CODE_JUMP:    // Branch always to LOCATION (2 bytes)
	pc = wss->page->data + (((int) *pc) << 8) + ((int) *(pc+1));
	break;

      case BYTE_CODE_ASSIGN:    // Store TOS in global N (byte)
	wss->stk[ *pc++ ] = *(--sptr);
	break;

      case BYTE_CODE_PUSH_VAR:    // Copy global N (byte)               -> TOS
	*sptr++ = wss->stk[ *pc++ ];
	break;
	
      case BYTE_CODE_PUSH_CONST:    // Copy 2 bytes as int                -> TOS
	sptr->value = (((int) *pc) << 8) + ((int) *(pc+1));
	sptr->type = TSP_TYPE_INTEGER;
	pc += 2;
	sptr++;
	break;

      case BYTE_CODE_PUSH_STRING:    // Copy LOCATION (2 bytes) as string  -> TOS
	sptr->value = (int) wss->page->data + (((int) *pc) << 8) + ((int) *(pc+1));
	sptr->type = TSP_TYPE_STRING;
	pc += 2;
	sptr++;
	break;

      case BYTE_CODE_ADD:   // TOS1 + TOS  -> TOS
	--sptr;
	(sptr-1)->value += sptr->value;
	break;

      case BYTE_CODE_SUBTRACT:   // TOS1 - TOS  -> TOS
	--sptr;
	(sptr-1)->value -= sptr->value;
	break;

      case BYTE_CODE_LOGICAL_NOT:   // not TOS     -> TOS
	tptr = sptr - 1;
	tptr->value = ((tptr->type == TSP_TYPE_INTEGER && tptr->value == 0) ||
		       (tptr->type == TSP_TYPE_STRING && *((char *)(tptr->value)) == 0 ));
	tptr->type = TSP_TYPE_INTEGER;
	break;
	
      case BYTE_CODE_LT:   // TOS1 < TOS  -> TOS
	sptr--;
	tptr = sptr-1;
	tptr->value = (tptr->value < sptr->value);
	break;

      case BYTE_CODE_GT:   // TOS1 > TOS  -> TOS
	sptr--;
	tptr = sptr-1;
	tptr->value = (tptr->value > sptr->value);
	break;

      case BYTE_CODE_EQ:   // TOS1 == TOS -> TOS
	sptr--;
	tptr = sptr-1;

	if ( sptr->type == TSP_TYPE_STRING && tptr->type == TSP_TYPE_STRING )
	  tptr->value = (strcmp( (char *)(tptr->value), (char *)(sptr->value)) == 0);
	else {
	  tptr->value = ((tptr->type == sptr->type) && (tptr->value == sptr->value));
	}
	tptr->type = TSP_TYPE_INTEGER;
	break;

      case BYTE_CODE_NE:   // TOS1 != TOS -> TOS
	sptr--;
	tptr = sptr-1;

	if ( sptr->type == TSP_TYPE_STRING && tptr->type == TSP_TYPE_STRING )
	  tptr->value = (strcmp( (char *)(tptr->value), (char *)(sptr->value)) != 0);
	else {
	  tptr->value = ((tptr->type != sptr->type) || (tptr->value != sptr->value));
	}
	tptr->type = TSP_TYPE_INTEGER;
	break;

      case BYTE_CODE_LE:   // TOS1 <= TOS -> TOS
	sptr--;
	tptr = sptr-1;
	tptr->value = (tptr->value <= sptr->value);
	break;

      case BYTE_CODE_GE:   // TOS1 >= TOS -> TOS
	sptr--;
	tptr = sptr-1;
	tptr->value = (tptr->value >= sptr->value);
	break;

      case BYTE_CODE_MULTIPLY:   // TOS1 * TOS  -> TOS
	--sptr;
	(sptr-1)->value *= sptr->value;
	break;

      case BYTE_CODE_DIVIDE:   // TOS1 / TOS  -> TOS
	--sptr;
	(sptr-1)->value /= sptr->value;
	break;

      case BYTE_CODE_MOD:   // TOS1 % TOS  -> TOS
	--sptr;
	tptr = sptr-1;
	switch (tptr->type) {
	case TSP_TYPE_INTEGER:
	  tptr->value %= sptr->value;
	  break;
	case TSP_TYPE_STRING:
	  snprintf(wss->tmp, TSP_TMP_LEN, (char *) (tptr->value), sptr->value);
	  tptr->value = (int) wss->tmp;
	  break;
	}
	break;

      case BYTE_CODE_UNARY_MINUS:   // - TOS       -> TOS
	(sptr-1)->value = -(sptr-1)->value;
	break;
	
      case BYTE_CODE_CALLFUNC:   // Execute function N (byte)
	sptr = eval_function( sptr, wss, *pc++ );
	break;

      case BYTE_CODE_PUSH:   // Push N (byte) cleared items on the stack
	sptr += *pc++;
	break;
      }
    }

    // EOF
    wss->pc = pc - 1;  // Set ourselves to return EOF again
    return 0;
  }

  /*
    Copy normal strings from the *srcptr (wss->ptr) into
    the destination buffer.  We do NOT copy terminating NULLs.
    We return the number of bytes copied.

    In normal mode, we just copy characters.  In HTML encoding 
    mode, we translate characters:

       & -> &amp;
       > -> &gt;
       < -> &lt;
       ' -> &#039;
       " -> &quot;
   */

  int copySource( char *dest, struct WebServerState *wss, int max_len )
  {
    char *d = dest;
    const char *s = wss->ptr;
    char *dend = d + max_len;

    if ( wss->state & WSS_STATE_HTML_MODE ) {  // Run substitutions
      while (*s != 0 && d < dend) {
	switch (*s) {
	case '&':
	  if (dend - d < 5) goto copyabort;
	  *d++ = '&'; *d++ = 'a'; *d++ = 'm'; *d++ = 'p'; *d++ = ';';  s++;
	  break;
	case '>':
	  if (dend - d < 4) goto copyabort;
	  *d++ = '&'; *d++ = 'g'; *d++ = 't'; *d++ = ';';  s++;
	  break;
	case '<':
	  if (dend - d < 4) goto copyabort;
	  *d++ = '&'; *d++ = 'l'; *d++ = 't'; *d++ = ';';  s++;
	  break;
	case '"':
	  if (dend - d < 6) goto copyabort;
	  *d++ = '&'; *d++ = 'q'; *d++ = 'u'; *d++ = 'o'; *d++ = 't'; *d++ = ';'; s++;
	  break;
	case 39:
	  if (dend - d < 6) goto copyabort;
	  *d++ = '&'; *d++ = '#'; *d++ = '0'; *d++ = '3'; *d++ = '9'; *d++ = ';'; s++;
	  break;
	default:
	  *d++ = *s++;
	  break;
	}
      }
    }
    else {
      while (*s != 0 && d < dend) 
	*d++ = *s++;
    }

  copyabort:
    wss->ptr = (*s) ? s : NULL;
    return d - dest;
  }

  /*
    We have a clean buffer.  Process TSP until we either run out
     of things to do, or we run out of buffer space
  */

  int handleTSP( struct WebServerState *wss )
  {
    char *b     = wss->buf;
    int max_len = WSS_BUF_LEN;
    int len;
      
    if ( wss->state == 2 )  // Were we end of file?
      return 0;

    if (wss->ptr) {  // Some left over from last time
      len = copySource( b, wss, max_len );
      b += len;
      if (wss->ptr)
	return b - wss->buf;   // We ran out of space
      max_len -= len;
    }
    
    while (processTSP(wss)) {
      len = copySource( b, wss, max_len );
      b += len;
      if (wss->ptr)
	return b - wss->buf;   // We ran out of space
      max_len -= len;
    }

    // Only reach here at EOF
    wss->state = 2; 
    return b - wss->buf;
  }

  /**
   * On connection, check to see if we have a free WebServerState
   * structure.  If so, put a pointer to it in the *token field.
   */

  event void TCPServer.connectionMade( void *token )
  {
    struct WebServerState *wss;
    int i;
    
    for ( i = 0, wss = g_server_state ; i < WSS_COUNT ; i++, wss++ ) {
      if ( wss->state == 0 ) {
	wss->state   = WSS_STATE_RX;
	wss->buf_len = 0;
	wss->page    = NULL;

	*((struct WebServerState **)token) = wss;

	g_stats.connect++;
	return;
      }
    }

    g_stats.failed++;
    call TCPServer.close(token);
  }

  event void TCPServer.writeDone( void *token )
  {
    struct WebServerState *wss = *((struct WebServerState **)token);
    const struct WebPage *page = wss->page;
    int len;

    switch (page->type) {
    case WPT_BINARY:     // Write a header
    case WPT_STATIC_HTML:
    case WPT_STATIC_JPEG:
    case WPT_STATIC_GIF:
      if (wss->state == 2) {
	call TCPServer.close(token);
      }
      else {
	wss->state = 2;
	call TCPServer.write( token, page->data, page->len );
      }
      break;

    case WPT_STATIC_RAW:  // Write the whole thing
      call TCPServer.close(token);
      break;

    case WPT_DYNAMIC_HTML:
      len = handleTSP(wss);
      if (len)
	call TCPServer.write( token, wss->buf, len );
      else
	call TCPServer.close(token);
      break;
    }
  }

  void startWrite( void *token, struct WebServerState *wss )
  {
    const struct WebPage *page = wss->page;
    int len;

    switch (page->type) {
    case WPT_BINARY:     // Write a header
      len = snprintf(wss->buf,WSS_BUF_LEN,
		     "HTTP/1.0 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: %d\r\n\r\n",
		     page->len);
      call TCPServer.write( token, wss->buf, len );
      break;

    case WPT_STATIC_HTML:
      len = snprintf(wss->buf,WSS_BUF_LEN,
		     "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nContent-Length: %d\r\n\r\n",page->len);
      call TCPServer.write( token, wss->buf, len );
      break;

    case WPT_STATIC_JPEG:
      len = snprintf(wss->buf,WSS_BUF_LEN,
		     "HTTP/1.0 200 OK\r\nContent-Type: image/jpeg\r\nContent-Length: %d\r\n\r\n",page->len);
      call TCPServer.write( token, wss->buf, len );
      break;

    case WPT_STATIC_GIF:
      len = snprintf(wss->buf,WSS_BUF_LEN,
		     "HTTP/1.0 200 OK\r\nContent-Type: image/gif\r\nContent-Length: %d\r\n\r\n",page->len);
      call TCPServer.write( token, wss->buf, len );
      break;

    case WPT_STATIC_RAW:  // Write the whole thing
      call TCPServer.write( token, page->data, page->len );
      break;

    case WPT_DYNAMIC_HTML:
      initTSP(wss);
      len = snprintf(wss->buf,WSS_BUF_LEN,"HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n");
      call TCPServer.write( token, wss->buf, len );
    }
    
    wss->state = 1;
  }

  /* Trim the white space from the front of a string */
  inline uint8_t *skipWhite( uint8_t *buf )
  {
    uint8_t c;

    while ((c = *buf) != 0) {
      if (c != ' ')
	return buf;
      buf++;
    }
    return buf;
  }

  /* Mark the end of a string with a null terminator */
  inline uint8_t * nextToken( uint8_t *buf, uint8_t t )
  {
    uint8_t c;

    while ((c = *buf) != 0){
      if (c == t) {
	*buf = 0;
	return buf + 1;
      }
      buf++;
    }
    return NULL;
  }

  /* Convert a character hex digit into a number */
  inline uint8_t fromHexDigit( uint8_t c )
  {
    if ( c >= '1' && c <= '9' ) 
      return c - '0';
    if ( c >= 'a' && c <= 'f' )
      return (c - 'a') + 10;
    if ( c >= 'A' && c <= 'F' )
      return (c - 'A') + 10;
    return 0;
  }

  /* Copy a URL encoded string to a buffer and decode.
     This returns the length of the string put in the out
     buffer INCLUDING the null terminator
  */
  inline int strCopyEncoded( uint8_t *out, int max_len, const uint8_t *in )
  {
    int state = 0;
    int len = 1;  // There will always be a null terminator
    uint8_t c;

    while ( len < max_len && (c = *in++) != 0 ) {
      switch (state) {
      case 0:   // Normal reading mode
	switch (c) {
	case '%':
	  state = 1;  // Hex reading mode 1
	  break;
	case '+':
	  c = ' ';  // Deliberate fall through
	default:
	  *out++ = c;
	  len++;
	  break;
	}
	break;
	    
      case 1:  // First hex digit
	*out = fromHexDigit(c) << 4;
	state = 2;
	break;

      case 2:  // Second hex digit
	*out++ |= fromHexDigit(c);
	len++;
	state = 0;
	break;
      }
    }

    *out = 0;
    return len;
  }

  /* Extract arguments and copy into the arg list in an
     de-encoded form.  We store items in the arg list as 
     follows:

       ( offset, NAME, VALUE )+,  \0

     The offset is the delta to the next name.  When it
     is 0, you have no more. Note that this limits
     name + value combos to less than 253 characters.

     NAME and VALUE are both null terminated strings. 
     VALUE may have zero length.
  */

  void extractArguments( uint8_t *out, int max_len, uint8_t *in )
  {
    uint8_t *fixup, *next, *value;
    int len;
    int count = 0;

    while (max_len > 2) {
      count++;
      next  = nextToken( in, '&' );   // Splits the 'in' string
      value = nextToken( in, '=' );

      fixup = out++;
      max_len--;

      len = strCopyEncoded( out, max_len, in );
      *fixup   = len + 1;
      out     += len;
      max_len -= len;

      if ( value ) {
	len = strCopyEncoded( out, max_len, value );
	*fixup  += len;
	out     += len;
	max_len -= len;
      }

      if ( !next ) {
	*out = 0;
	return;
      }

      in = next;
    }
    *out = 0;
  }

  /*
   * At this time we only look at the first line
   */

  void parseInputLine( struct WebServerState *wss, int len, int line )
  {
    uint8_t *buf, *b;
    const struct WebPage *page;
    int i;

    if ( line != 0 )
      return;

    buf = wss->buf;
    
    if (strncmp(buf,"GET ",4) != 0) {   // We only accept GET requests
      g_stats.bad_request++;
      wss->page = g_web_page + ERROR_PAGE_405;
      return;
    }

    if ( len == WSS_BUF_LEN ) {         // The request was too long
      g_stats.request_overrun++;
      wss->page = g_web_page + ERROR_PAGE_414;  
      return;
    }

    buf[len - 2] = 0;            // Set the line terminator
    buf = skipWhite( buf + 4 );  // Skip over the 'GET '
    nextToken( buf, ' ' );       // Mark the end of the string

    // Extract the arguments
    b = nextToken(buf,'?');
    if (b) 
      extractArguments(wss->args, WSS_ARGS_LEN, b );
    else
      wss->args[0] = 0;

    if ( strcmp(buf,"/") == 0) {
      wss->page = g_web_page + DEFAULT_WEB_PAGE;
      return;
    }

    if ( *buf == '/' )  // Skip over leading slash
      buf++;

    for ( i = 0, page = g_web_page ; i < NUM_WEB_PAGES ; i++, page++ ) {
      if (strcmp(page->url,buf) == 0) {
	wss->page = page;
	return;
      }
    }
    
    /* Didn't find a web page */
    g_stats.page_not_found++;
    wss->page = g_web_page + ERROR_PAGE_404;   // Page not found
  }

  /*
  */

  /**
   *  Receive data from the client
   *  Our basic strategy is to copy from the server one line at a time.
   *  The data will be stashed in wss->buf.
   */

  event void TCPServer.dataAvailable( void *token, uint8_t *buf, uint16_t len )
  {
    struct WebServerState *wss = *((struct WebServerState **)token);
    int    state;
    char  *outbuf;
    int    buf_len;
    int    line;

    if ( !(wss->state & WSS_STATE_RX) )
      return;

    state   = (wss->state & 0x0001);      // 1 bit of 'state' held
    line    = (wss->state & 0x7ffe) >> 1; // Up to ~16000 input lines
    outbuf  = wss->buf + wss->buf_len;
    buf_len = wss->buf_len;

    while (len--) {
      uint8_t c = *buf++;

      if ( buf_len < WSS_BUF_LEN ) {
	*outbuf++ = c;
	buf_len++;
      }
	    
      if ( state == 0 && c == '\r')
	state = 1;
      else if ( c == '\n' ) {
	if ( state == 1 ) {  // End of line
	  if (buf_len > 2) {
	    parseInputLine( wss, buf_len, line );
	    outbuf  = wss->buf;
	    buf_len = 0;
	    line++;
	  }
	  else {  // Blank line...go to transmit state
	    if (wss->page == NULL) 
	      call TCPServer.close(token);
	    else 
	      startWrite(token,wss);
	    return;
	  }
	}
	state = 0;  // Set back to normal state
      }
    }

    // If we get here, we've run out of characters
    // Stash our current state
    wss->state   = WSS_STATE_RX | (line << 1) | state;
    wss->buf_len = buf_len; 
  }

  event void TCPServer.connectionFailed( void *token, uint8_t reason )
  {
    struct WebServerState *wss = *((struct WebServerState **)token);
    wss->state = 0;  // Clear this buffer for future use
  }

  /*****************************************************************/

  const struct Param s_HTTP[] = {
    { "connect",   PARAM_TYPE_UINT16, &g_stats.connect },
    { "failed",    PARAM_TYPE_UINT16, &g_stats.failed },
    { "bad",       PARAM_TYPE_UINT16, &g_stats.bad_request },
    { "overrun",   PARAM_TYPE_UINT16, &g_stats.request_overrun },
    { "not_found", PARAM_TYPE_UINT16, &g_stats.page_not_found },
    { NULL, 0, NULL }
  };

  struct ParamList g_HTTPList   = { "http",   &s_HTTP[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_HTTPList );
    return SUCCESS;
  }

}

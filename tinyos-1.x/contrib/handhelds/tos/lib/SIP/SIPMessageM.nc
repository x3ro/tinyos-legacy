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
 * Authors:  Steve Ayer, Jamey Hicks
 *           Feb-March 2005
 */

includes UIP_internal;
includes SIPMessage;

module SIPMessageM {
    provides {
	interface StdControl;
	interface SIPMessage;
    }
    uses {
	interface SIPMessagePool;
	interface TCPClient;
	interface TCPServer;
	interface Leds;
    }
}

implementation {

  extern int sprintf(char *str, const char *format, ...) __attribute__((C));
  //  void seq_breadcrumbs(int seqnum, int data, char * buf);
  
  uint8_t chunkbuf_c[MAX_CHUNKLEN], chunklen_c;  // read into this, or build message for write
  uint8_t chunkbuf_s[MAX_CHUNKLEN], chunklen_s;  // read into this, or build message for write
  uint8_t linebuf[MAX_CHUNKLEN];
  uint16_t linepos = 0;  // put lines here one at a time to parse

  struct SIPMessage * clientmsg;
  struct SIPMessage * servermsg;

  void * server_token = NULL;

  const struct sip_token_info sip_tokens[] = {
    /* sip requests */
    { SIP_INVITE, "INVITE" },
    { SIP_CANCEL, "CANCEL" },
    { SIP_BYE,    "BYE" },
    { SIP_ACK,    "ACK" },
    { SIP_REGISTER, "REGISTER" },
    { SIP_MESSAGE, "MESSAGE" },

    /* sip response */
    { SIP2, "SIP/2.0" },

    /* sip headers */
    { SIP_CONTENT_TYPE_HEADER, "Content-Type" },
    { SIP_CONTENT_LENGTH_HEADER, "Content-Length" },
    { SIP_CALLID_HEADER, "Call-ID" },
    { SIP_CSEQ_HEADER, "CSeq" },
    { SIP_VIA_HEADER, "Via" },
    { SIP_TO_HEADER, "To" },
    { SIP_FROM_HEADER, "From" },
    { SIP_CONTACT_HEADER, "Contact" },
    { SIP_SUBJECT_HEADER, "Subject" },
    { SIP_SERVER_HEADER, "Server" },
    { SIP_WARNING_HEADER, "Warning" },
    { SIP_DATE_HEADER, "Date" },
    { SIP_USER_AGENT_HEADER, "User-Agent" },

    { SIP_UNKNOWN, 0 }
  };

  command result_t StdControl.init() {
    call SIPMessagePool.init();

    return SUCCESS;
  }
  command result_t StdControl.start() {
	abody[0] = 0;
    call TCPServer.listen(SIP_SERVER_PORT);
    return SUCCESS;
  }
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  uint8_t get_byte(uint8_t *buf, int bytenum)
  {
    return buf[bytenum];
  }

  enum sip_token parse_token()
  {
      int j=0, len;

    enum sip_token tok = SIP_UNKNOWN;

    while (sip_tokens[j].token) {
      len = strlen(sip_tokens[j].str);
      if (strncmp(linebuf + linepos, sip_tokens[j].str, len) == 0) {
	linepos += len;
	tok = sip_tokens[j].token;
	break;
      }
      j++;
    }

    return tok;
  }

  char *sip_token_str(enum sip_token tok)
  {
    const struct sip_token_info *info = &sip_tokens[0];
    while (info->token) {
      if (info->token == tok)
	return info->str;
      info++;
    }
    return NULL;
  }

  int parse_int()
  {
    char *newpos = 0;
    int i = strtoul(linebuf + linepos, &newpos, 0);
    linepos += (newpos - (char *)(linebuf+linepos));
    return i;
  }

  void skip_whitespace()
  {
    char c;
    c = linebuf[linepos];
    while ((c == ' ') || (c == '\t') || (c == '\r') || (c == '\n')) {
      linepos++;
      c = linebuf[linepos];
    }
  }

  void skip_colon()
  {
      //      char c; 
      //      c = linebuf[linepos];
    if (linebuf[linepos] == ':')
	linepos++;
    //	    printf("expecting a colon, got %c\n", c);
  }

  void strcpy_header(char *dst, char *src, int dstlen)
  {
    strncpy(dst, src, dstlen);
    dst[dstlen-1] = 0;
  }
  void strcpy_url(char *dst, char *src, int dstlen)
  {
    char c;
    int i = 0;
    while ((c = *src++) && (i++ < dstlen)) {
      if (c == ' ' || c == '\r' || c == '\n')
	break;
      *dst++ = c;
    }
    *dst = 0;
  }
  void strcpy_line(char *dst, char *src, int dstlen)
  {
    char c;
    int i = 0;
    while ((c = *src++) && (i++ < dstlen)) {
      if (c == '\r' || c == '\n')
	break;
      *dst++ = c;
    }
    *dst = 0;
  }

  void strcat_header(char *dst, char *src, int dstlen)
  {
    int oldlen = strlen(dst);
    strncpy(dst+oldlen, src, dstlen-oldlen);
    dst[dstlen-1] = 0;
  }

  void parse_first_line(struct SIPMessage * msg) 
  {
      static uint8_t i;

    enum sip_token tok;

    linepos = 0;
    tok = parse_token();
    if (tok & SIP_REQUEST) {
      msg->request = tok;
      msg->response_code = 0;
      skip_whitespace();
      strcpy_url(msg->request_uri, linebuf+linepos, sizeof(msg->request_uri));
    }
    else if (tok == SIP2) {
      skip_whitespace();
      //      msg->request = tok;
      msg->response_code = parse_int();
      skip_whitespace();
      strcpy_line(msg->response_str, linebuf+linepos, sizeof(msg->response_str));
    } 
    else {
	;//	snprintf(abody, 30, "bad token %#x 1st line:%s", tok, linebuf);
    }
  }

  void parse_header_line(struct SIPMessage * msg) 
  {
    enum sip_token tok;
    linepos = 0;
    tok = parse_token();
    if (tok) {
      skip_colon(); 
      skip_whitespace();
    } 
    else {
      ;    //printf("header_line: unknown token for line: \n  %s", linebuf);
    }
    switch (tok) {
    case SIP_CONTENT_LENGTH_HEADER:
      msg->content_length = parse_int();
      if (msg->content_length > (MAX_BODY_LEN-1))
	msg->content_length = (MAX_BODY_LEN-1);
      break;
    case SIP_CSEQ_HEADER:
      msg->cseq = parse_int();
      break;
    case SIP_FROM_HEADER:
      strcpy_header(msg->from, linebuf + linepos, sizeof(msg->from));
      break;
    case SIP_TO_HEADER:
      strcpy_header(msg->to, linebuf + linepos, sizeof(msg->to));
      break;
    case SIP_CONTACT_HEADER:
      strcpy_header(msg->contact, linebuf + linepos, sizeof(msg->contact));
      break;
    case SIP_VIA_HEADER:
      strcat_header(msg->vias, linebuf, sizeof(msg->vias)); /* copy whole line including 'Via:' */
      break;
    case SIP_CALLID_HEADER:
      strcpy_header(msg->callid, linebuf + linepos, sizeof(msg->callid));
      break;
    case SIP_CONTENT_TYPE_HEADER:
      strcpy_header(msg->content_type, linebuf + linepos, sizeof(msg->content_type));
      break;
    default:
      break;
    }
  }

  uint16_t parse_data(struct SIPMessage * msg, uint8_t * chunkbuf, uint16_t chunkstart, uint16_t len)
  {
      //      int i;
      static uint8_t jj;
      uint8_t c ;
      static uint16_t body_bytes;

      for (; chunkstart < len; chunkstart++) {
	  c = chunkbuf[chunkstart];

	  switch (msg->parsing_status) {
	  case EXPECTING_BODY_BYTE:
	      msg->body[body_bytes++] = c;
	      if (body_bytes >= msg->content_length) {
		  msg->body[body_bytes] = 0;
		  msg->parsing_status = MESSAGE_COMPLETE;
		  body_bytes = 0;
	      }
	      break;
	  case MESSAGE_COMPLETE:
	      return chunkstart;
	  default:
	      linebuf[linepos++] = c;

	      if (c == '\n') {
		  linebuf[linepos] = 0;
		  /*
		    if(!strcmp(linebuf, "\r\n"))
			seq_breadcrumbs(jj++, msg->parsing_status, "*BLANK*");
		    else
			seq_breadcrumbs(jj++, msg->parsing_status, linebuf);
		  */
		  //		  linepos = 0;
	  
		  switch (msg->parsing_status) {
		  case EXPECTING_FIRST_LINE:
		      parse_first_line(msg);
		      msg->parsing_status = EXPECTING_HEADER_LINE;
		      break;
		  case EXPECTING_HEADER_LINE:
		      if (strcmp(linebuf, "\r\n") == 0) {
			  if (msg->content_length) {
			      msg->parsing_status = EXPECTING_BODY_BYTE;
			      body_bytes = 0;
			      msg->body[0] = 0;
			  }
			  else{
			      msg->parsing_status = MESSAGE_COMPLETE;
			  }
		      } 
		      else{
			  parse_header_line(msg);
		      }
		      break;
		  default:
		      break;
		  }
		  linepos = 0;
	      }
	  }
      }
      return chunkstart;
  }

  void pas_data(struct SIPMessage * msg, uint8_t * cbuf, uint16_t clen)
  {
      int i;
      static uint8_t jj;
      static uint16_t ollp;

      ollp = linepos;
      for(i = 0; i < clen; i++){
	  linebuf[linepos++] = cbuf[i];
	  if(cbuf[i] == '\n'){
	      linebuf[linepos] = 0;
	      linepos = 0;
	  }
      }
      seq_breadcrumbs(jj++, ollp, linebuf+ollp);
  }
  void sip_message_build_next_chunk(struct SIPMessage * msg, uint8_t * chunkbuf, uint8_t * pchunklen)
  {
    uint8_t openspace = 0;
    char fieldbuf[MAX_CHUNKLEN];
    static char * bodyleft;
    uint8_t chunklen, end_o_packet = 0;
    enum sip_message_send_status nextstate = SENDING_IDLE;
    int nbytes = 0;

    chunklen = 0;
    memset(chunkbuf, 0, MAX_CHUNKLEN);

    if (msg->sending_status == SENDING_IDLE)
      return;

    while (msg->sending_status != SENDING_COMPLETE && !end_o_packet) {
      switch (msg->sending_status) {
      case SENDING_REQUEST_LINE:
	  sprintf(fieldbuf, "%s %s SIP/2.0\r\n",
		  sip_token_str(msg->request),
		  msg->request_uri);
	  nbytes = strlen(fieldbuf);
	  nextstate = SENDING_VIAS;
	  break;
      case SENDING_RESPONSE_LINE:
	  sprintf(fieldbuf, "SIP/2.0 %d %s\r\n",
		  msg->response_code,
		  msg->response_str);
	nbytes = strlen(fieldbuf);
	nextstate = SENDING_VIAS;
	break;
      case SENDING_VIAS:
	  sprintf(fieldbuf, "Via: SIP/2.0/TCP %s\r\n", msg->vias);
	  nbytes = strlen(fieldbuf);
	  nextstate = SENDING_MAX_FORWARDS;
	  break;
      case SENDING_FROM:
	  sprintf(fieldbuf, "From: %s\r\n", msg->from);
	  nbytes = strlen(fieldbuf);
	  nextstate = SENDING_CALLID;
	break;
      case SENDING_TO:
	sprintf(fieldbuf, "To: %s\r\n", msg->to);
	nbytes = strlen(fieldbuf);
	nextstate = SENDING_FROM;
	break;
      case SENDING_CSEQ:
	  sprintf(fieldbuf, "CSeq: %d %s\r\n", msg->cseq, sip_token_str(msg->request));
	  nbytes = strlen(fieldbuf);
	  nextstate = SENDING_CONTACT;
	  break;
      case SENDING_CALLID:
	  sprintf(fieldbuf, "Call-ID: %s\r\n", msg->callid);
	  nbytes = strlen(fieldbuf);
	  nextstate = SENDING_CSEQ;
	  break;
      case SENDING_CONTACT:
	  sprintf(fieldbuf, "Contact: %s\r\n", msg->contact);
	  nbytes = strlen(fieldbuf);
	  nextstate = SENDING_EXPIRES;
	  break;
      case SENDING_MAX_FORWARDS:
	sprintf(fieldbuf, "max-forwards: %d\r\n", msg->max_forwards);
	  nbytes = strlen(fieldbuf);
	nextstate = SENDING_TO;
	break;
      case SENDING_EXPIRES:
	  sprintf(fieldbuf, "expires: %d\r\n", msg->expires);
	  nbytes = strlen(fieldbuf);
	nextstate = SENDING_CONTENT_TYPE;
	break;
      case SENDING_CONTENT_LENGTH:
	  sprintf(fieldbuf, "Content-Length: %d\r\n", msg->content_length);
	  nbytes = strlen(fieldbuf);
	nextstate = SENDING_BLANK_LINE;
	break;
      case SENDING_CONTENT_TYPE:
	  if (msg->content_length){
	      sprintf(fieldbuf, "Content-Type: %s\r\n", msg->content_type);
	      nbytes = strlen(fieldbuf);
	  }
	nextstate = SENDING_CONTENT_LENGTH;
	break;
      case SENDING_BLANK_LINE:
	sprintf(fieldbuf, "\r\n");
	nbytes = strlen(fieldbuf);
	if (msg->content_length) {
	  nextstate = SENDING_BODY;
	  bodyleft = msg->body;
	}
	else{
	  nextstate = SENDING_COMPLETE;
	}
	break;

      case SENDING_BODY:
	openspace = MAX_CHUNKLEN - chunklen - 1;
	nbytes = strlen(bodyleft);
	strncpy(fieldbuf, bodyleft, openspace);

	if (openspace >= nbytes) {           // remainder of body fits in this packet
	  bodyleft = NULL;
	  openspace = 0;
	  msg->sending_status = SENDING_COMPLETE;
	}
	else{
	  bodyleft += openspace;
	  nextstate = SENDING_BODY;
	  nbytes = openspace;
	}
	end_o_packet = 1;
	break;
      default:
	  nextstate = SENDING_BLANK_LINE;
	  nbytes = 0;   // eep, hack around
	break;
      }

      if ((chunklen + nbytes) < MAX_CHUNKLEN) { 
	chunklen += nbytes;
	strcat(chunkbuf, fieldbuf);
	msg->sending_status = nextstate;
      } 
      else{                  /* that's all that fits for now */
	  break;
      }
    }
    *pchunklen = chunklen;
  }


  void collate_incoming(uint8_t * chunkbuf, uint16_t chunklen)
  {
      static struct SIPMessage * inmsg;
      static uint8_t i;
      uint16_t chunkstart = 0;
    //Jamey// need separate inmsg pointers for client and server

      while(chunkstart < chunklen){
	  if (!inmsg) {
	      inmsg = call SIPMessagePool.alloc();
	      inmsg->parsing_status = EXPECTING_FIRST_LINE;
	      inmsg->sending_status = SENDING_IDLE;
	  }
	  chunkstart = parse_data(inmsg, chunkbuf, chunkstart, chunklen);
	  //    pas_data(inmsg, chunkbuf, chunklen);
	  if (inmsg->parsing_status == MESSAGE_COMPLETE) {
	      signal SIPMessage.received(inmsg);
	      
	      inmsg = NULL;
	      //Jamey// If message contains junk after content, then next chunk will be parsed as start of a message
	  }
      }
  }

  command result_t SIPMessage.listen(uint16_t listenport) {
    return call TCPServer.listen(listenport);
  }

  command result_t SIPMessage.connectionOpen(uint8_t remoteoctet1, 
					     uint8_t remoteoctet2, 
					     uint8_t remoteoctet3, 
					     uint8_t remoteoctet4,
					     uint16_t remoteport) {
    return call TCPClient.connect(remoteoctet1, remoteoctet2, remoteoctet3, remoteoctet4, remoteport);
  }

  command void SIPMessage.connectionClose() {
    call TCPClient.close();
  }

  command result_t SIPMessage.send(struct SIPMessage * msg) {
    // first chunk from here, the rest built/sent after writedone is signalled
      clientmsg = msg;
    sip_message_build_next_chunk(msg, chunkbuf_c, &chunklen_c);

    call TCPClient.write(chunkbuf_c, chunklen_c);

    return SUCCESS;
  }

  command result_t SIPMessage.respond(struct SIPMessage * msg) {
    // first chunk from here, the rest built/sent after writedone is signalled
      servermsg = msg;
      sip_message_build_next_chunk(msg, chunkbuf_s, &chunklen_s);

    if (server_token) {
      call TCPServer.write(server_token, chunkbuf_s, chunklen_s);
    }
    else
      return FAIL;

    return SUCCESS;
  }

  command void SIPMessage.resetListener() {
    call TCPServer.close(server_token);
    server_token = NULL;
    call TCPServer.listen(SIP_SERVER_PORT);
  }

  event void TCPClient.writeDone() {
    /*
     * after first build/send, we wait until each send has completed
     * before building and sending the rest of the message
     *
     * also, don't signal until the whole message is gone; 
     */
    if (clientmsg->sending_status != SENDING_IDLE) {
      sip_message_build_next_chunk(clientmsg, chunkbuf_c, &chunklen_c);
	
      call TCPClient.write(chunkbuf_c, chunklen_c);
      if (clientmsg->sending_status == SENDING_COMPLETE) {
	clientmsg->sending_status = SENDING_IDLE;

      }
    }
    else{
	// final write was done in a packet 
	clientmsg = NULL;
      signal SIPMessage.sendCompleted();
    }
  }

  event void TCPClient.connectionMade( uint8_t status ) {   // SUCCESS = made, FAIL = never connected
    signal SIPMessage.connected(status);
  }

  event void TCPClient.dataAvailable( uint8_t *buf, uint16_t len ) {
    //Jamey// Need separate inmsg for client transactions

      collate_incoming(buf, len);
  }

  event void TCPClient.connectionFailed( uint8_t reason ) {     // Reason = which end died
    signal SIPMessage.connectionFailed();
    call TCPClient.close();
  }

  // A child has connected.  Return a client token.
  event    void     TCPServer.connectionMade( void *token ) {
    server_token = token;
  }  

  event    void     TCPServer.writeDone( void *token ) {
    /*
     * after first build/send, we wait until each send has completed
     * before building and sending the rest of the message
     *
     * also, don't signal until the whole message is gone; 
     */
      if (servermsg->sending_status != SENDING_IDLE) {
	  sip_message_build_next_chunk(servermsg, chunkbuf_s, &chunklen_s);
	
	  call TCPServer.write(server_token, chunkbuf_s, chunklen_s);
	  if (servermsg->sending_status == SENDING_COMPLETE) {
	      servermsg->sending_status = SENDING_IDLE;
	
	  }
      }
      else{      // final write in a message
	  signal SIPMessage.sendCompleted();
      }
  }

  event    void     TCPServer.dataAvailable( void *token, uint8_t *buf, uint16_t len ) {
    //Jamey// Need separate inmsg for server transactions
      
    collate_incoming(buf, len);
  }

  // Reason = which end killed it
  event    void     TCPServer.connectionFailed( void *token, uint8_t reason ) {
    server_token = NULL;
  }  

}

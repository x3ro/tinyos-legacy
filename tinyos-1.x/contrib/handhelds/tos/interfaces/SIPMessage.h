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

#include "UIP_internal.h"

#ifndef NULL
#define NULL	0
#endif
#define SIP_REQUEST 0x4000
#define SIP_HEADER  0x2000

#define MAX_CHUNKLEN (UIP_TCP_MSS + 128)
#define MAX_BODY_LEN (UIP_TCP_MSS + 128)

#define SIP_SERVER_PORT 5060
#define SIP_CLIENT_PORT 5060

char abody[32];
char bbody[32];
char cbody[32];
char dbody[32];
char ebody[32];
char fbody[32];
char gbody[32];
char hbody[32];
char ibody[32];
char jbody[32];
char kbody[32];
char lbody[32];


enum sip_response {
    TRYING=100,
    RINGING=180,
    OK=200,
    BAD_REQUEST=400,
    FORBIDDEN=403,
    NOT_FOUND,
    METHOD_NOT_ALLOWED,
    REQUEST_TIMEOUT=408,
    SERVER_INTERNAL_ERROR=500,
    SERVICE_UNAVAILABLE=503,
    UNKNOWN
};

struct sip_response_info {
    enum sip_response response_code;
    char * response_str;
};
    
enum sip_token {
    SIP_UNKNOWN = 0,
    /* sip requests */
    SIP_INVITE = SIP_REQUEST | 1,
    SIP_CANCEL = SIP_REQUEST | 2,
    SIP_BYE    = SIP_REQUEST | 3,
    SIP_ACK    = SIP_REQUEST | 4,
    SIP_REGISTER = SIP_REQUEST | 5,
    SIP_MESSAGE = SIP_REQUEST | 6,
    /* sip response */
    SIP2       = 100,

    /* sip headers */
    SIP_CONTENT_TYPE_HEADER = 200,
    SIP_CONTENT_LENGTH_HEADER,
    SIP_CALLID_HEADER,
    SIP_CSEQ_HEADER,
    SIP_VIA_HEADER,
    SIP_TO_HEADER,
    SIP_FROM_HEADER,
    SIP_CONTACT_HEADER,
    SIP_SUBJECT_HEADER,
    SIP_USER_AGENT_HEADER,
    SIP_SERVER_HEADER,
    SIP_DATE_HEADER,
    SIP_WARNING_HEADER
};

struct sip_token_info {
    enum sip_token token;
    char *str;
}; 

enum sip_message_parsing_status {
    EXPECTING_FIRST_LINE = 0,
    EXPECTING_HEADER_LINE = 1,
    EXPECTING_BLANK_LINE = 2,
    EXPECTING_BODY_BYTE = 3,
    MESSAGE_COMPLETE = 4
};

enum sip_message_send_status {
    SENDING_IDLE = 0,
    SENDING_REQUEST_LINE,      // these two initial states
    SENDING_RESPONSE_LINE,     // these two initial states
    SENDING_VIAS,
    SENDING_FROM,
    SENDING_TO,
    SENDING_CSEQ,
    SENDING_CALLID,
    SENDING_CONTACT,
    SENDING_CONTENT_TYPE,
    SENDING_MAX_FORWARDS,
    SENDING_EXPIRES,
    SENDING_CONTENT_LENGTH,
    SENDING_BLANK_LINE,
    SENDING_BODY,
    SENDING_COMPLETE
};

enum sip_status {
    IDLE_STATE = 0,
    /* server states */
    INVITE_RECEIVED,
    INVITE_PROCEEDING, /* provisional response sent */
    INVITE_COMPLETED,  /* final response sent */
    INVITE_CONFIRMED,
    INVITE_TERMINATED,

    /* client states */
    INVITE_SENT,
    INVITE_PROVISIONAL_RECEIVED,
    INVITE_FINAL_RECEIVED,
    INVITE_ACK_SENT
};

struct sip_state {
    enum sip_status status;
    int message_pending;
    int cseq;
} sip_state;

enum {
    APPCALL_ACKDATA, /* outstanding data was acked and application can send new data */
    APPCALL_NEWDATA, /* new data. */
    APPCALL_ACK_NEWDATA, /* new data + ack */
    APPCALL_REXMIT, /* retransmit the data that was last sent. */
    APPCALL_POLL, /* Used for polling the application, to
		     check if the application has data that it wants to send. */
    APPCALL_CLOSE, /* remote has closed the connection, thus the connection has
		      gone away. Or the application signals that it wants to close the connection. */
    APPCALL_ABORT, /* remote has aborted the connection, thus the connection has
		      gone away. Or the application signals that it wants to abort the connection. */
    APPCALL_CONNECTED, /* connection from a remote host and have set up a new connection
			  for it, or an active connection has been successfully established. */ 
    APPCALL_TIMEDOUT, /* connection has been aborted due, too many retransmissions. */ 
    APPCALL_ACTIVE, /* Bluetooth link has become active */
    APPCALL_INTERFACE_UP,   /* Network interface active */
    APPCALL_HCI    /* HCI packet indication */
};

/* holds the request and the data for the response */
struct SIPMessage {
    char body[MAX_BODY_LEN];
    enum sip_message_parsing_status parsing_status;
    enum sip_message_send_status sending_status;
    enum sip_token request;
    char request_uri[128];
    int response_code;
    char response_str[48];
    int content_length;
    char content_type[32];
    int max_forwards;
    int expires;
    int cseq;
    char to[84];
    char from[84];
    char contact[128];
    char vias[128];
    char callid[64];
    struct SIPMessage * next;
};

/* 
 * inline code snippets from andy to support messagepool ops
 */
inline struct SIPMessage * pop_sipqueue( struct SIPMessage **head )
{
  struct SIPMessage *result = *head;
  if ( result != NULL )
    *head = (*head)->next;
  return result;
}

inline void push_sipqueue( struct SIPMessage **head, struct SIPMessage *item )
{
  item->next = *head;
  *head = item;
}

inline uint8_t count_sipqueue( struct SIPMessage *head )
{
  uint8_t count = 0;
  while ( head ) {
    count++;
    head = head->next;
  }
  return count;
}

inline void sipmsg_clear( struct SIPMessage *msg )
{
    msg->parsing_status = EXPECTING_FIRST_LINE;
    msg->sending_status = SENDING_IDLE;
    msg->request = SIP_UNKNOWN;
    memset(msg->request_uri, 0, 128);
    msg->response_code = SIP2;
    strcpy(msg->response_str, "SIP/2.0");
    msg->content_length = 0;
    memset(msg->content_type, 0, 32);
    msg->max_forwards = 10;
    msg->cseq = 0;
    memset(msg->to, 0, 84);
    memset(msg->from, 0, 84);
    memset(msg->contact, 0, 128);
    memset(msg->vias, 0, 128);
    memset(msg->callid, 0, 64);
    memset(msg->body, 0, MAX_BODY_LEN);
    msg->next = NULL;
};

  extern int sprintf(char *str, const char *format, ...) __attribute__((C));
  void seq_breadcrumbs(int seqnum, int data, char * buf)
  {
      switch(seqnum) {
      case 0:
	  snprintf(abody, 30, "%d %s", data, buf);
	  break;
      case 1:
	  snprintf(bbody, 30, "%d %s", data, buf);
	  break;
      case 2:
	  snprintf(cbody, 30, "%d %s", data, buf);
	  break;
      case 3:
	  snprintf(dbody, 30, "%d %s", data, buf);
	  break;
      case 4:
	  snprintf(ebody, 30, "%d %s", data, buf);
	  break;
      case 5:
	  snprintf(fbody, 30, "%d %s", data, buf);
	  break;
      case 6:
	  snprintf(gbody, 30, "%d %s", data, buf);
	  break;
      case 7:
	  snprintf(hbody, 30, "%d %s", data, buf);
	  break;
      case 8:
	  snprintf(ibody, 30, "%d %s", data, buf);
	  break;
      case 9:
	  snprintf(jbody, 30, "%d %s", data, buf);
	  break;
      case 10:
	  snprintf(kbody, 30, "%d %s", data, buf);
	  break;
      case 11:
	  snprintf(lbody, 30, "%d %s", data, buf);
	  break;
      default:
	  break;
      }
  }



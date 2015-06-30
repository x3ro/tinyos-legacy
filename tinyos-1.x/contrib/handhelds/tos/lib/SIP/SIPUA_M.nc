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
 * Authors:  Steve Ayer
 *           Feb-March 2005
 */


includes Message;
includes SIPMessage;

module SIPUA_M {
    provides {
	interface SIPUA;
	interface StdControl;
    }
    uses {
	interface StdControl as IPStdControl;
	interface StdControl as SIPTransactionStdControl;
	interface StdControl as SIPMessageStdControl;
	interface UIP;
	interface SIPMessagePool;
	interface SIPTransaction;
	interface Timer as RegistrationTimer;
	interface Leds;
	interface Client;
    }
}

implementation {

    extern int sprintf(char *str, const char *format, ...) __attribute__((C));
    uint16_t callid_u, callid_l, tag_u, tag_l, branch;

    enum registrationStatus {
	REGISTRATION_PENDING,
	REGISTERED,
        NOT_REGISTERED
    } registrationState;
    enum sessionStatus {
	NO_SESSION,
	INVITE_SENT,
	INVITE_PENDING,
	INVITE_OK,
        IN_SESSION
    } sessionState;

    const struct sip_response_info sip_responses[] = {
	{TRYING, "TRYING"},
	{RINGING, "RINGING"},
	{OK, "OK"},
	{BAD_REQUEST, "BAD REQUEST"},
	{FORBIDDEN, "FORBIDDEN"},
	{NOT_FOUND, "NOT FOUND"},
	{METHOD_NOT_ALLOWED, "METHOD NOT ALLOWED"},
	{REQUEST_TIMEOUT, "REQUEST TIMEOUT"},
	{SERVER_INTERNAL_ERROR, "SERVER INTERNAL ERROR"},
	{SERVICE_UNAVAILABLE, "SERVICE UNAVAILABLE"},
	{UNKNOWN, "UNKNOWN"}
    };

#define EXPIRATION 900

    void doRegistration(struct SIPMessage * msg) {

	callid_u = rand();  // two pieces of a 32-bit item
	callid_l = rand();
	tag_u = rand();       
	tag_l = rand();       
	branch = rand();

	msg->sending_status = SENDING_REQUEST_LINE;
	msg->request = SIP_REGISTER;

	strcpy(msg->request_uri, "sip:sip.crl.hpl.hp.com");
	sprintf(msg->vias, "16.11.5.200:%d;branch=z9hG4bK%x", SIP_CLIENT_PORT, branch);
	strcpy(msg->to, "<sip:ayer@sip.crl.hpl.hp.com>");
	sprintf(msg->from, "<sip:ayer@sip.crl.hpl.hp.com>;tag=%x", tag_u);
	sprintf(msg->callid, "%x%x@16.11.5.200",callid_u, callid_l);
	msg->content_length = 0;
	msg->cseq = 0;
	msg->max_forwards = 10;
	msg->expires = EXPIRATION;
	//	sprintf(msg->contact, "<sip:ayer@16.11.5.200:%d>", SIP_CLIENT_PORT);
	strcpy(msg->contact, "<sip:ayer@16.11.5.200>");

	registrationState = REGISTRATION_PENDING;

	call SIPTransaction.sendRequest(msg);
    }

    void doInvite(struct SIPMessage * msg)
    {
	callid_u = rand();  // two pieces of a 32-bit item
	callid_l = rand();
	tag_u = rand();       
	tag_l = rand();       
	branch = rand();

	msg->sending_status = SENDING_REQUEST_LINE;
	msg->request = SIP_INVITE;
	/*  call kphone on bleed *
	strcpy(msg->request_uri, "sip:bleed.crl.hpl.hp.com");
	sprintf(msg->vias, "16.11.0.100;branch=z9hG4bK%x", branch);
	strcpy(msg->to, "<sip:steve.ayer@bleed.crl.hpl.hp.com>");
	*/
	/*  call steve.ayer at cisco */
	strcpy(msg->request_uri, "sip:steven.ayer@16.11.100.211");
	sprintf(msg->vias, "16.11.5.200;branch=z9hG4bK%x", branch);
	strcpy(msg->to, "<sip:steven.ayer@16.11.100.211>");

	sprintf(msg->from, "<sip:ayer@16.11.5.200>;tag=%x", tag_u);
	sprintf(msg->callid, "%x%x",callid_u, callid_l);
	strcpy(msg->content_type, "application/sdp");
	strcpy(msg->body, "v=0\r\n\
o=ayer 0 0 IN IP4 16.11.5.200\r\n\
s=Tiny SIP\r\n\
c=IN IP4 16.11.5.200\r\n\
t=0 0\r\n\
m=audio 33040 RTP/AVP 0 97 3\r\n\
a=rtpmap:0 PCMU/8000\r\n\
a=rtpmap:3 GSM/8000\r\n\
a=rtpmap:97 iLBC/8000\r\n");


/*
m=data 5061 udp wb\r\n\r\n");
*/
	msg->content_length = strlen(msg->body);
	msg->cseq = 10;
	strcpy(msg->contact, "<sip:ayer@16.11.5.200>");

	call SIPTransaction.sendRequest(msg);
    }

    void doMessage(struct SIPMessage * msg, char * body)
    {
	callid_u = rand();  // two pieces of a 32-bit item
	callid_l = rand();
	tag_u = rand();       
	tag_l = rand();       
	branch = rand();

	// try a message
	strcat(body, "\r\n");

	msg->sending_status = SENDING_REQUEST_LINE;
	msg->request = SIP_MESSAGE;

	strcpy(msg->request_uri, "sip:bleed.crl.hpl.hp.com");
	sprintf(msg->vias, "16.11.0.100:%d;branch=z9hG4bK%x", SIP_CLIENT_PORT, branch);
	//sprintf(msg->from, "<sip:ayer@sip.crl.hpl.hp.com>;tag=%x", tag_u);
	sprintf(msg->from, "<sip:ayer@16.11.5.200>;tag=%x", tag_u);
	strcpy(msg->to, "<sip:steve.ayer@bleed.crl.hpl.hp.com>");
	sprintf(msg->callid, "MESSAGE-%x%x@16.11.5.200",callid_u, callid_l);
	msg->content_length = strlen(body);
	strcpy(msg->content_type, "text/plain");
	strcpy(msg->body, body);
	msg->cseq = 10;

	call SIPTransaction.sendRequest(msg);
    }

    command struct SIPMessage * SIPUA.sample_registration() {
	struct SIPMessage * msg;
	msg = call SIPMessagePool.alloc();
	
 	doRegistration(msg);

	return NULL;
    }

    command struct SIPMessage * SIPUA.sample_invite() {
	struct SIPMessage * msg;
	msg = call SIPMessagePool.alloc();

	sessionState = INVITE_SENT;

 	doInvite(msg);

	return NULL;
    }

    command struct SIPMessage * SIPUA.sample_instantmessage(char * textmessage) {
	struct SIPMessage * msg;

	msg = call SIPMessagePool.alloc();
	
	doMessage(msg, textmessage);

	return NULL;
    }

    bool supportedRequest(struct SIPMessage * msg) {
	if((msg->request != SIP_UNKNOWN))// && (msg->request <= SIP_MESSAGE))
	    return TRUE;

	return FALSE;
    }

    char * lookup_response_code(enum sip_response response_code) {
	uint8_t i = 0;
	
	while(sip_responses[i].response_code != UNKNOWN){
	    if(response_code == sip_responses[i].response_code)
		break;
	    i++;
	}
	return sip_responses[i].response_str;
    }

    struct SIPMessage * build_response(struct SIPMessage * msg, enum sip_response response_code) {
	struct SIPMessage * rmsg;
	uint8_t tagbuf[30], *scout, *oldscout;
	
	rmsg = call SIPMessagePool.alloc();

	rmsg->response_code = response_code;
	strcpy(rmsg->response_str, lookup_response_code(response_code));
	rmsg->sending_status = SENDING_RESPONSE_LINE;
	rmsg->request = msg->request;

	// copy stuff that must match
	strcpy(rmsg->from, msg->from);
	strcpy(rmsg->callid, msg->callid);
	rmsg->cseq = msg->cseq;
	// try snipping off "Via: 
	strcpy(rmsg->vias, (msg->vias + strlen(" Via: SIP/2.0/TCP")));
	// then we have to snip off the last blank line or recipient will think eot
	oldscout = rmsg->vias;
	while((scout = strstr(oldscout+2, "\r\n")))
	    oldscout = scout;
	if(oldscout)
	    *oldscout = 0;
	strcpy(rmsg->to, msg->to);
	if(!strstr(rmsg->to, "tag=")){
	    if((scout = strstr(rmsg->to, "\r\n")))
		*scout = 0;
	    tag_u = rand(); tag_l = rand();
	    sprintf(tagbuf, ";tag=%x\r\n", tag_u);
	    strcat(rmsg->to, tagbuf);
	}

	strcpy(rmsg->contact, msg->contact);
	if(msg->request == SIP_INVITE){
	    strcpy(rmsg->content_type, msg->content_type);
	    strcpy(rmsg->body, msg->body);
	    rmsg->content_length = msg->content_length;  //strlen(rmsg->body);
	}
	return rmsg;
    }	
		
    struct SIPMessage * build_ack(struct SIPMessage * msg) { 
	struct SIPMessage * rmsg;
	
	rmsg = call SIPMessagePool.alloc();

	rmsg->request = SIP_ACK;
	rmsg->sending_status = SENDING_REQUEST_LINE;

	strcpy(rmsg->request_uri, "sip:bleed.crl.hpl.hp.com");
	sprintf(rmsg->vias, "16.11.0.100;branch=z9hG4bK%x", branch);   // this should be dup of original via

	// copy stuff that must match
	strcpy(rmsg->from, msg->from);
	strcpy(rmsg->to, msg->to);
	strcpy(rmsg->callid, msg->callid);
	rmsg->cseq = msg->cseq;
	strcpy(rmsg->to, msg->to);
	rmsg->content_length = 0;
	strcpy(rmsg->contact, msg->contact);

	return rmsg;
    }	
		
    event void SIPTransaction.receivedRequest(struct SIPMessage * msg) {
	uint16_t response_code;
	struct SIPMessage * rmsg;

	if(!supportedRequest(msg))
	    response_code = METHOD_NOT_ALLOWED;
	else
	    response_code = OK;
	
	if(msg->request == SIP_INVITE)
	    sessionState = INVITE_OK;

	rmsg = build_response(msg, response_code);
	//	signal SIPUA.receivedRequest(msg);
	call SIPMessagePool.free(msg);
	call SIPTransaction.sendResponse(rmsg);
    }

    event void SIPTransaction.receivedResponse(struct SIPMessage * msg) {
	struct SIPMessage * rmsg;
	static uint8_t i;
	//	sprintf(cbody, "state %d response%d=%d", sessionState, i++,msg->response_code);

	if((registrationState == REGISTRATION_PENDING) && (msg->response_code == 200)) {
	    registrationState = REGISTERED;
	    call RegistrationTimer.start(TIMER_REPEAT, 250);
	}
	else if((sessionState == INVITE_SENT) || (sessionState == INVITE_PENDING) ){
	    if(msg->response_code == 200){     // server ok'd our invite
		seq_breadcrumbs(i++, msg->response_code, msg->response_str);
		rmsg = build_ack(msg);
		seq_breadcrumbs(i++, rmsg->request, rmsg->request_uri);
		sessionState = IN_SESSION;
		call SIPMessagePool.free(msg);
		
		call SIPTransaction.sendRequest(rmsg);
	    }
	    else if((msg->response_code == 100) || (msg->response_code == 180)){     // server trying/ringing
		seq_breadcrumbs(i++, msg->response_code, msg->response_str);
		sessionState = INVITE_PENDING;
		call SIPMessagePool.free(msg);
	    }
	}
	else if(sessionState == INVITE_OK){  // we sent the ok, this is client's ack
	    sessionState = IN_SESSION;
	    call SIPMessagePool.free(msg);
	}
    }    

    event void SIPTransaction.timeout() {
	
    }    

    command result_t StdControl.init() {
	registrationState = NOT_REGISTERED;
	sessionState = NO_SESSION;

 	call Leds.init();

	//	call IPStdControl.init();
	call SIPMessageStdControl.init();
	call SIPTransactionStdControl.init();
	return SUCCESS;
    }

    command result_t StdControl.start() {
	//	call IPStdControl.start();
	//	call UIP.init(IP);
	call SIPMessageStdControl.start();
	call SIPTransactionStdControl.start();
	call SIPTransaction.ipSetup(REGISTRAR_IP);

	call Leds.set(0);

	//	post sample_transactions();

	return SUCCESS;
    }

    command result_t StdControl.stop() {
	//	call IPStdControl.stop();
	return SUCCESS;
    }

    event result_t RegistrationTimer.fired(){
	static uint16_t q;
	struct SIPMessage * msg;

	q++;
	if(!(q % (EXPIRATION * 4))){       // fires every .25s, so...
	    if(registrationState == REGISTERED){
		msg = call SIPMessagePool.alloc();
		doRegistration(msg);
		registrationState = NOT_REGISTERED;
		call SIPMessagePool.free(msg);
		call RegistrationTimer.stop();
	    }
	}
	return SUCCESS;
    }

    event void Client.connected( bool isConnected ) {
	if ( isConnected ) {
	    ;
	    //	    post sample_transactions();    
	}
    }
}

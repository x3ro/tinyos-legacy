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

includes SIPMessage;

module SIPTransactionM {
    provides {
	interface SIPTransaction;
	interface StdControl;
    }
    uses {
	interface Timer as TransactionTimer;
	interface SIPMessage;
	interface SIPMessagePool;
	interface Leds;
    }
}
implementation {

    extern int sprintf(char *str, const char *format, ...) __attribute__((C));

    uint8_t remoteoctet1, remoteoctet2, remoteoctet3, remoteoctet4;

    struct SIPMessage * ctransmsg;    // client-side
    struct SIPMessage * stransmsg;    // server-side

    enum connectionStatus  {
	CONNECTED,
	DISCONNECTED
    }clientConnectionState;

    enum transactionStatus  {
	IDLE,
	AWAITING_CONNECTION,
	SENT_NI_REQUEST,
	SENT_NI_RESPONSE,
	RECEIVED_NI_REQUEST,
	AWAITING_NI_RESPONSE,
	SENT_I_REQUEST,
	SENT_I_RESPONSE,
	RECEIVED_I_REQUEST,
	RECEIVED_I_RESPONSE,
	AWAITING_I_RESPONSE,
	SENT_ACK,
	AWAITING_ACK
    } transactionState;
    /*
    enum transactionStatus  {
	IDLE,
	AWAITING_CONNECTION,
	REQUEST_PENDING,
	INVITE_PENDING,
	AWAITING_RESPONSE,
	AWAITING_INVITE_RESPONSE,
	RESPONSE_PENDING,
	INVITE_RESPONSE_PENDING
    } transactionState;
    */
    command result_t StdControl.init() {
	clientConnectionState = DISCONNECTED;
	transactionState = IDLE;

	return SUCCESS;
    }	

    command result_t StdControl.start() {
	return SUCCESS;
    }	

    command result_t StdControl.stop() {
	call TransactionTimer.stop();

	return SUCCESS;
    }

    command result_t SIPTransaction.ipSetup(uint8_t roctet1, uint8_t roctet2, uint8_t roctet3, uint8_t roctet4) {
	remoteoctet1 = roctet1;
	remoteoctet2 = roctet2;
	remoteoctet3 = roctet3;
	remoteoctet4 = roctet4;

	return SUCCESS;
    }

    /*
    command void SIPTransaction.resetState(transactionStatus ts) {
	transactionState = ts;
    }
    */
    command result_t SIPTransaction.sendRequest(struct SIPMessage * msg){
	if(!ctransmsg)
	    ctransmsg = msg;
	
	if(clientConnectionState == DISCONNECTED){
	    call SIPMessage.connectionOpen(remoteoctet1, 
					   remoteoctet2, 
					   remoteoctet3, 
					   remoteoctet4, 
					   SIP_CLIENT_PORT);
	    transactionState = AWAITING_CONNECTION;
	}
	else{
	    if(msg->request == SIP_INVITE)
		transactionState = SENT_I_REQUEST;
	    else if(msg->request == SIP_ACK)
		transactionState = SENT_ACK;
	    else
		transactionState = SENT_NI_REQUEST;
	    call SIPMessage.send(msg);
	}
	return SUCCESS;
    }
    
    // this one goes out on tcp server
    command result_t SIPTransaction.sendResponse(struct SIPMessage * msg){
	if(!stransmsg)
	    stransmsg = msg;
	
	if(transactionState == RECEIVED_NI_REQUEST)
	    transactionState = SENT_NI_RESPONSE;
	else if(transactionState == RECEIVED_I_REQUEST)
	    transactionState = SENT_I_RESPONSE;

	call SIPMessage.respond(msg);

	return SUCCESS;
    }
    
    event result_t TransactionTimer.fired(){
	static uint16_t q;

	q++;
	if(!(q % 16)){  // fires every .25s, so 4s
	    call TransactionTimer.stop();
	    if((transactionState == AWAITING_I_RESPONSE) || 
	       (transactionState == AWAITING_NI_RESPONSE)) {
		signal SIPTransaction.timeout();
		clientConnectionState = DISCONNECTED;
		call SIPMessage.connectionClose();
	    }
	}
	return SUCCESS;
    }

    // assume client-side event only happens when we're trying to initiate a request
    event void SIPMessage.connected(uint8_t status){
	if(status == SUCCESS){
	    clientConnectionState = CONNECTED;

	    if(transactionState == AWAITING_CONNECTION){
		call SIPTransaction.sendRequest(ctransmsg);   
	    }
	}
	else
	    clientConnectionState = DISCONNECTED;
    }

    event void SIPMessage.connectionFailed(){
	atomic clientConnectionState = DISCONNECTED;
    }

    // could be either client- or server-side
    event void SIPMessage.sendCompleted() {
	switch(transactionState) {
	case SENT_NI_REQUEST:
	    call SIPMessagePool.free(ctransmsg);
	    ctransmsg = NULL;
	    transactionState = AWAITING_NI_RESPONSE;
	    break;
	case SENT_I_REQUEST:
	    transactionState = AWAITING_I_RESPONSE;
	    call SIPMessagePool.free(ctransmsg);
	    ctransmsg = NULL;
	    break;
	case SENT_NI_RESPONSE:
	    call SIPMessagePool.free(stransmsg);
	    stransmsg = NULL;
	    transactionState = IDLE;
	    call SIPMessage.resetListener();
	    break;
	case SENT_I_RESPONSE:
	    call SIPMessagePool.free(stransmsg);
	    stransmsg = NULL;
	    transactionState = AWAITING_ACK;	
	    break;
	case SENT_ACK:
	    transactionState = IDLE;
	    call SIPMessagePool.free(ctransmsg);
	    ctransmsg = NULL;
	    break;
	default:
	    break;
	}
    }

    event void SIPMessage.received(struct SIPMessage * msg) {
	static uint8_t i;
	//	    sprintf(bbody, "state %d response%d=%d", transactionState, i++,msg->response_code);
	switch(transactionState) {
	case IDLE:
	    if(msg->request & SIP_REQUEST){
		if(msg->request == SIP_INVITE)
		    transactionState = RECEIVED_I_REQUEST;
		else
		    transactionState = RECEIVED_NI_REQUEST;
		signal SIPTransaction.receivedRequest(msg);
	    }
	    break;
	case AWAITING_NI_RESPONSE:
	    transactionState = IDLE;
	    signal SIPTransaction.receivedResponse(msg);
	    clientConnectionState = DISCONNECTED;
 	    call SIPMessage.connectionClose();
	    break;
 	case AWAITING_I_RESPONSE:         // either an ok or trying/ringing
 	case RECEIVED_I_RESPONSE:
	    transactionState = RECEIVED_I_RESPONSE;
	    signal SIPTransaction.receivedResponse(msg);
	    break;
	case AWAITING_ACK:
	    transactionState = IDLE;
	    signal SIPTransaction.receivedResponse(msg);
	    break;
	default:
	    break;
	}
    }
}    

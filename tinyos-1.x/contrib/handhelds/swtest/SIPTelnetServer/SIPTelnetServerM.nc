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
 * Authors:  Steve Ayer
 *           Feb-March 2005
 */

includes SIPMessage;
includes Message;
includes NVTParse;

module SIPTelnetServerM {
    provides{
	interface StdControl;
	interface ParamView;
    }

    uses {
	interface StdControl as IPStdControl;
	interface StdControl as TelnetStdControl;
	interface StdControl as PVStdControl;

	interface StdControl as SIPStdControl;

	// for telnet to paramview goodies
	interface UIP;
	interface Client;

	interface Telnet as TelnetRun;

	//	interface TCPServer;

	interface SIPUA;

	interface Leds;
	interface SIPTransaction;
	interface NTPClient;
    }
}

implementation {
    extern int sprintf(char *str, const char *format, ...) __attribute__ ((C));
    extern int snprintf(char *str, size_t len, const char *format, ...) __attribute__ ((C));

#define MAX_BODY_BYTES 192  // don't need to include SIPMessage.h for just this

    uint32_t curr_time;
    char msgbuf[MAX_BODY_BYTES];

    enum {
	IN_BUFFER_LENGTH  = 60,
	OUT_BUFFER_LENGTH = 300
    };

    struct ScratchBuffer {
	uint8_t in[ IN_BUFFER_LENGTH ];
	int in_length;      // How many bytes are in the input buffer

	uint8_t out[ OUT_BUFFER_LENGTH ];
	int out_length;     // How many bytes are in the output buffer
	int write_length;   // Last write request length
    };

    struct ScratchBuffer g_buf;
    struct ParamList *g_paramlist = NULL;


    /*****************************************
     *  StdControl interface
     *****************************************/

    command result_t StdControl.init() {
	call PVStdControl.init();
	call SIPStdControl.init();
	call IPStdControl.init();
	
	call Leds.init();

	return call TelnetStdControl.init();
    }

    command result_t StdControl.start() {
	call IPStdControl.start();
	call SIPStdControl.start();
	call TelnetStdControl.start();

	return SUCCESS;
    }

    command result_t StdControl.stop() {
	call TelnetStdControl.stop();
	call SIPStdControl.stop();
	return call IPStdControl.stop();
    }

    struct TelnetCommand {
	char *name;
	char * (*func)( char *, char *, char * );
    };

    char * do_invite(char * in, char * out, char * outmax) { 
	call SIPUA.sample_invite();

	strcpy(msgbuf, "sent invite request");
	return out;
    }

    char * do_registration(char * in, char * out, char * outmax) { 
	call SIPUA.sample_registration();

	strcpy(msgbuf, "sent registration request");
	return out;
    }

#define MAX_IMSIZE 40

    char * do_instantmessage(char * in, char * out, char * outmax) { 
	uint8_t sbuf[MAX_IMSIZE + 1];

	strncpy(sbuf, in, MAX_IMSIZE);
	*(sbuf + MAX_IMSIZE) = 0;
     
	call SIPUA.sample_instantmessage(sbuf);
	sprintf(msgbuf, "sent IM %s", in);

	return out;
    }

    const struct TelnetCommand sip_commands[] = {
	{ "invite", &do_invite },
	{ "register", &do_registration },
	{ "IM", &do_instantmessage },
	{ 0, NULL }
    };


    event void Client.connected( bool isConnected ) {
	///      if( isConnected );
	//	  blat_spurious_msg("got connect");
    }

    event void NTPClient.timestampReceived( uint32_t *seconds, uint32_t *fraction ) {
	static uint8_t seeded = 0;
	char t[20];
      
	if(seeded == 0){
	    atomic  curr_time = *fraction;
	  
	    //	  srand((uint16_t)(curr_time & 0x0000ffffU));
	    srand((uint16_t)curr_time);
	  
	    seeded = 1;
	}
	sprintf(t, "seed is %u", (uint16_t)curr_time);// & 0x0000ffffU));
	//	blat_spurious_msg(t);
    }
  
    event void SIPTransaction.receivedRequest(struct SIPMessage * msg) {
    }

    event void SIPUA.receivedRequest(struct SIPMessage * msg) {
	if(msg->content_length){
	    strcpy(msgbuf, msg->body);//, MAX_BODY_BYTES - 1);
	    msgbuf[msg->content_length] = 0;
	    //	    sprintf(msgbuf, "%s %d\r\n", msg->body, msg->content_length);
	}
    } 

    event void SIPTransaction.receivedResponse(struct SIPMessage * msg) {
	if((msg->request == SIP2) && (msg->response_code == 200))
	    strcpy(msgbuf, "received OK response");
	else
	    strcpy(msgbuf, "received weird response");
    }
    
    event void SIPTransaction.timeout() {
	strcpy(msgbuf, "tcp client connection failed");
    }

    /**** modern param view stuff ****/
    const struct Param s_foo[] = {
	//	{ "msgs",  PARAM_TYPE_STRING, &msgbuf[0] },
	{ "body1",  PARAM_TYPE_STRING, &abody[0] },
	{ "body2",  PARAM_TYPE_STRING, &bbody[0] },
	{ "body3",  PARAM_TYPE_STRING, &cbody[0] },
	{ "body4",  PARAM_TYPE_STRING, &dbody[0] },
	{ "body5",  PARAM_TYPE_STRING, &ebody[0] },
	{ "body6",  PARAM_TYPE_STRING, &fbody[0] },
	{ NULL, 0, NULL }
    };
    struct ParamList g_myList = { "msgs", &s_foo[0] };
    const struct Param s_bar[] = {
	{ "body7",  PARAM_TYPE_STRING, &gbody[0] },
	{ "body8",  PARAM_TYPE_STRING, &hbody[0] },
	{ "body9",  PARAM_TYPE_STRING, &ibody[0] },
	{ "body10",  PARAM_TYPE_STRING, &jbody[0] },
	{ "body11",  PARAM_TYPE_STRING, &kbody[0] },
	{ "body12",  PARAM_TYPE_STRING, &lbody[0] },
	{ NULL, 0, NULL }
    };
    struct ParamList g_myLister = { "else", &s_bar[0] };

    command result_t ParamView.init()
    {
	signal ParamView.add( &g_myList );
	signal ParamView.add( &g_myLister );
	return SUCCESS;
    }
    event const char * TelnetRun.token() { return "run"; }
    event const char * TelnetRun.help() { return "Run SIP methods\r\n"; }
    
    /**** telnet command handling stuff ******/
    event char * TelnetRun.process( char * in, char * out, char * outmax ) {
	char * next, * extrastuff;
	char * cmd = next_token(in, &next, ' ');

	if(cmd) {
	    const struct TelnetCommand *c = sip_commands;
      
	    for ( ;c->name; c++) {
		if (strcmp(cmd, c->name) == 0) {
		    if ((extrastuff = (*c->func)( next, out, outmax ))) { 
			out += snprintf(out, outmax - out, "%s\r\n", extrastuff);
			break;
		    }
		}
	    }
	}
	else
	    out += snprintf(out, outmax - out, "must provide command with 'run'\r\n");
	    
	return out;
    }

}

/*
 * Copyright (c) 2009 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Ricardo Simon Carbajo <carbajor {tcd.ie}>
 * @date   February 13 2009 
 * Computer Science
 * Trinity College Dublin
 */
 
/****************************************************************/
/* Demo application on how to use the TinyHop routing layer     */
/*															    */
/* TinyHop:														*/
/* An end-to-end on-demand reliable ad hoc routing protocol		*/
/* for Wireless Sensor Networks intended for P2P communication	*/
/* See: http://portal.acm.org/citation.cfm?id=1435467.1435469   */
/*--------------------------------------------------------------*/
/* This version has been tested with TinyOS 2.1.0 and 2.1.1     */
/****************************************************************/

module TinyHopTestM {
  uses {
	interface Boot;
	interface SplitControl as RadioControl;
    interface AMSend as Send;
    interface Receive; 
    interface AMPacket;
	interface Timer<TMilli>;
	interface Random;
	interface Leds;
    
  }
}

implementation {

  //CONFIGURE ORIGIN AND DETINATION FOR THE ROUTE 
  am_addr_t ORIGIN = 0x1;
  am_addr_t DESTINATION = 0xA;   //Node 10 = 0xA
								 //Node 32 = 0x20
								 //Node 64 = 0x40
								 //Node 128 = 0x80

  enum{
	MAX_SEQUENCE=65535
  };

  message_t Msg;
  uint16_t seqControl;	

  /***********************************************************************
   * Tasks 
   ***********************************************************************/
    
  task void SendData() {
	 am_addr_t addr;
	 TOS_TinyHopTestMsg* pTinyHopTestMsg = (TOS_TinyHopTestMsg *) call Send.getPayload(&Msg, sizeof(TOS_TinyHopTestMsg));

	 pTinyHopTestMsg->seqControl=seqControl;
	 pTinyHopTestMsg->type=TEMPERATURE;
	 pTinyHopTestMsg->reading=0x0045;
	 
	 addr=DESTINATION;
	
	 dbg("TinyHopTest", "USER APPLICATION: Sending Packet to %hu with seqControl=%hhu & type=%hu & reading=%hu @ %hu  \n", addr, pTinyHopTestMsg->seqControl, pTinyHopTestMsg->type, pTinyHopTestMsg->reading, call Timer.getNow());
  
	 if (call Send.send(addr, &Msg, sizeof(TOS_TinyHopTestMsg))== SUCCESS){
		seqControl++;
		seqControl %= MAX_SEQUENCE;
		call Leds.led1Toggle(); 
	 }
	 else{
		dbg("TinyHopTest", "USER APPLICATION: ERROR @ TinyHopM in Sending ........... \n");	
	 }
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/

  event void Boot.booted() {
	call RadioControl.start();
  } 
   
  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
		seqControl=0;
		if (TOS_NODE_ID == ORIGIN){
			call Timer.startOneShot(5000);
		}
    }
    else {
		call RadioControl.start();
    }
  }

  event void RadioControl.stopDone(error_t err) {
  		call RadioControl.start();
  }
  

  event void Timer.fired() {
	dbg_clear("TinyHopTest", "\n");
	dbg("TinyHopTest", "USER APPLICATION: Timer fired Time Now: %u \n",call Timer.getNow());
	post SendData();

	if (TOS_NODE_ID == ORIGIN){
		call Timer.startOneShot(5000);
	}
  }
  
  event void Send.sendDone(message_t* msg, error_t error) {
	if (error == FAIL){
		dbg("TinyHopTest", "USER APPLICATION: SendDone FAIL//////////////////////////////// \n");	
		seqControl--;
	}
	
  }
  
  event message_t* Receive.receive(message_t* msg, void *payload, uint8_t len) {
	TOS_TinyHopTestMsg* pTinyHopTestMsg = (TOS_TinyHopTestMsg *) call Send.getPayload(msg, len);

	dbg("TinyHopTest", "USER APPLICATION:  RECEIVING -> Receiving packet with seqControl=%hu & type=%hu  & reading=%hu @ %u \n", pTinyHopTestMsg->seqControl, pTinyHopTestMsg->type, pTinyHopTestMsg->reading, call Timer.getNow());
    
	return msg;
  }
 
}

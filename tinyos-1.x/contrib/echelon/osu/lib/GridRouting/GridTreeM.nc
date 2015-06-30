/**
 * Copyright (c) 2003 - The University of Texas at Austin and
 *                      The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE
 * UNIVERSITY BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL,
 * INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS
 * SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF TEXAS AT AUSTIN
 * AND THE OHIO STATE UNIVERSITY HAVE BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE UNIVERSITY
 * SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND
 * THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE UNIVERSITY HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */

/*
 *  Author/Contact: Young-ri Choi
 *                  yrchoi@cs.utexas.edu
 */

// Vis codes deleted

includes GridTreeMsg; 

#ifndef DeadThreshold
#define DeadThreshold 3
#endif

module GridTreeM { 
    provides{
		interface StdControl;
		interface GridInfo;
		interface BroadcastingNP;
	}
    uses {
      interface Leds;
      interface ReceiveMsg as ReceiveGTMsg;
      interface SendMsg as SendGTMsg;
      interface StdControl as CommControl;
      interface Timer;

      interface Random;
	  interface Neighborhood;
    }
}

/* 
 *  Module Implementation
 */

implementation 
{

enum{

/*
#ifdef CASE_22
	N=11,					// it should be 11 for case ONE!
#else
	N=21,					// it should be 21 for April Demo!
#endif
*/

	PARENT_DEAD_COUNT=120, //60,	// R in the document

	CONNECTED=0,
	CONNECTED_PIGGYBACK=3,

	CONNECTED_INTERVAL_COUNT=20,		// should be > 1
	CONNECTED_INTERVAL=1000, 			// 1 sec
	MOD_NUM=11,		// to pick number in [15..25] for connected msgs
	SUBT_NUM=5,

	SPEEDUP_INTERVAL_COUNT=5,
	MOD_NUM_SP=7,		// to pick number in [2..8] for connected msgs
	SUBT_NUM_SP=3,

	//LIMIT_FREQ=0,	// no limit frequency 
	LIMIT_FREQ=60,	// to limit frequency for ReliableComm

	DIST=20
};

  gpoint myID;
  gpoint parentID;
  int8_t distance;	// for new grid routing
  //int8_t myLevel;
  //int8_t hasParent;		
  int8_t curGate;	// 0 -> np? 1 -> primary 2 -> secondary stargate
  int8_t basestation;	// 0-> nonbase 1-> base
  int8_t cconnected;

  int8_t myPBid,mySBid; // my primary or secondary base station ID
  int8_t myBid;			// my current base station ID

  int8_t pending;
  TOS_Msg inMsgBuf,outMsgBuf;
  int8_t remain;

  int8_t tickCount;

  uint8_t limitFlag;	// limit parent chaning frequency
  uint16_t limitCount;

  // inHandle for inMsgBuf (connected)
  int8_t inHandle;
  int8_t pendingDeadCount;

  // BroadcastingNP
  uint8_t version;
  netParam nplist;
  int8_t verFlag;

  // To support ReliableComm
  int8_t baseChild;

/* ---------------------------------------------------------*/

  task void sendConnected(){
 	ConnectedMsg *msg = (ConnectedMsg *)outMsgBuf.data;

   /* send connected only when remain > 0 or I am a base station! */
   if(!pending && (remain>0 || basestation)){
		atomic{
	    pending = TRUE;
		msg->id.x = myID.x;			
		msg->id.y = myID.y;
		msg->version1 = version;
		msg->version2 = version;
		//msg->pid.x = parentID.x;	//check
		//msg->pid.y = parentID.y;
		msg->bid= myBid;
		}

		//BroadcastingNP
		if(verFlag == 1){	// piggyback network parameters
			msg->type = CONNECTED_PIGGYBACK;
			memcpy((void*)&msg->nplist, (const void*)&nplist, sizeof(netParam));

			if(call SendGTMsg.send(TOS_BCAST_ADDR, sizeof(ConnectedMsg), &outMsgBuf)){
				call Leds.yellowToggle();

				//test
				//if(baseChild) call Leds.greenToggle();

				dbg(DBG_USR2, "I (%d, %d) send Connected with v=%d and np.type=%d\n", myID.x, myID.y,version,nplist.type);
				verFlag=0;
			}
			else{ 
				atomic{
		   		pending=FALSE;
				pendingDeadCount=0;
				}
		 	}
		}
		else{	// verFlag==0
			msg->type = CONNECTED;
			if(call SendGTMsg.send(TOS_BCAST_ADDR, sizeof(ConnectedMsg)-sizeof(netParam), &outMsgBuf)){
				call Leds.yellowToggle();

				//test
				//if(baseChild) call Leds.greenToggle();

				dbg(DBG_USR2, "I (%d, %d) send Connected with v=%d\n", myID.x, myID.y,version);
			}
			else{ 
				atomic{
		   		pending=FALSE;
				pendingDeadCount=0;
				}
		 	}
		}
    }
	else{ 

		if(pending){
			pendingDeadCount++;
			if (pendingDeadCount > DeadThreshold){
				atomic{
				pending = FALSE;
				pendingDeadCount=0;
				}
			}
		}
	}

  }

  task void readConnected() {
  	TOS_MsgPtr pbuf = &inMsgBuf;
	ConnectedMsg *msg = (ConnectedMsg *)pbuf->data;
#ifdef CASE_22
	int8_t tmpd;
#endif

	uint8_t tmpv;
	int8_t r;
	int8_t pparent;
	int8_t update, propagate;

  //BroadcastingNP
  //check if the received version number is valid?
  tmpv=0;
  update=0;
  propagate=0;

  if(msg->version1==msg->version2) {
	tmpv=msg->version1;

	if(version<86) {		// in region A
	//if(version>=0 && version<86) {		// in region A
		if(tmpv<86) {
		//if(tmpv>=0 && tmpv<86) {
			if(version>tmpv)	propagate=1;
			else if(version<tmpv)	update=1;
		}

		if(tmpv>=86 && tmpv<171) update=1;

		if(tmpv>=171) propagate=1;
		//if(tmpv>=171 && tmpv<256) propagate=1;
	}
	else if(version>=86 && version<171) { // in region B
		if(tmpv>=86 && tmpv<171) {
			if(version>tmpv)	propagate=1;
			else if(version<tmpv)	update=1;
		}

		if(tmpv>=171) update=1;
		//if(tmpv>=171 && tmpv<256) update=1;

		if(tmpv<86) propagate=1;
		//if(tmpv>=0 && tmpv<86) propagate=1;
	}
	else if(version>=171) { // in region C
	//else if(version>=171 && version<256) { // in region C
		if(tmpv>=171) {
		//if(tmpv>=171 && tmpv<256) {
			if(version>tmpv)	propagate=1;
			else if(version<tmpv)	update=1;
		}

		if(tmpv<86) update=1;
		//if(tmpv>=0 && tmpv<86) update=1;

		if(tmpv>=86 && tmpv<171) propagate=1;
	}
  }

  if(update==1 && msg->type==CONNECTED_PIGGYBACK){
		if(!basestation){	// KKK
			atomic{
			version=tmpv;
			memcpy((void*)&nplist, (const void*)&msg->nplist, sizeof(netParam));
			signal BroadcastingNP.setLocalParameters(version,nplist);
			}
		}
  }

  if(propagate==1){
		verFlag=1;

		//speed up sending the next connected
		if(distance>0 || basestation) { // if I have a parent now
			if((cconnected-tickCount)>SPEEDUP_INTERVAL_COUNT+SUBT_NUM_SP) {
				atomic{
				// pick number in [2..8] whose average is 5
				r= (call Random.rand())%MOD_NUM_SP;
				cconnected= SPEEDUP_INTERVAL_COUNT - (r-SUBT_NUM_SP);
				tickCount=0;	
				dbg(DBG_USR2, "speedup timer %d (v=%d, tmpv=%d)\n",
				cconnected,version,tmpv);
				}
			}
		}
  }
  // end of BroadcastNP

  // GN: if only from my primary or secondary
  pparent=0;
  if(!basestation){
  	if((call Neighborhood.isPrimaryParent(myID,msg->id))==1 &&
     	msg->bid==myPBid) pparent=1; 
  	else if((call Neighborhood.isSecondaryParent(myID,msg->id))==1 &&
     	msg->bid==mySBid) pparent=2;
  	else pparent=0;		// no potential parent 
  }

  if( pparent>0 && !basestation ) {
  //if(isMyHNgh(myID, msg->id) && TOS_LOCAL_ADDRESS>0){	
	//aquire a parent
	if(distance==0){
		atomic{
		remain = PARENT_DEAD_COUNT;
		parentID.x = msg->id.x;		//check
		parentID.y = msg->id.y;
#ifdef CASE_22
		distance = compDistance(myID,parentID);
#else
		distance = DIST;
#endif
		curGate=pparent;
		myBid = msg->bid;
		limitFlag=0;	//

		dbg(DBG_USR2, "I (%d, %d) acquire my parent (%d,%d) curGate=%d\n",
		myID.x,myID.y,parentID.x,parentID.y,curGate);
		}
	}
	//keep a parent
	//GN: if I have a parent
	/*
			if curGate==1 && pparent==2 -> skip
			if curGate==1 && pparent==1 -> same thing as before
			if curGate==2 && pparent==1 -> switch 
			if curGate==2 && pparent==2 -> same thing as before
	*/
	else if(distance>0){
		//tmpd=compDistance(myID,msg->id);
		//if(tmpd > distance){
		if (curGate>pparent) {		// switch !!!
			atomic{
			remain = PARENT_DEAD_COUNT;
			parentID.x = msg->id.x;		//check
			parentID.y = msg->id.y;
#ifdef CASE_22
			distance = compDistance(myID,parentID);
#else
			distance = DIST;
#endif
			dbg(DBG_USR2, "I (%d, %d) keep a parent (%d,%d) curGate=%d\n",
			myID.x,myID.y,parentID.x,parentID.y,curGate);
			
			limitFlag=0;
			curGate=pparent;
			myBid = msg->bid;
			}
		}
		//else if(tmpd == distance){
		else if(curGate==pparent){
#ifdef CASE_22
			tmpd=compDistance(myID,msg->id);
			if((tmpd>distance) || 
               ((tmpd==distance) && ((limitFlag==1) || (LIMIT_FREQ==0)))){
#else
			if((limitFlag==1) || (LIMIT_FREQ==0)){
#endif
				atomic{
				remain = PARENT_DEAD_COUNT;
				parentID.x = msg->id.x;		//check
				parentID.y = msg->id.y;
#ifdef CASE_22
				distance = compDistance(myID,parentID);
#else
				distance = DIST;
#endif
				dbg(DBG_USR2, "I (%d, %d) keep a parent (%d,%d) curGate=%d\n",
				myID.x,myID.y,parentID.x,parentID.y,curGate);
			
				limitFlag=0;
				curGate=pparent;
				myBid = msg->bid;
				}
			}
			// else no change
			else{
				dbg(DBG_USR2, "I (%d, %d) cannot keep a parent to (%d,%d) LIMIT limitCount=%d\n",myID.x,myID.y,msg->id.x,msg->id.y, limitCount);
			}
		}
	}
  }

  // for ReliableComm
  // I am a child of a base station now!
  if(!basestation){
  	if(curGate==1 && amIPotentialBaseChild(TOS_LOCAL_ADDRESS)){ 
		if(baseChild==0){
			baseChild=1;
			signal GridInfo.updateBaseChild(TRUE);
		}
  	} 
  	else { // I am not a child of a base station now!
		if(baseChild==1){
			baseChild=0;
			signal GridInfo.updateBaseChild(FALSE);
		}
  	}
  }
  //

	/*
	otherwise, ignore the msg 
	*/

	inHandle=0;
  }

  command result_t StdControl.init() {
  	result_t ok1, ok3;
  	gpoint id;
	int r;

	id = AddresstoID(TOS_LOCAL_ADDRESS, N);
	myID.x = id.x;		
	myID.y = id.y;

	//hasParent = 0;
	parentID.x = 0xff;
	parentID.y = 0xff;
	distance = 0;	// for new grid routing
	curGate=0;

	// MODIFY depending on topology!!!
	basestation=amIBaseStation(TOS_LOCAL_ADDRESS);

	myPBid= ComputePrimBid(myID);		// get my primary base ID
	mySBid= ComputeSecBid(myID);

	if(basestation) myBid=ComputeMyBid(myID);
	else myBid=0x7f;

    pending = FALSE;
	remain = 0;
	tickCount=0;
	inHandle=0;
  	pendingDeadCount=0;

	call Random.init();

	atomic{
	// for new routing, pick number in [15..25]
	r= (call Random.rand())%MOD_NUM;
	cconnected= CONNECTED_INTERVAL_COUNT - (r-SUBT_NUM);
	dbg(DBG_USR2, "select init %d\n",cconnected);
	}

    limitFlag=1;	// 1-> can change, 0-> cannot change
    limitCount=0;		 

	verFlag=0;		// BroadcastingNP 1->piggyback 0->no piggyback
	version=0;

	baseChild=0;	// for ReliableComm

    ok1= call CommControl.init();
	//ok2= call UARTControl.init();
	
	ok3= call Leds.init();

	return rcombine(ok1, ok3);
	//return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.start(){
  	result_t ok1, ok2;

    ok1= call Timer.start(TIMER_REPEAT,CONNECTED_INTERVAL);
    ok2= call CommControl.start();
	//ok3= call UARTControl.start();
	return rcombine(ok1,ok2);
	//return rcombine3(ok1,ok2,ok3);
  }

  command result_t StdControl.stop(){
  	result_t ok1, ok2, ok3;

    ok1=call Timer.stop();
    ok2= call CommControl.stop();
	//call UARTControl.stop();

	return rcombine(ok1,ok2);
  } 

  /*Timer.fired*/
  event result_t Timer.fired() {
    int r;

	tickCount++; 
	if(tickCount >= cconnected) {
		tickCount = 0;
		atomic{
		// for new routing, pick number in [15..25]
		r= (call Random.rand())%MOD_NUM;
		cconnected= CONNECTED_INTERVAL_COUNT - (r-SUBT_NUM);
		//dbg(DBG_USR2, "select timer %d\n",cconnected);
		}

		// debug
		//call Leds.greenToggle();
	}
	//if(tickCount == CONNECTED_INTERVAL_COUNT) tickCount = 0;

	// limit frequency
	if(LIMIT_FREQ > 0) {
		limitCount++;
		if(limitCount >= LIMIT_FREQ){
			atomic{
			limitFlag=1;
			limitCount=0;
			}
		}
	}

	//for new grid routing
	if(remain>0) {
		remain--;
		if(remain==0) {
			atomic{
			distance=0;
			}
			dbg(DBG_USR2, "I (%d, %d) lost my parent\n", myID.x, myID.y);
		}
	}

	if(tickCount == 0){

    /* send connected only when I have a parent or
	   I am a base station */
  		if ( basestation || distance>0){
    			post sendConnected();
		}
	}

    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveGTMsg.receive(TOS_MsgPtr pmsg){

    	TOS_MsgPtr pbuf = &inMsgBuf;
  		//ConnectedMsg *msg = (ConnectedMsg *)pmsg->data;
	
		//dbg(DBG_USR2, "I (%d, %d) received a connected from (%d,%d) rv=%d\n", myID.x, myID.y, msg->id.x, msg->id.y, msg->version1);

		//If I receives connected only from my H-ngh
		//if(isMyHNgh(myID, msg->id) && !inHandle && TOS_LOCAL_ADDRESS>0){	

		if(!inHandle){

			atomic{
			memcpy((void*)pbuf, (const void*)pmsg, sizeof(TOS_Msg));
			inHandle=1;
			}
			post readConnected();

			return pmsg;
		}
		else{   //if it is not my ngh, ignore this msg
			return pmsg;  
		}
	
//	return pmsg;

  }

  result_t sendDone(TOS_MsgPtr pmsg, result_t status) {
  	TOS_MsgPtr pbuf = (TOS_MsgPtr)&outMsgBuf;

    if(pbuf==pmsg) {
		atomic{
		pending = FALSE;
		pendingDeadCount=0;
		}
	}

    return status;
  }

  event result_t SendGTMsg.sendDone(TOS_MsgPtr msg, result_t success) {
      return sendDone(msg, success);
  }	    

  command gpoint GridInfo.getParent(){
	// parentID= (0xff,0xff) then NO PARENT!!!

    gpoint noparent;
	noparent.x = 0xff;	
	noparent.y = 0xff;

	if (distance>0) return parentID;
	else return noparent;
  }

  command gpoint GridInfo.getMyID(){
	gpoint id = AddresstoID(TOS_LOCAL_ADDRESS, N);
	return id;
  }

  command uint16_t GridInfo.getIDtoAddress(gpoint id){
	uint16_t addr = IDtoAddress(id, N);
	return addr;
  }

  command result_t BroadcastingNP.setNetworkParameters(uint8_t vnum, netParam plist){
	atomic{
  	version=vnum;
	memcpy((void*)&nplist, (const void*)&plist, sizeof(netParam));
	}

	return SUCCESS;
  }

} // end of implementation

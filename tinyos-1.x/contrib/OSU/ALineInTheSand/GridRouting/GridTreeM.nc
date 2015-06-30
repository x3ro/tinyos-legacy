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
 *
 *  This implementation is based on the design
 *  by Mohamed G. Gouda, Young-ri Choi, Anish Arora and Vinayak Naik.
 *
 */

// This module includes some codes for visualization of a spanning 
// tree. However, these codes doesn't affect routing performance,
// since the visualization is excuted only on-demand.

includes GridTreeMsg; 

#ifndef DeadThreshold
#define DeadThreshold 3
#endif

module GridTreeM { 
    provides{
		interface StdControl;
		interface GridInfo;
	}
    uses {
      interface Leds;
      interface ReceiveMsg as ReceiveGTMsg;
      interface SendMsg as SendGTMsg;
      interface StdControl as CommControl;
      interface Timer;

      interface Random;
      // for visualization purpose only,
	  // a base station sends periodic vis messages to PC
	  interface SendMsg as UARTSendGTMsg;	
	  // a base station sends on-demand vis messages to PC
	  interface SendMsg as UARTSendPathMsg;

	  interface ReliableSendMsg;
	  interface ReliableReceiveMsg;

	  interface StdControl as UARTControl;
	  interface ReceiveMsg as UARTReceive;
    }
}

/* 
 *  Module Implementation
 */

implementation 
{

enum{
	N=3,					// size of grid, 3x3 grid
	LMAX=6,               // cmax in the document
	PARENT_DEAD_COUNT=7,	// R in the document

	CONNECTED=0,
	PATH=1,

	PATH_MAX_COUNT=4,		// for vis. purpose only
	UPDATE_MAX_COUNT=20,			

	CONNECTED_INTERVAL_COUNT=3,		// should be > 1
	CONNECTED_INTERVAL=1000, 

	MAX_NUM_MOTES=100

};

  gpoint myID;
  gpoint parentID;
  int8_t myLevel;
  int8_t hasParent;		

  int8_t pending;
  TOS_Msg inMsgBuf,outMsgBuf;
  int8_t remain;

  int8_t pathCount;
  int8_t pathFlag;

  int8_t updateCount;
  int8_t updateFlag;
  int8_t state;

  int8_t parentFlag;

  int8_t tickCount;
  TOS_Msg inMsgBufPath, outMsgBufPath;
  int8_t outHandlePath; // for outMsgBufPath;

  uint16_t tick;

  uint8_t parray[MAX_NUM_MOTES];

  // inHandle for inMsgBuf (connected)
  // inHandlePath for inMsgBufPath (path)
  int8_t inHandle, inHandlePath;

  int8_t pendingDeadCount;

  uint8_t vis;			// for on-demand vis.
  uint8_t numUpdate;

  /*
   Dist(ngh) < Dist(me) -> mylevel = parentlevel
   Dist(ngh) > Dist(me) -> mylevel = parentlevel +1
   */
  inline int8_t computeLevel(gpoint id, int8_t level){
  	if(id.x+id.y < myID.x+myID.y){
		return level;
	}
	else return level+1;
  }

  // for vis. purpose only
  task void updatePath(){
  	struct UpdateMsg *msg = (struct UpdateMsg *)outMsgBuf.data;
	int i;

	if(!pending){
	  pending=TRUE;

	  msg->state = 4-state;
	  dbg(DBG_USR1, "* ");
	  for(i=0;i<NUM_INDEX;i++){
	    if(msg->state != 4) {
	  		msg->path[i] = parray[(4-state)*NUM_INDEX+i];
		}
		else // msg->state == 4
	  		msg->path[i] = 0xff;
	  }

	  call Leds.redToggle();
	  if(!(call UARTSendGTMsg.send(TOS_UART_ADDR, sizeof(struct UpdateMsg),&outMsgBuf))) 
	    pending = FALSE;
	}
	else { //Hongwei:
		pendingDeadCount++;
		if (pendingDeadCount > DeadThreshold)
			pending = FALSE;
	}

	state++;
	if(state == 5) {
		state = 0;
		updateFlag = 0;
	}
  }

  // for vis. purpose only
  task void sendPath(){
  	struct PathMsg *msg = (struct PathMsg *)outMsgBufPath.data;
	uint16_t addr;

	msg->num = 1;
	msg->pid = parentID;
	msg->path[0] = (uint8_t)TOS_LOCAL_ADDRESS;
	addr = IDtoAddress(parentID, N);

	if(call ReliableSendMsg.send(addr, sizeof(struct PathMsg), &outMsgBufPath, TOS_LOCAL_ADDRESS,0)){
			call Leds.greenToggle();
		}
  }

  // for vis. purpose only
  task void forwardPath(){
  	TOS_MsgPtr pbuf = &inMsgBufPath;
	struct PathMsg *imsg = (struct PathMsg *)pbuf->data;
	struct PathMsg *omsg = (struct PathMsg *)outMsgBufPath.data;
	int i;
	uint16_t addr, fromAddr;
	uint8_t fromQueuePos;

	if(imsg->num < MAX_PATH){
			omsg->pid = parentID;
			omsg->num = imsg->num+1;
			for(i=0;i<imsg->num;i++)
				omsg->path[i]=imsg->path[i];
			omsg->path[(int)imsg->num]=(uint8_t)(TOS_LOCAL_ADDRESS);

			addr = IDtoAddress(parentID, N);

			fromAddr = (uint16_t)pbuf->data[sizeof(struct PathMsg)+MyAddrPos];
			fromAddr = fromAddr << 8;
			fromAddr = fromAddr | ((uint16_t)pbuf->data[sizeof(struct PathMsg)+MyAddrPos+1]);
			fromQueuePos = pbuf->data[sizeof(struct PathMsg)+MyQueuePos];

			// for forwarding msgs
			if(call ReliableSendMsg.send(addr, sizeof(struct PathMsg), &outMsgBufPath, fromAddr,fromQueuePos)){
				call Leds.greenToggle();
			}
	}

	inHandlePath=0;
  }

  // for vis. purpose only
  task void readPath(){
  	TOS_MsgPtr pbuf = &inMsgBufPath;
	struct PathMsg *msg = (struct PathMsg *)pbuf->data;
	uint8_t p,c;
	int i,j;

	call Leds.greenToggle();

	for(i=0; i<msg->num;i++){
		if(i<msg->num-1){
			c=msg->path[i];
			p=msg->path[i+1];

			parray[c] = p;
		}
	}

	j = msg->path[msg->num-1];
	parray[j] = TOS_LOCAL_ADDRESS;
	dbg(DBG_USR1, "parent of mote %d is mote %d\n", j, parray[j]);

	// ON-DEMAND: if you don't want to send vis. msg right away,
	// you can comment out following paragraph.
	// send on-demand vis msg to PC
	/*
	if(!pending){
		pending = TRUE;
		memcpy((void*)&outMsgBuf, (const void*)&inMsgBufPath, 
				sizeof(struct PathMsg));
		outMsgBuf.addr = TOS_UART_ADDR;
		if(call UARTSendPathMsg.send(TOS_UART_ADDR, 
				sizeof(struct PathMsg), &outMsgBuf)){
			call Leds.greenToggle();
		}
		else
			pending = FALSE; 
	}
	else { //Hongwei:
		pendingDeadCount++;
		if (pendingDeadCount > DeadThreshold)
			pending = FALSE;
	}
	*/

	inHandlePath=0; 
  }

  task void sendConnected(){
 	ConnectedMsg *msg = (ConnectedMsg *)outMsgBuf.data;

   /* send connected only when remain > 0 or I am a base station! */
   if(!pending && (remain>0 || TOS_LOCAL_ADDRESS==0)){
	    pending = TRUE;
		msg->type = CONNECTED;
		msg->id = myID;
		msg->level = myLevel;
		msg->pid = parentID;
		msg->vis = vis;

		remain--;
		if(call SendGTMsg.send(TOS_BCAST_ADDR, sizeof(ConnectedMsg), &outMsgBuf)){
		call Leds.yellowToggle();
		}
		else 
		   pending= FALSE;
    }
	else{ 
		if(remain==0){
			// if remain==0, then I lose my parent!
			hasParent=0;
			dbg(DBG_USR1, "I (%d, %d) lost my parent\n", myID.x, myID.y);
		}

		if(pending){
			pendingDeadCount++;
			if (pendingDeadCount > DeadThreshold)
				pending = FALSE;
		}
	}
  }

  task void readConnected() {
  	TOS_MsgPtr pbuf = &inMsgBuf;
	ConnectedMsg *msg = (ConnectedMsg *)pbuf->data;
	int8_t tmplevel;

  	// learn its parent alive
	if(hasParent && msg->id.x == parentID.x
	  && msg->id.y==parentID.y){
		// check if level is changed
		if( msg->level<LMAX ||
		   (msg->level==LMAX && 
		    msg->id.x + msg->id.y < myID.x+myID.y)){
			remain = PARENT_DEAD_COUNT;
			hasParent = 1;
			parentID = msg->id;
			myLevel = computeLevel(msg->id, msg->level);
		}
		else {
			// if msg->level == LMAX &&  Dist(ngh) > Dist(Me)
			// then I lose my parent.
			hasParent = 0;

		dbg(DBG_USR1, "I (%d, %d) lost my parent\n", myID.x, myID.y);

		}
	}
	// aquire parent
	else if(!hasParent && (msg->level<LMAX || (msg->level==LMAX && 
	(msg->id.x+msg->id.y < myID.x+myID.y))))
	{
		remain = PARENT_DEAD_COUNT;
		hasParent = 1;
		parentID = msg->id;
		myLevel = computeLevel(msg->id, msg->level);
		dbg(DBG_USR1, "I (%d, %d) acquire my parent (%d,%d)\n",
		myID.x,myID.y,parentID.x,parentID.y);
	}
	// change parent
	else if(hasParent){
		tmplevel = computeLevel(msg->id, msg->level);
		// it can decrease my level, then I change!
		if(tmplevel<myLevel){
			remain = PARENT_DEAD_COUNT;
			hasParent = 1;
			parentID = msg->id;
			myLevel = tmplevel;

		dbg(DBG_USR1, "I (%d, %d) change my parent (%d,%d)\n",
		myID.x,myID.y,parentID.x,parentID.y);

		}
	}
	/*
	otherwise, ignore the msg 
	*/

	inHandle=0;
  }

  command result_t StdControl.init() {
  	result_t ok1, ok2, ok3;
  	gpoint id;
	int i;

	id = AddresstoID(TOS_LOCAL_ADDRESS, N);
	myID = id;
	myLevel = 0;

	hasParent = 0;
	parentID.x = 0xff;
	parentID.y = 0xff;

    pending = FALSE;
	remain = 0;

	pathCount = 0;
	pathFlag= 0;

	updateCount=0;
	updateFlag=0;
	state=0;

	parentFlag=0;

	tickCount=0;

	tick=0;

	inHandle=0;
	inHandlePath=0;
	outHandlePath=0;

  	pendingDeadCount=0;

	vis = 0;
	numUpdate=0;

	for(i=0;i<MAX_NUM_MOTES;i++){
		parray[i]=0xff;
	}

    ok1= call CommControl.init();
	ok2= call UARTControl.init();
	
	ok3= call Leds.init();

	return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.start(){
  	result_t ok1, ok2, ok3;

    ok1= call Timer.start(TIMER_REPEAT,CONNECTED_INTERVAL);
    ok2= call CommControl.start();
	ok3= call UARTControl.start();
	return rcombine3(ok1,ok2,ok3);
  }

  command result_t StdControl.stop(){
  	result_t ok1, ok2, ok3;

    ok1=call Timer.stop();
    ok2= call CommControl.stop();
	call UARTControl.stop();

	return rcombine(ok1,ok2);
  } 
  
  /*Timer.fired*/
  event result_t Timer.fired() {

	tickCount++; 
	if(tickCount == CONNECTED_INTERVAL_COUNT) tickCount = 0;

    // for vis. purpose only
	if(pathFlag>0 && tickCount!=0) {
		pathFlag--;

		if(hasParent)
			post sendPath();

		return SUCCESS;
	}

    // for vis. purpose only
	// ON-DEMAND: if you don't want to send vis msgs periodically
	// you can comment out two parts, one is the below paragraph.
	//
	if(updateFlag==1) {
		updateFlag=0;

		if(numUpdate>0){
			post updatePath();
		}

		return SUCCESS;
	}
	//

	if(tickCount == 0){
		
		tick++;
		
        // for vis. purpose only
		// ON-DEMAND: here is another paragrph to comment out
		// if you don't want to send periodic vis msgs.
		//
		if(TOS_LOCAL_ADDRESS == 0){
			updateCount++;
			if(updateCount==UPDATE_MAX_COUNT){
				updateCount=0;
				updateFlag=1;
				if(numUpdate > 0) numUpdate--;
			}

			if(updateFlag == 0 && state>0){
				updateFlag=1;
			}
		}
		//

        // for vis. purpose only
		if(TOS_LOCAL_ADDRESS != 0) {
			if(parentFlag > 0) parentFlag--;
		}

    /* send connected only when I have a parent or
	   I am a base station */
  		if ((TOS_LOCAL_ADDRESS == 0) || hasParent){

    			post sendConnected();
		}
	}

    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveGTMsg.receive(TOS_MsgPtr pmsg){

	if(pmsg->data[0] == CONNECTED){
    	TOS_MsgPtr pbuf = &inMsgBuf;
  		ConnectedMsg *msg = (ConnectedMsg *)pmsg->data;

        // for vis. purpose only
		// check if I am parent or not here
		if((msg->pid.x==myID.x) && (msg->pid.y==myID.y)){
			// since it decreases parentFlag by one first
			// before it checks parentFlag value
			parentFlag = PARENT_DEAD_COUNT+1;
		}

        // for vis. purpose only
		// ON-DEMAND: check if this msg contains a bigger vis 
        // from any motes
		if(msg->vis > vis && TOS_LOCAL_ADDRESS > 0){
			vis=msg->vis;
			// if I am a leaf, generate two visualization msg!
			if(parentFlag==0 && hasParent){
				pathFlag=2;
			}
		}

		/* If I receives connected only from my ngh */
		if(isMyNgh(myID, msg->id, N) && !inHandle && TOS_LOCAL_ADDRESS>0){	
			memcpy((void*)pbuf, (const void*)pmsg, sizeof(TOS_Msg));

		/* (0,0) doesn't have a parent so ignore connected msg*/
			if(TOS_LOCAL_ADDRESS > 0){
				inHandle=1;
				post readConnected();
			}

			return pmsg;
		}
		else{   //if it is not my ngh, ignore this msg
			return pmsg;  
		}
	}
	
	return pmsg;

  }

  result_t sendDone(TOS_MsgPtr pmsg, result_t status) {
  	TOS_MsgPtr pbuf = (TOS_MsgPtr)&outMsgBuf;

    if  (pbuf==pmsg) 
		pending = FALSE;

    return status;
  }

  event result_t SendGTMsg.sendDone(TOS_MsgPtr msg, result_t success) {
	return sendDone(msg, success);
  }

  event result_t UARTSendGTMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    pending = FALSE;
	return SUCCESS;
  }

  // for vis. purpose only
  event result_t UARTSendPathMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    pending = FALSE; 
	return SUCCESS;
  }

  // for vis. purpose only
  event result_t ReliableSendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
	return success;
  }

  // for vis. purpose only
  event TOS_MsgPtr ReliableReceiveMsg.receive(TOS_MsgPtr pmsg, uint16_t fromAddr, uint8_t fromQueuePos)
  {
	struct PathMsg *msg = (struct PathMsg *)pmsg->data;
	TOS_MsgPtr pbuf = &inMsgBufPath;	// copy to this buffer

	if((msg->pid.x == myID.x) && (msg->pid.y == myID.y) && !inHandlePath){
		memcpy((void*)pbuf, (const void*)pmsg, sizeof(TOS_Msg));

		if(TOS_LOCAL_ADDRESS == 0){
			inHandlePath=1;
			post readPath();
		}
		else{
			if(hasParent){
				inHandlePath=1;
				post forwardPath();
			}
		}
	}

	return pmsg;

  }

  // for vis. purpose only
  event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr pmsg){
  	int i;
	struct HiMsg *msg = (struct HiMsg *)pmsg->data;

	if(msg->type == 0xff){	// if it is a Hi msg

		call Leds.redToggle();
		numUpdate=6;

		if(msg->flag == 1){		// with a specific vis!
			vis = msg->vis;
		}
		else{
			vis++;
		}

		// reinitialize parray when it receives a "hi" msg
		for(i=0;i<MAX_NUM_MOTES;i++)
			parray[i]=0xff;
	}
	//else ignore other msgs!

  	return pmsg;
  }

  command gpoint GridInfo.getParent(){
	// parentID= (0xff,0xff) then NO PARENT!!!

    gpoint noparent;
	noparent.x = 0xff;	
	noparent.y = 0xff;

	if (hasParent) return parentID;
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

} // end of implementation

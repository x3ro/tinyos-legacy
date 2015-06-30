/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */

/**
 * WARNING: This module packs addresses into 8 bytes.  Be careful when
 * using 16-byte addressing.
 * This code assumes that only Send can be pending at any given time
 */

//****************************************************************************
//*************************Important notes************************************
//-------------------------------1--------------------------------------------
//*** Window size used in nacks is assumed to be a multipole of 8*************
//*** This is not too restrictive, and allows for ease of implementation******
//-------------------------------2--------------------------------------------
//***NACK timer is in 100 millisec scale, even though the sender specifies****
//***it in millisecond scale, to avoid excessive timer events*****************
//***This implies that minimum nack timer can be 100 millisecs****************
//-------------------------------3--------------------------------------------
//***This only supports 1 active send coneection for now,*********************
//***and REL_MAX_CONN_NUM number of active receive connections****************





#define USE_LEDS 1

module ReliableTransportM {
   provides {
      interface StdControl as Control;
#if VIB_SENSOR
#if ENABLE_EEPROM
      interface State;
#endif
#endif

      interface VarRecv;
      interface VarSend;
   }
   uses {

      interface Timer;
      interface StdControl as RTCommControl;
      interface GenericPacket;
#if USE_LEDS
      interface Leds;
#endif

#if 0 // Replacing following interfaces with a single interface GenericPacket interface

      // The send receive interface hookups for following interfaces assume a single destination DSDV 
      // which only gives route to the root node. If we have multi-destination DSDV we could probably 
      // use only one send receive interface

      // Next three interfaces hook up to DVDV in this version
      interface Send; // Send data and cmds for Send side
      interface Receive; // Receive data and cmd on the receive side
      interface MultiHopMsg;

      // Next three interfaces hook up to Flood in this version
      // Two send interfaces because of a hack needed in flood.
      // Self note: Move to a non-flood delivery method. Maybe source-routing.
      // both send interfaces are used to send cmds and ack on Receive side
      interface Send as SendCmd;
      interface SendMHopMsg as SendMHopCmd; 
      interface Receive as ReceiveCmd;      
      interface MultiHopMsg as CmdMHopMsg;
#endif
   }
}




implementation{

  //#ifdef RELIABLE_TRANSPORT_DEBUG
#if 0
void DisplayStr(char *str) __attribute__ ((C, spontaneous));
char temp[100];
#else
#define DisplayStr(str)
  //#define sprintf(char *str) __attribute__ ((C, spontaneous))
#endif

// struct to store conection parameters for receive
    typedef  __attribute__ ((packed)) struct{
	wsnAddr addr; // address of the sender node
	uint8_t appId;
	uint8_t tId; //Transaction id received from the sender
	uint8_t ver; // version number of the protocol used byteh sender
	uint16_t dataSize; // total amount of data to expect
	uint16_t fragSize; // fragment size
	uint16_t fragPeriod; // minimum delay between two consecutive frags
	uint8_t winSize;  // window size used for acks    
      uint16_t netDelay;
	uint16_t nackPeriod; // maximum delay between nacks in millisecs. 
	// But, in order to avoid excessive timer events the implementation only uses a timer accuracy 
	// of 100 millisecs
	

	//timer parameters for connection
	uint16_t fatalTimeout; //maximum amount of time for which a connection is allowed to be 
	// open waiting for data 

	uint16_t currNackTimeout;  // timeout before sending out next Nack. ** 100 millisec ** scale
	//	uint8_t  nackTimerState; // used to figure out what state was the nack timer in. This allows us 
    // to vary the timer accordingly. For e.g. first nack timeout maybe shorter then subsequent ones etc.
    // see nack timer state enum below...
	
    //parameters for connection acks
	
	uint16_t startFrag;
	uint8_t ackBitmap[REL_MAX_ACK_BITMAP_SIZE];
	uint8_t   tmpFragStore[REL_MAX_FRAG_SIZE];
	void * handle; // connection handle provided by the application layer
	bool connState; // has it been accepted yet by the app layer?
	uint16_t nackMainTimer;
	uint16_t nackShortTimer;
	uint16_t nackDataTimeout;
	uint16_t lastAckResendTimer; // Self Note: make sure to initialize it to 0 for every send

	bool     unusedIndex;
	uint8_t  nackSeq;
    }RelConnParams;
    typedef RelConnParams* RelConnParamsPtr;


    
    uint8_t* msg;
   
    

    RelConnParams relConnParams[REL_MAX_CONN_NUM];
    uint8_t lastConnIndex; // points to last **free** connection index 
    
    //parameters for sendConnRej task
    wsnAddr connRejAddr; // address of the sender
    uint8_t connRejTid;  // transaction id of the sender
    uint8_t connRejReason; // reason for rejection of connection
    uint16_t connReqResendTimer; // Self Note: make sure to initialize it to 0 for every send
    uint8_t sendConnReqTask;
    uint8_t connAccIndex;
    uint8_t sendConnRejTask;

    //parameters for sendConnRej task
    uint8_t sendConnAccTask;
    //general parameters
    bool sendPending;

    uint8_t tId;
    uint16_t packetSize;
    bool sendPacketPending;
    void* connHandle;

    //parameters for sigSendFail
    uint8_t sigSendFailTask;

    //parameters for sending packets
    uint8_t sendState;
    uint16_t currStartFrag; // start of the window
    uint16_t currFrag; // current frag that is being sent 
    uint16_t lastFrag; // last fragment
    uint16_t maxFragSize;
    
    uint8_t processSendDoneTask;
    uint8_t abortSendTask;

    uint8_t* sendMsg;

    uint8_t sendAckStatus[REL_ACK_STATUS_ARRAY_SIZE]; 
    uint8_t lastNackSeq;
    // char* currBufPtr;
    uint8_t sendDataPacketTask;
    uint8_t currApp;
    bool stopSend;


    uint8_t processConnAccTask;
    uint8_t processLastAckTask;

    //process nack task parameters
    uint8_t processNackTask;
    uint16_t tmpStartFrag;
    uint8_t tmpSendAckStatus[REL_ACK_STATUS_ARRAY_SIZE]; 
    
    // parameters for last ack task
    uint8_t lastAckTid;
    
    uint16_t  lastRecFrag; 
    uint8_t   lastDataIndex;

    uint8_t processRelDataTask;
    //#if SINK_NODE || PLATFORM_PC
    //    uint8_t receiveBuf[1100]; //enough for 500 samples
    //#endif 
    uint8_t maskArray[8];
    bool currConnAcc;
    uint8_t   sendFragStore[2*REL_MAX_FRAG_SIZE];
    RelDataPtr rData;

    wsnAddr DestAddr; 
  #if ENABLE_EEPROM
  RTStateInfo rtInfo;
  #endif




enum {
    REL_CONN_REJ_MAX_CONN_ERR = 1, // this connection request has exceeded the maximum 
    // number of connections allowed
    
    REL_CONN_REJ_APP_ERR = 2 // application has refused to accept connection
    
    // maybe more to follow later
};


//mtc values
enum {
    REL_CONN_REQ      = 1,
    REL_CONN_ACC      = 2,
    REL_CONN_REJ      = 3,
    REL_DATA          = 4,
    REL_NACK          = 5,
    REL_LAST_ACK      = 6,
    REL_REC_LAST_ACK  = 7
};


//Task States
    enum {
	REL_TASK_DONE = 1,
	REL_TASK_PENDING = 2,
	REL_TASK_RUNNING = 3,
        REL_TASK_POST_REQ = 4,
	REL_TASK_POST_DONE = 5
    };


    //Send modes for figuring out whetrher we are resending, or is this a new Nack 

    enum {
	REL_SEND_PACKETS_DONE = 1,
	REL_SEND_PACKETS_SEND = 2,
	REL_SEND_PACKETS_RESEND = 3 // a new ackhas arrived that needs to be handled
    };


    //Purpose: Initialize all the variables and sub-components

    command result_t Control.init() {
	uint8_t i,j;


	sendPending = FALSE;
	stopSend = FALSE;
	
	currConnAcc = FALSE;

	sendState = REL_SEND_PACKETS_DONE;


	lastConnIndex = 0;
	tId = 0;
	connReqResendTimer = 0;

	sendConnReqTask    = REL_TASK_DONE;
	sendConnRejTask    = REL_TASK_DONE;
	sigSendFailTask    = REL_TASK_DONE;
	sendDataPacketTask = REL_TASK_DONE;
	sendConnAccTask    = REL_TASK_DONE;
	processRelDataTask = REL_TASK_DONE;
	processNackTask    = REL_TASK_DONE;
	processConnAccTask = REL_TASK_DONE;
	processSendDoneTask = REL_TASK_DONE;
	abortSendTask      = REL_TASK_DONE;
	processLastAckTask = REL_TASK_DONE;
	
	sendPacketPending  = FALSE;
	
	maskArray[0] = 0x80;
	for(i=1; i<8; i++){
	    maskArray[i] = ((maskArray[i-1] >> 1) | 0x80); 
	}
	
	for(i = 0; i< REL_MAX_CONN_NUM; i++){
	    relConnParams[i].nackMainTimer = 0;
	    relConnParams[i].nackShortTimer = 0;
	    relConnParams[i].nackDataTimeout = 0;
	    relConnParams[i].startFrag = 0;
	    relConnParams[i].unusedIndex = TRUE;
	    relConnParams[i].lastAckResendTimer = 0;
	    relConnParams[i].connState = FALSE;
	    for( j=0; j < REL_MAX_ACK_BITMAP_SIZE; j++){
		relConnParams[i].ackBitmap[j] = 0;
	    }
	}
	call RTCommControl.init();
	return SUCCESS;
    }



    // Purpose: Start sub components
   command result_t Control.start() {
     
       call RTCommControl.start();
       return call Timer.start(TIMER_REPEAT, REL_MAIN_TIMER);

   }

   command result_t Control.stop() {
       call RTCommControl.stop();
       return call Timer.stop();
   }


#if ENABLE_EEPROM
  command void* State.getStateBuffer(){
    return &rtInfo;
  }
  command result_t State.loadState (void *lsInfo){
    RTStateInfo* sInfo = (RTStateInfo*)lsInfo;
    if(sInfo->validData == TRUE){
      tId = sInfo->tId;
      packetSize = sInfo->packetSize;
      sendPacketPending = sInfo->sendPacketPending;
      lastFrag = sInfo->lastFrag;
      maxFragSize = sInfo->maxFragSize;
      currApp = sInfo->currApp;
      DestAddr = sInfo->DestAddr;
      currConnAcc = sInfo->currConnAcc;
    }
    return SUCCESS;
  }
#endif


  task void processSendDone();


    void SendLastAck(uint8_t i);
   
   task void SendDataPacket(){
       if(sendDataPacketTask != REL_TASK_DONE){
	   DisplayStr("ReliableTransport: Sending a data packet\n");
	   dbg(DBG_USR1, "ReliableTransport: Sending a data packet\n");
	   if(!sendPending &&  call GenericPacket.Send(DestAddr, 
						  (uint8_t*)sendMsg, REL_DATA_LEN+maxFragSize)){
	       DisplayStr("ReliableTransport: SendSuccess\n");
	       dbg(DBG_USR1, "ReliableTransport: SendSuccess\n");
               DisplayStr("Set Pending 8 \r\n");
	       sendPending = TRUE;
	       sendDataPacketTask = REL_TASK_DONE;
	   }
	   else{
	       sendDataPacketTask = REL_TASK_POST_REQ;
#ifdef RELIABLE_TRANSPORT_DEBUG
	       sprintf(temp,"Couldn't Send, pending %d\n", sendPending);
	       DisplayStr(temp);
#endif
	       
	   }
	   
	   

       }
   }
   


   //assumes only one task is running at a time, because assumption 
   //is that only one send can be pending at any given time on one node
   task void SendConnReq(){
       RelConnReqPtr relConnReq;
       uint16_t len;
       
  

#if USE_LEDS
       //       call Leds.yellowToggle();
#endif
       

       if(sendConnReqTask != REL_TASK_DONE){
	   
	   
	   //should be done before getbuffer to avoid clobbering the message buffer
	   if(sendPending){
	       sendConnReqTask = REL_TASK_POST_REQ;
	       return;
	   }


	   msg = call GenericPacket.AllocateBuffer(DestAddr, REL_CONN_REQ_LEN);



	   if(msg == NULL){

	       
	       DisplayStr("ReliableTransport: SendConnReq: Got a NULL\n");
	       dbg(DBG_USR1, "ReliableTransport: SendConnReq: Got a NULL\n");
	       sendConnReqTask = REL_TASK_POST_REQ;
	       return;
	   }
	   relConnReq = (RelConnReqPtr) call GenericPacket.GetPayloadStart((uint8_t*)msg, 
									   &len);
	   relConnReq->rHead.mtc = REL_CONN_REQ;
	   relConnReq->rHead.appId = APP_ID_RELIABLE_TRANSPORT;
	   relConnReq->rHead.tId = tId;
	   relConnReq->ver = REL_VER_NUM;
	   relConnReq->dataSize = packetSize;


           // Get the MTU size, and subtract the header
           maxFragSize = call GenericPacket.GetMaxPayloadSize(DestAddr);
	   maxFragSize -= REL_DATA_LEN;
	   if((maxFragSize%2) !=0){
	     maxFragSize--; 
	   }

	   relConnReq->fragSize = maxFragSize;
	   relConnReq->fragPeriod = REL_FRAG_PERIOD;
	   relConnReq->winSize = REL_WIN_SIZE;
	   relConnReq->netDelay = REL_MAX_NET_DELAY;	   
	   DisplayStr("ReliableTransport: Sending Connection Req packet\n");
	   dbg(DBG_USR1, "ReliableTransport: Sending Connection Req packet\n");
	   


	   if(!sendPending &&  
	      call GenericPacket.Send(DestAddr, msg, REL_CONN_REQ_LEN)){
	       DisplayStr("ReliableTransport: SendConnReq Send Successn");
	       dbg(DBG_USR1, "ReliableTransport: SendConnReq Send Successn");
	       

               DisplayStr("Set Pending 9 \r\n");
	       sendPending = TRUE;
	       sendConnReqTask = REL_TASK_DONE;
	       
	       if(connReqResendTimer == 0){ // only need to do it the first time
		   connReqResendTimer = (REL_RESEND_CONN_REQ_TIMER * 
					 REL_RESEND_CONN_REQ_MAX_TRIES);
	       }
	   }
	   else{
	       call GenericPacket.FreeBuffer(msg);
	       sendConnReqTask = REL_TASK_POST_REQ;
	       return;
	   }
       }
       sendConnReqTask = REL_TASK_DONE;
   }


  task void processPostSend(){
    tId++;
    
    currConnAcc  = FALSE;
    //       currApp    = app;  // only one send connection assumed   
    
    sendConnReqTask = REL_TASK_PENDING;
    post SendConnReq();
  }


   command result_t VarSend.postSend(void *handle, uint16_t numBytes, 
						  uint16_t destAddr){



       
       dbg(DBG_USR1, "ReliableTransport: Calling VarSend.postSend numbytes = %d\n", numBytes);
       dbg(DBG_USR1, "ReliableTransport: Calling VarSend.postSend numbytes = %d\n", numBytes);

       if(sendPacketPending || sendConnReqTask != REL_TASK_DONE){
	   // only one connection can be pending on send side
	   return FAIL;
       }


       sendPacketPending = TRUE;
       packetSize = numBytes;
       connHandle = handle;
       DestAddr = destAddr;
       
       // to make sure that it is run after any abort send
       post processPostSend();
       
       return SUCCESS;
   }
   

   command result_t 
   VarSend.pullSegDone(void *handle, uint16_t msgOffset){
     
     uint8_t i;

     //if(result == FAIL){
       // set this to done and wait for next nack
     //sendState = REL_SEND_PACKETS_DONE;
     //call GenericPacket.FreeBuffer(sendMsg);
     //return SUCCESS;
     //}
       if(sendDataPacketTask !=REL_TASK_DONE){
	   return SUCCESS; 
       }
       //copy data 
       
       DisplayStr("ReliableTransport: GOT a pullsegDone\n");
       dbg(DBG_USR1, "ReliableTransport: GOT a pullsegDone\n");
       sendDataPacketTask = REL_TASK_PENDING;
       
       for(i=0; i< maxFragSize; i++){
	 rData->data[i] = sendFragStore[i];
       }
       
       
       post SendDataPacket();
       
       
       return SUCCESS;
   }

  task void abortSend(){

    sendConnReqTask = REL_TASK_DONE;
    sendDataPacketTask = REL_TASK_DONE;
    processSendDoneTask = REL_TASK_DONE;
    sendPacketPending = FALSE;

    abortSendTask = REL_TASK_DONE;
    call GenericPacket.FreeBuffer(sendMsg);
    currConnAcc = FALSE;
    connReqResendTimer = 0;
  }

   command result_t VarSend.abortSend(void *handle){


     if(abortSendTask != REL_TASK_DONE){
       abortSendTask = REL_TASK_PENDING;
       post abortSend();
     }
       
       return SUCCESS;
   }




   




void SendNack(uint8_t i){
       RelNackPtr rNack;
       uint16_t  mBytes = (relConnParams[i].winSize/8);
       uint16_t len,j;
       uint16_t lFrag;
       
       lFrag = (relConnParams[i].dataSize -1)/relConnParams[i].fragSize;
       
       if(relConnParams[i].startFrag > lFrag){ // no need to send ack
	   DisplayStr("ReliableTransport: SendNack: No need to send nack\n ");
	   dbg(DBG_USR1, "ReliableTransport: SendNack: No need to send nack\n ");
	   return;
       }


       if(!sendPending){
	   DisplayStr("calling SendNack \n ");
	   dbg(DBG_USR1, "calling SendNack \n ");

	   msg = call GenericPacket.AllocateBuffer(relConnParams[i].addr, 
					  REL_NACK_LEN);

	   if(msg == NULL){
	       relConnParams[i].nackShortTimer = 2*REL_MAIN_TIMER;
	       return;
	   }
	   
	   

	   rNack = (RelNackPtr) call GenericPacket.GetPayloadStart((uint8_t*)msg, &len);

	   rNack->rHead.mtc = REL_NACK;
	   rNack->rHead.tId = relConnParams[i].tId;
	   rNack->rHead.appId = APP_ID_RELIABLE_TRANSPORT;
	   rNack->seq  = relConnParams[i].nackSeq;
	   rNack->startFrag  = relConnParams[i].startFrag;
	   
	   for(j = 0; j< mBytes; j++){
	       rNack->data[j] = relConnParams[i].ackBitmap[j];
	   }

	   if(call GenericPacket.Send(relConnParams[i].addr, 
				      msg, REL_NACK_LEN +(relConnParams[i].winSize/8))){
	       sendPending = TRUE;
	   }
	   else{
	       call GenericPacket.FreeBuffer(msg);
	       // try again in 100 milliseconds
	       relConnParams[i].nackShortTimer = 2*REL_MAIN_TIMER;
	   }
       }
       else{
	   DisplayStr("calling SendNack fail sendPending\n ");
	   dbg(DBG_USR1, "calling SendNack fail sendPending\n ");
	   // try again in 100 milliseconds
	   relConnParams[i].nackShortTimer = 2*REL_MAIN_TIMER;
       }
       
   }
#if PLATFORM_PC

   void printConnParams(){
       
       uint8_t i,j;
       RelConnParamsPtr rptr;
       uint8_t pState = 0;

       rptr = relConnParams;



       for(i =0; i< REL_MAX_CONN_NUM; i++){
	   
	   if(rptr[i].unusedIndex == FALSE){
	       if(pState == 0){
		   dbg(DBG_USR1, "********PrintConnParams START*************\n");
		   pState = 1;
	       }
	       dbg(DBG_USR1, "-------i = %d-------\n",i);
	       dbg(DBG_USR1, "addr = %d, appId = %d, tId = %d, ver = %d, dataSize = %d\n",
		   rptr[i].addr, rptr[i].appId, rptr[i].tId, rptr[i].ver,rptr[i].dataSize);
	       dbg(DBG_USR1, "dataSize = %d, fragSize = %d, fragPeriod = %d, winSize = %d\n",
		   rptr[i].dataSize, rptr[i].fragSize, rptr[i].fragPeriod, rptr[i].winSize);
	       dbg(DBG_USR1, "nackPeriod = %d, fatalTimeout = %d, currNackTimeout = %d\n",
		   rptr[i].nackPeriod, rptr[i].fatalTimeout, rptr[i].currNackTimeout);
	       dbg(DBG_USR1, "startFrag = %d, connState = %d \n",
		   rptr[i].startFrag, rptr[i].connState);
	       dbg(DBG_USR1, 
		   "nackMainTimer = %d, nackShortTimer = %d, nackDataTimeout = %d, lastAckResendTimer = %d \n",
		   rptr[i].nackMainTimer, rptr[i].nackShortTimer, rptr[i].nackDataTimeout, 
		   rptr[i].lastAckResendTimer);
	       

	       for(j = 0; j < rptr[i].winSize/8; j++){
		   dbg(DBG_USR1, "ackBitmap[%d] =%x ", j, rptr[i].ackBitmap[j]);
	       }
	       dbg(DBG_USR1, "\n");
	   }
	   if(pState == 1  && i == REL_MAX_CONN_NUM -1){
	       dbg(DBG_USR1, "********PrintConnParams END*************\n");
	   }
       }



   }


#endif

   task void processNackTimers(){
       uint8_t i;
       
       //       dbg(DBG_USR1, "FabApp: Calling processNackTimer \n");
#if PLATFORM_PC
       printConnParams();
#endif

       for(i = 0; i< REL_MAX_CONN_NUM; i++){
	   if(relConnParams[i].unusedIndex == FALSE){
	       if(relConnParams[i].nackMainTimer  == 0){
		   
		   relConnParams[i].nackMainTimer  = 
		       relConnParams[i].nackPeriod;
		   
		   relConnParams[i].nackShortTimer = 
		       REL_NMAX_ACKS * relConnParams[i].fragPeriod + 
		     relConnParams[i].netDelay;
		   
		   relConnParams[i].nackDataTimeout = 	    
		       relConnParams[i].fatalTimeout;
		   
		   relConnParams[i].nackSeq++;
		   SendNack(i);
	       }
	       else{
		   relConnParams[i].nackMainTimer -= REL_MAIN_TIMER;
	       }
	       
	       
	       
	       if(relConnParams[i].nackShortTimer  != 0){
		   
		   relConnParams[i].nackShortTimer -= REL_MAIN_TIMER;
		   if(relConnParams[i].nackShortTimer  ==0){
		       SendNack(i);
		   }
	       }
	       
	       if(relConnParams[i].nackDataTimeout  != 0){
		   
		   relConnParams[i].nackDataTimeout -= REL_MAIN_TIMER;
		   if(relConnParams[i].nackDataTimeout  ==0){
		       signal VarRecv.recvDone(relConnParams[i].handle, FAIL);
		       relConnParams[i].unusedIndex = TRUE;
		       return;
		   }
	       }
	       if(relConnParams[i].lastAckResendTimer != 0){
		   relConnParams[i].lastAckResendTimer--;
		   if((relConnParams[i].lastAckResendTimer%REL_RESEND_ACK_RESEND_TIMER) 
		      == 0){
		       if(relConnParams[i].lastAckResendTimer == 0){
			   // hit max tries, so signal fail to upper layer
			   // signal SendLargeBuf.sendLargeBufDone[currApp](sendBuf,FAIL);
			   relConnParams[i].unusedIndex = TRUE;
			   signal VarRecv.recvDone(relConnParams[i].handle,FAIL);
		       }
		       else{
			   SendLastAck(i);
		       }
		   }
	       }
	       
	   }
	       
	       
       }
   }
       
   

   

   task void SendConnRej();

   task void SendConnAcc();

   task void checkTimer(){
       if(connReqResendTimer != 0){
	   connReqResendTimer--;
	   if((connReqResendTimer%REL_RESEND_CONN_REQ_TIMER) == 0){
	       if(connReqResendTimer == 0){
		   // hit max tries, so signal fail to upper layer
		   //		   signal SendLargeBuf.sendLargeBufDone[currApp](sendBuf,FAIL);
		   sendPacketPending  = FALSE;
		   signal VarSend.sendDone(connHandle,FAIL);
		   currConnAcc = FALSE;
	       }
	       else{
		   if(sendConnReqTask == REL_TASK_DONE){
#if USE_LEDS
		     //   call Leds.redToggle();
#endif
		       sendConnReqTask = REL_TASK_PENDING;
		       post SendConnReq();
		   }
	       }
	   }
       }
       
       
       if(sendConnReqTask == REL_TASK_POST_REQ){
	   sendConnReqTask = REL_TASK_PENDING;
	   post SendConnReq();
       }

       if(processSendDoneTask == REL_TASK_POST_REQ){
	   processSendDoneTask = REL_TASK_PENDING;
	   post processSendDone();
       }
       
       if(sendConnRejTask == REL_TASK_POST_REQ){
	   sendConnRejTask = REL_TASK_PENDING;
	   post SendConnRej();
       }
       
       if(sendDataPacketTask == REL_TASK_POST_REQ){
	   sendDataPacketTask = REL_TASK_PENDING;
	   DisplayStr("ReliableTransport: Reposting SendDone\n"); 	  
	   dbg(DBG_USR1, "ReliableTransport: Reposting SendDone\n"); 	  
	   post SendDataPacket();
       }
       
       if(sendConnAccTask == REL_TASK_POST_REQ){
	   sendConnAccTask = REL_TASK_PENDING;
	   post SendConnAcc();
       }
       
       
   }
   

   event result_t Timer.fired() {
       
       
       post checkTimer();       
       
       post processNackTimers(); // too long to do in an event


       return SUCCESS;
   }


   uint16_t getNextSendFrag(bool incCheck){
       
       uint16_t byte, bit;
       bool found = FALSE;
       uint8_t mask;
       uint16_t tmpFrag = currFrag;
#if PLATFORM_PC
       uint8_t i;
#endif
       
       if(incCheck){
	   tmpFrag++;
       }
#ifdef RELIABLE_TRANSPORT_DEBUG
       sprintf(temp, "ReliableTransport: GetNextFrag currStartFrag = %d, tmpFrag = %d\n ", 
	   incCheck,  tmpFrag);
       DisplayStr(temp);
#endif
          
       dbg(DBG_USR1, "ReliableTransport: GetNextFrag currStartFrag = %d, tmpFrag = %d\n ", 
	   incCheck,  tmpFrag);
       
#if PLATFORM_PC
       for(i = 0; i<REL_ACK_STATUS_ARRAY_SIZE ; i++){

       dbg(DBG_USR1, "ReliableTransport: GetNextFrag: sendAckStatus[%d] = %x\n ", 
	   i, sendAckStatus[i]);

       }
#endif


       while(found == FALSE){
	   byte = (tmpFrag - currStartFrag)/8;
	   bit  = ((tmpFrag - currStartFrag)%8);
	   
	   mask = (0x80 >> bit);
	   
	   if(mask & sendAckStatus[byte]){
	       
	       tmpFrag++;
	       if(tmpFrag == (currStartFrag + REL_WIN_SIZE-1) || tmpFrag == lastFrag){
		   // should never happen, but just in case this provides a graceful
		   // recovery by simply resending an already sent packet
		   found = TRUE;
	       }
	   }
	   else{
	       found = TRUE;
	   }

       }
#ifdef RELIABLE_TRANSPORT_DEBUG
       sprintf(temp, "ReliableTransport: GetNextFrag inCheck = %d, tmpFrag = %d\n ", 
	   incCheck,  tmpFrag);
       DisplayStr(temp);
#endif
       dbg(DBG_USR1, "ReliableTransport: GetNextFrag inCheck = %d, tmpFrag = %d\n ", 
	   incCheck,  tmpFrag);
       return tmpFrag;
   }

   task void processSendDone(){
       uint16_t len;

#ifdef RELIABLE_TRANSPORT_DEBUG
       sprintf(temp, 
	   "ReliableTransport: ProcessSendDone currFrag = %d, currStartFrag = %d, sendState = %d, lastFrag = %d \n", 
	   currFrag, currStartFrag, sendState, lastFrag);
       DisplayStr(temp);
#endif
       dbg(DBG_USR1, 
	   "ReliableTransport: ProcessSendDone currFrag = %d, currStartFrag = %d, sendState = %d, lastFrag = %d \n", 
	   currFrag, currStartFrag, sendState, lastFrag);

       if(processSendDoneTask == REL_TASK_DONE){
	 return;
       }
       
       if(sendState == REL_SEND_PACKETS_RESEND){
	   currFrag = getNextSendFrag(FALSE);
	   
	   // test to see if a frag beyond the current window has been returned
	   if(currFrag > (currStartFrag + REL_WIN_SIZE-1) || currFrag > lastFrag){
	     currFrag--; // to set it to correct end value
	     sendState = REL_SEND_PACKETS_DONE;
	     processSendDoneTask = REL_TASK_DONE;
	     return;
	   }
	   
	   sendMsg = call GenericPacket.AllocateBuffer(DestAddr, REL_DATA_LEN+maxFragSize);
	   if(sendMsg == NULL){
	       // Should never happen -- because there is only one send connection

	   }
	   
	   rData = (RelDataPtr)call GenericPacket.GetPayloadStart((uint8_t*)sendMsg, &len);
	   rData->rHead.mtc   = REL_DATA;
	   rData->rHead.appId = APP_ID_RELIABLE_TRANSPORT;
	   rData->rHead.tId   = tId;
	   rData->fragIndex   = currFrag;  

	   if(!signal VarSend.pullSegReq(connHandle, currFrag*maxFragSize, 
					 sendFragStore, maxFragSize)){
	       sendState = REL_SEND_PACKETS_DONE;
	       call GenericPacket.FreeBuffer(sendMsg);
	   }
	   else{
	       sendState = REL_SEND_PACKETS_SEND;
	   }
	   processSendDoneTask = REL_TASK_DONE;
	   return;   
       }

       if(currFrag != (currStartFrag + REL_WIN_SIZE-1) && currFrag != lastFrag){
	   currFrag = getNextSendFrag(TRUE);

	   // test to see if a frag beyond the current window has been returned
	   if(currFrag > (currStartFrag + REL_WIN_SIZE-1) || currFrag > lastFrag){
	     currFrag--; // to set it to correct end value
	     sendState = REL_SEND_PACKETS_DONE;
	     processSendDoneTask = REL_TASK_DONE;
	     return;
	   }


	   sendMsg = call GenericPacket.AllocateBuffer(DestAddr, REL_DATA_LEN+maxFragSize);
	   if(sendMsg == NULL){
	       // Should never happen -- because there is only one send connection
	       
	   }
	   
	   rData = (RelDataPtr)call GenericPacket.GetPayloadStart((uint8_t*)sendMsg, &len);
	   
	   rData->rHead.mtc   = REL_DATA;
	   rData->rHead.appId = APP_ID_RELIABLE_TRANSPORT;
	   rData->rHead.tId   = tId;
	   rData->fragIndex   = currFrag;  

	   sendState = REL_SEND_PACKETS_SEND;
	   
	   if(!signal VarSend.pullSegReq(connHandle, currFrag*maxFragSize, 
					 sendFragStore, maxFragSize)){
	       sendState = REL_SEND_PACKETS_DONE;
	       call GenericPacket.FreeBuffer(sendMsg);
	   }
	   processSendDoneTask = REL_TASK_DONE;
	   
	   
       }
       else{
	 sendState = REL_SEND_PACKETS_DONE;
       }
       processSendDoneTask = REL_TASK_DONE;
       
   }


   event result_t GenericPacket.SendDone(uint8_t* Buffer, result_t success) {
       DisplayStr("ReliableTransport: SendDone\n"); 	  
       dbg(DBG_USR1, "ReliableTransport: SendDone\n"); 	  
       if(Buffer == sendMsg){
	   DisplayStr("ReliableTransport: Calling ProcessSendDone\n"); 	  
	   dbg(DBG_USR1, "ReliableTransport: Calling ProcessSendDone\n"); 	  
	   call GenericPacket.FreeBuffer(Buffer);
	   processSendDoneTask = REL_TASK_PENDING;
	   post processSendDone();
	   sendPending = FALSE;
	   return SUCCESS;
       }
       else{
	   if(Buffer == msg){
	       call GenericPacket.FreeBuffer(Buffer);
	       sendPending = FALSE;
	       return SUCCESS;
	   }
       }
       DisplayStr("ReliableTransport: Couldn't release buffer\n"); 	  
       
       return FAIL;
   }





   task void sigSendFail(){
       if(sigSendFailTask != REL_TASK_DONE){
	   sendPacketPending  = FALSE;
	   signal VarSend.sendDone(connHandle, FAIL);
	   currConnAcc = FALSE;
	   sigSendFailTask = REL_TASK_DONE;
	   sendConnReqTask    = REL_TASK_DONE;
       }
   }


   task void processNack(){
       uint16_t len;   
       uint8_t i;
  
#if USE_LEDS
       //       call Leds.redOff();
#endif
       
#ifdef RELIABLE_TRANSPORT_DEBUG
       sprintf(temp, 
	   "ReliableTransport: ProcessNack sendState = %d and processSenDoneTask %d\n",
	   sendState,processSendDoneTask);  
       DisplayStr(temp);
#endif
       dbg(DBG_USR1, 
	   "ReliableTransport: ProcessNack sendState = %d and processSenDoneTask %d\n",
	   sendState,processSendDoneTask);  
       if(processNackTask == REL_TASK_DONE){
	 return;
       }

       if(sendState != REL_SEND_PACKETS_DONE){
	   
	   sendState = REL_SEND_PACKETS_RESEND;
	   currStartFrag = tmpStartFrag;
	   currFrag  = tmpStartFrag;
	   for(i = 0; i<REL_ACK_STATUS_ARRAY_SIZE ; i++){
	       sendAckStatus[i] = tmpSendAckStatus[i];
	   }
	   processNackTask = REL_TASK_DONE;
	   return;
       }
       else{

	 if(processSendDoneTask != REL_TASK_DONE){
	   processNackTask = REL_TASK_DONE;
	   return;
	 }
	 
	 sendState = REL_SEND_PACKETS_SEND;
	 currStartFrag = tmpStartFrag;
	 currFrag  = tmpStartFrag;
	 for(i = 0; i<REL_ACK_STATUS_ARRAY_SIZE ; i++){
	   sendAckStatus[i] = tmpSendAckStatus[i];
	 }
	 currFrag = getNextSendFrag(FALSE);
	 if(currFrag <= lastFrag){
	   
	   sendMsg = 
	     call GenericPacket.AllocateBuffer(DestAddr, REL_DATA_LEN+maxFragSize);
	   if(sendMsg == NULL){
	     // Should never happen -- because there is only one send connection

	   }
	       
	       rData = (RelDataPtr) call GenericPacket.GetPayloadStart((uint8_t*)sendMsg, &len);
	       
	       rData->rHead.mtc   = REL_DATA;
	       rData->rHead.appId = APP_ID_RELIABLE_TRANSPORT;
	       rData->rHead.tId   = tId;
	       rData->fragIndex   = currFrag;  
	       
	       if(!signal VarSend.pullSegReq(connHandle, currFrag*maxFragSize, 
					     sendFragStore, maxFragSize)){
		   sendState = REL_SEND_PACKETS_DONE;
		   call GenericPacket.FreeBuffer(sendMsg);
	       }
	       
	 }  
	 processNackTask = REL_TASK_DONE;
	   
       }       
       
       
   }

  //for debugging
   uint8_t DummyFunc(){
    uint8_t i,j;
    for(i = 0; i<1; i++){
      i = j;
    }
    return j;
  }
   
   task void processLastAck(){
       RelRecLastAckPtr rRecLastAck;
       uint16_t len;

       if(processLastAckTask == REL_TASK_DONE){
	 return;
       }
       if(sendPacketPending && lastAckTid == tId){
	   sendPacketPending  = FALSE;

	   signal VarSend.sendDone(connHandle, SUCCESS);
	   currConnAcc = FALSE;
       }

       if(!sendPending){
	   DisplayStr("ReliableTransport: Sending RecLastAck \n"); 
	   dbg(DBG_USR1, "ReliableTransport: Sending RecLastAck \n"); 

	   msg = call GenericPacket.AllocateBuffer(DestAddr, REL_CONN_REQ_LEN);
	   if(msg == NULL){
	     processLastAckTask = REL_TASK_DONE;
	       return;
	   }
	   rRecLastAck = 
	     (RelRecLastAckPtr) call GenericPacket.GetPayloadStart((uint8_t*)msg, 
									    &len);

	  
	   rRecLastAck->rHead.mtc = REL_REC_LAST_ACK;
	   rRecLastAck->rHead.tId = lastAckTid;
	   rRecLastAck->rHead.appId = APP_ID_RELIABLE_TRANSPORT;

	   if(!sendPending &&  call GenericPacket.Send(DestAddr, msg, 
						       REL_REC_LAST_ACK_LEN)){
	       sendPending = TRUE;
	   }
	   else{
	       call GenericPacket.FreeBuffer(msg);
	   }
       }
       processLastAckTask = REL_TASK_DONE;
   }



   task void processConnAcc(){
       uint16_t len;   
       uint8_t i;
       
       if(processConnAccTask == REL_TASK_DONE || currConnAcc){
	 processConnAccTask = REL_TASK_DONE;
	 return;
       }
	//call Leds.greenOn();   	
       currConnAcc = TRUE;
       //initialize send vars
       sendState = REL_SEND_PACKETS_SEND;
       currStartFrag = 0;
       currFrag      = 0;
       connReqResendTimer = 0;
       // assumes that the if connection is accepted then the same parameters 
       // as ConnReq are used
       
       // note: following logic assumes that packetsize >= 0
       lastFrag    =  ((packetSize - 1)/maxFragSize);
       sendMsg = call GenericPacket.AllocateBuffer(DestAddr, REL_DATA_LEN+maxFragSize);
       
       if(sendMsg == NULL){
	   // Should never happen -- because there is only one send connection
	   
       }
       
       rData = (RelDataPtr)call GenericPacket.GetPayloadStart((uint8_t*)sendMsg, &len);
       
       
       rData->rHead.mtc   = REL_DATA;
       rData->rHead.appId = APP_ID_RELIABLE_TRANSPORT;
       rData->rHead.tId   = tId;
       rData->fragIndex   = currFrag; 
       
       
       lastNackSeq = 0;
       DisplayStr("ReliableTransport: Posting a get seg req\n");
       dbg(DBG_USR1, "ReliableTransport: Posting a get seg req\n");
       for(i = 0; i < REL_ACK_STATUS_ARRAY_SIZE; i++){
	   sendAckStatus[i] = 0;
       }
       sendConnReqTask    = REL_TASK_DONE;
       
       if(!signal VarSend.pullSegReq(connHandle, 0, sendFragStore, maxFragSize)){
	   sendState = REL_SEND_PACKETS_DONE;
	   call GenericPacket.FreeBuffer(sendMsg);
       }

       processConnAccTask = REL_TASK_DONE;

   }


#if ENABLE_EEPROM
  task void saveState(){
    rtInfo.validData = TRUE;
    rtInfo.tId = tId;
    rtInfo.packetSize = packetSize;
    rtInfo.sendPacketPending = sendPacketPending;
    rtInfo.lastFrag = lastFrag;
    rtInfo.maxFragSize = maxFragSize;
    rtInfo.currApp = currApp;
    rtInfo.DestAddr = DestAddr;
    rtInfo.currConnAcc = currConnAcc;

    signal State.currentState(&rtInfo);
    post processConnAcc();
  }
#endif

   // Purpose: Receive the various command on the send side. For e.g. ConnAccept, LastAck, and Ack
   // hooks up to flood in the current version

   result_t ReceiveCmdReceive(wsnAddr Source, void* payload, uint16_t len) {
       RelHeaderPtr rHead = (RelHeaderPtr) payload;
       RelNackPtr   rNack = (RelNackPtr) payload;
       uint8_t i;
       DisplayStr("ReliableTransport: GOT a Command on Receive\n");
       dbg(DBG_USR1, "ReliableTransport: GOT a Command on Receive\n");
       
       switch(rHead->mtc){
       case REL_CONN_ACC:
	   DisplayStr("ReliableTransport: GOT a ConnAcc\n");
	   dbg(DBG_USR1, "ReliableTransport: GOT a ConnAcc\n");
	   if(rHead->tId != tId || currConnAcc || processConnAccTask != REL_TASK_DONE){
	       break;
	   }
	   processConnAccTask = REL_TASK_PENDING;
#if ENABLE_EEPROM
	   post saveState();
#else
	   post processConnAcc();
#endif
	   break;

       case REL_CONN_REJ:
	   if(!currConnAcc && sigSendFailTask == REL_TASK_DONE){
	       sigSendFailTask = REL_TASK_PENDING;
	       post sigSendFail();
	   }
	   break;
       case REL_NACK:
#if USE_LEDS
	 //	 call Leds.redOn();
#endif
#ifdef RELIABLE_TRANSPORT_DEBUG
	   sprintf(temp, 
	       "ReliableTransport:GOT NACK rNacktid=%d tid=%d,currConnAcc=%d, Nacktask=%d",
	       rNack->rHead.tId, tId,currConnAcc,processNackTask);
           DisplayStr(temp);
#endif
	   dbg(DBG_USR1, 
	       "ReliableTransport:GOT NACK rNacktid=%d tid=%d,currConnAcc=%d, Nacktask=%d",
	       rNack->rHead.tId, tId,currConnAcc,processNackTask);

	   if(rHead->tId != tId || !currConnAcc || processNackTask != REL_TASK_DONE){
	       break;
	   }
	   if(rNack->rHead.tId == tId){
	   // assumes that the very first Nack starts with seq# 1 and not 0
	       if(rNack->seq == lastNackSeq){
		   // ignore
		   break;
	       }
 
	       // 230 is arbitary number to check for wraparound assuming 256 to 
	       // be the max seq# as it is uint8_t
#ifdef RELIABLE_TRANSPORT_DEBUG
	       sprintf(temp, 
		   "ReliableTransport: GOT NACK packet nackSeq = %d, lastNackSeq = %d\n", 
		   rNack->seq, lastNackSeq);
               DisplayStr(temp);
#endif
	       dbg(DBG_USR1, 
		   "ReliableTransport: GOT NACK packet nackSeq = %d, lastNackSeq = %d\n", 
		   rNack->seq, lastNackSeq);

#if PLATFORM_PC
	       dbg(DBG_USR1, 
		   "ReliableTransport: GOT NACK packet startFrag = %d \n Nack bits = ", 
		   rNack->startFrag); 
	       for(i = 0; i < REL_ACK_STATUS_ARRAY_SIZE; i++){
		   dbg(DBG_USR1, "%x ",rNack->data[i]);
	       }
	       dbg(DBG_USR1, "\n");
#endif
	      if(rNack->seq > lastNackSeq 
		   || (lastNackSeq - rNack->seq) > 230 ){
		  
		  tmpStartFrag = rNack->startFrag;
		  
		  if(tmpStartFrag == 256){
		    DummyFunc();
		  }

		  for(i = 0; i < REL_ACK_STATUS_ARRAY_SIZE; i++){
		      tmpSendAckStatus[i] = rNack->data[i];
		  }

		  
		  if(processNackTask == REL_TASK_DONE){
		      processNackTask = REL_TASK_PENDING;
		      post processNack();
		  }
		
	      }
	      lastNackSeq  = rNack->seq;
	   }
	   break;
       case REL_LAST_ACK:
	 if(!currConnAcc){
	   break;
	 }
	 lastAckTid = rHead->tId;
	 DisplayStr("ReliableTransport: Got LastAck \n"); 
	 dbg(DBG_USR1, "ReliableTransport: Got LastAck \n"); 
	 processLastAckTask = REL_TASK_PENDING;
	 post processLastAck();
	 break;
	   
       default:
	   return FAIL;
       }
       return SUCCESS;
   }
   






//******************************************************************************************
//_______________________________________Receive Portion starts_____________________________

//******************************************************************************************
   task void SendConnRej(){

       RelConnRejPtr rConnRej;
       uint16_t len;
       
       if(sendConnRejTask != REL_TASK_DONE){
	   
	   //should be done before getbuffer to avoid clobbering the message buffer
	   if(sendPending){
	       sendConnRejTask = REL_TASK_POST_REQ;
	       return;
	   }


	   msg = call GenericPacket.AllocateBuffer(relConnParams[connAccIndex].addr, 
					  REL_CONN_REJ_LEN);
	   
	   if(msg == NULL){
	       sendConnRejTask = REL_TASK_POST_REQ;
	       return;
	   }
	   
	   rConnRej = (RelConnRejPtr) call GenericPacket.GetPayloadStart((uint8_t*)msg, &len);



	   
	   rConnRej->rHead.mtc = REL_CONN_REJ;
	   rConnRej->rHead.appId = APP_ID_RELIABLE_TRANSPORT;
	   rConnRej->rHead.tId = connRejTid;
	   rConnRej->reasonCode = connRejReason;
	   

	   
	   if(!sendPending && call GenericPacket.Send(connRejAddr, msg, REL_CONN_REJ_LEN)){
	       DisplayStr("RT: sendConnRej: SUCCESS \n"); 
	       dbg(DBG_USR1, "RT: sendConnRej: SUCCESS \n"); 
	       sendPending = TRUE;
	       sendConnRejTask = REL_TASK_DONE;
	   }
	   else{
	       DisplayStr("RT: sendConnRej: FAIL \n"); 
	       dbg(DBG_USR1, "RT: sendConnRej: FAIL \n"); 
	       call GenericPacket.FreeBuffer(msg);
	       sendConnRejTask = REL_TASK_POST_REQ;
	   }
       }
   }




   void SendLastAck(uint8_t i){
       RelLastAckPtr rLastAck;
       uint16_t len;

       if(!sendPending){

	   msg = call GenericPacket.AllocateBuffer(relConnParams[connAccIndex].addr, 
					  REL_LAST_ACK_LEN);
	   
	   if(msg != NULL){
	       
	       
	       rLastAck = (RelLastAckPtr) call GenericPacket.GetPayloadStart((uint8_t*)msg, &len);
	       
	       

	       rLastAck->rHead.mtc = REL_LAST_ACK;
	       rLastAck->rHead.tId = relConnParams[i].tId;
	       rLastAck->rHead.appId = APP_ID_RELIABLE_TRANSPORT;
	       DisplayStr("Sending Last Ack \n"); 	   
	       dbg(DBG_USR1, "Sending Last Ack \n"); 	   
	       if(call GenericPacket.Send(relConnParams[i].addr,msg, 
					  REL_LAST_ACK_LEN)){
		   sendPending = TRUE;
	       }
	       else{
		   call GenericPacket.FreeBuffer(msg);
	       }
	   }
	   
       }
       if(relConnParams[i].lastAckResendTimer == 0){ // only need to do it the first time
	   relConnParams[i].lastAckResendTimer = (REL_RESEND_ACK_RESEND_TIMER * 
				 REL_RESEND_ACK_RESEND_MAX_TRIES);
	   relConnParams[i].nackMainTimer  = 0;
	   
	   relConnParams[i].nackShortTimer = 0;
	   
	   relConnParams[i].nackDataTimeout = 0;
	   
       }
       
       
   }


   task void SendConnAcc(){
       RelConnAccPtr rConnAcc;
       uint16_t len;
       
       if(sendConnAccTask != REL_TASK_DONE){
	   
	//should be done before getbuffer to avoid clobbering the message buffer
	   if(sendPending){
	       sendConnAccTask = REL_TASK_POST_REQ;
	       return;
	   }

	   msg = call GenericPacket.AllocateBuffer(relConnParams[connAccIndex].addr, 
					  REL_CONN_REQ_LEN);

	   if(msg == NULL){
	       sendConnAccTask = REL_TASK_POST_REQ;
	       return;
	   }

	   rConnAcc = (RelConnAccPtr) call GenericPacket.GetPayloadStart((uint8_t*)msg, 
										   &len);
	   rConnAcc->rHead.mtc                    = REL_CONN_ACC;
	   rConnAcc->rHead.appId                  = APP_ID_RELIABLE_TRANSPORT;
	   rConnAcc->rHead.tId                    = relConnParams[connAccIndex].tId;
	   rConnAcc->dataSize                     = relConnParams[connAccIndex].dataSize;
	   rConnAcc->fragSize                     = relConnParams[connAccIndex].fragSize;
	   rConnAcc->nackPeriod                   = relConnParams[connAccIndex].nackPeriod;
	   rConnAcc->winSize                      = relConnParams[connAccIndex].winSize;
	   
	   
	   if(!sendPending && call GenericPacket.Send(relConnParams[connAccIndex].addr, 
				      msg, REL_CONN_ACC_LEN)){
	       DisplayStr("RT: sendAccept: SUCCESS \n"); 
	       dbg(DBG_USR1, "RT: sendAccept: SUCCESS \n"); 
	       sendConnAccTask = REL_TASK_DONE;
	       sendPending = TRUE;
	       sendConnAccTask = REL_TASK_DONE;
	       return;
	   }
	   else{
	       DisplayStr("RT: sendAccept: FAIL \n"); 
	       dbg(DBG_USR1, "RT: sendAccept: FAIL \n"); 
	       call GenericPacket.FreeBuffer(msg);
	       sendConnAccTask = REL_TASK_POST_REQ;
	       return;
	   }
       }
   }
   
bool alreadyReceived(uint8_t idx, uint16_t frag){
    uint8_t byte, bit;
    uint8_t mask;
    uint16_t lFrag;
    
    lFrag = (relConnParams[idx].dataSize -1)/relConnParams[idx].fragSize;

#ifdef RELIABLE_TRANSPORT_DEBUG
    sprintf(temp, "ReliableTransport: Calling alreadyreceived with idx = %d, frag = %d\n", idx, frag); 
    DisplayStr(temp);
#endif
    dbg(DBG_USR1, "ReliableTransport: Calling alreadyreceived with idx = %d, frag = %d\n", idx, frag); 
    if(frag < relConnParams[idx].startFrag || frag > lFrag ){ 
	// frag > lFrag should never happen
	return TRUE;
    }
    if(frag >= relConnParams[idx].startFrag + relConnParams[idx].winSize){
	//should not happen
	return TRUE; // cannot handle it. Beyind the window size.
    }

    
    byte = (frag - relConnParams[idx].startFrag)/8;
    bit = ((frag - relConnParams[idx].startFrag)%8);
    
    mask = (0x80 >> bit);

    if(mask & relConnParams[idx].ackBitmap[byte]){
	DisplayStr("ReliableTransport: Alreadyreceived returning TRUE\n"); 
	dbg(DBG_USR1, "ReliableTransport: Alreadyreceived returning TRUE\n"); 
	return TRUE;
    }
    DisplayStr("ReliableTransport: Alreadyreceived returning FALSE\n"); 
    dbg(DBG_USR1, "ReliableTransport: Alreadyreceived returning FALSE\n"); 
    return FALSE;
    

}

void updateAckStatus(){
    uint8_t byte, bit, maxByte;
    uint8_t mask;
    uint8_t i;
    uint8_t byteShifts, bitShifts;
    


    byte = (lastRecFrag - relConnParams[lastDataIndex].startFrag)/8;
    bit  = ((lastRecFrag - relConnParams[lastDataIndex].startFrag)%8);
    
    mask = (0x80 >>bit);
    
    relConnParams[lastDataIndex].ackBitmap[byte] |= mask;

#ifdef RELIABLE_TRANSPORT_DEBUG
    sprintf(temp, "ReliableTransport: Calling updateackstatus lastRecFrag = %d, byte = %d, bit = %d\n", 
	lastRecFrag, byte, bit); 
    DisplayStr(temp);
#endif
    dbg(DBG_USR1, "ReliableTransport: Calling updateackstatus lastRecFrag = %d, byte = %d, bit = %d\n", 
	lastRecFrag, byte, bit); 

    if(lastRecFrag != relConnParams[lastDataIndex].startFrag){
	return;
    }
    else{

	maxByte =  (relConnParams[lastDataIndex].winSize)/8;
	
	byteShifts = 0;
	for(i = 0; i< maxByte; i++){
	    if(relConnParams[lastDataIndex].ackBitmap[i] != 0xFF){
		break;
	    }
	}
	
	byteShifts = i;
	if(i == maxByte){
	    relConnParams[lastDataIndex].startFrag = 
		relConnParams[lastDataIndex].startFrag + 
		relConnParams[lastDataIndex].winSize;

	    for(i = 0; i < maxByte; i++){
		relConnParams[lastDataIndex].ackBitmap[i] = 0;
	    }
	    byteShifts = 0; // done all we need

	}

	bitShifts = 0;
	mask = 0x80;
	for(i = 0; i< 8; i++){
	    if(!(relConnParams[lastDataIndex].ackBitmap[byteShifts] & mask)){
		break;
	    }
	    mask = (mask >> 1);
	}

	bitShifts = i;

	if(byteShifts != 0){
	    for(i =0; i < maxByte-1; i++){
		if((i+byteShifts) >= maxByte){
		    relConnParams[lastDataIndex].ackBitmap[i] = 0;
		}
		else{
		    relConnParams[lastDataIndex].ackBitmap[i] = 
			relConnParams[lastDataIndex].ackBitmap[i+byteShifts];
		}
	    }
	}

	if(bitShifts != 0){
	    for(i =0; i < maxByte-byteShifts; i++){
#ifdef RELIABLE_TRANSPORT_DEBUG
		sprintf(temp, "ReliableTransport: updateackstatus bitmap[%d]= %x\n", 
		    i, relConnParams[lastDataIndex].ackBitmap[i]);
                DisplayStr(temp);
#endif
		dbg(DBG_USR1, "ReliableTransport: updateackstatus bitmap[%d]= %x\n", 
		    i, relConnParams[lastDataIndex].ackBitmap[i]);
		relConnParams[lastDataIndex].ackBitmap[i] = 
		    (relConnParams[lastDataIndex].ackBitmap[i+byteShifts]<<bitShifts);
#ifdef RELIABLE_TRANSPORT_DEBUG
		sprintf(temp, "ReliableTransport: updateackstatus bitmap[%d]= %x\n", 
		    i, relConnParams[lastDataIndex].ackBitmap[i]);
                DisplayStr(temp);
#endif
		dbg(DBG_USR1, "ReliableTransport: updateackstatus bitmap[%d]= %x\n", 
		    i, relConnParams[lastDataIndex].ackBitmap[i]);
		mask = (maskArray[bitShifts-1] & relConnParams[lastDataIndex].ackBitmap[i+1]);
		mask = (mask >> (8-bitShifts));
		relConnParams[lastDataIndex].ackBitmap[i] = 
		    (relConnParams[lastDataIndex].ackBitmap[i] | mask) ;

#ifdef RELIABLE_TRANSPORT_DEBUG
		sprintf(temp, "ReliableTransport: updateackstatus mask = %x, bitmap[%d]= %x\n", 
		    mask, i, relConnParams[lastDataIndex].ackBitmap[i]);
                DisplayStr(temp);
#endif
		dbg(DBG_USR1, "ReliableTransport: updateackstatus mask = %x, bitmap[%d]= %x\n", 
		    mask, i, relConnParams[lastDataIndex].ackBitmap[i]);
		
		
	    }
	}
	relConnParams[lastDataIndex].startFrag += ((byteShifts*8) + bitShifts);
	
	
	if( relConnParams[lastDataIndex].startFrag > 
	   ((relConnParams[lastDataIndex].dataSize -1)/
	    relConnParams[lastDataIndex].fragSize)){

	    // last packet done
	    DisplayStr("ReliableTransport: updateackstutus: calling SendLastAck\n");
	    dbg(DBG_USR1, "ReliableTransport: updateackstutus: calling SendLastAck\n");
	    SendLastAck(lastDataIndex);
	}
	    

    }
    
#ifdef RELIABLE_TRANSPORT_DEBUG
    sprintf(temp, "ReliableTransport: updateackstatus end byteShifts = %d, bitShifts = %d \n",
	byteShifts, bitShifts);
    DisplayStr(temp);
#endif
    dbg(DBG_USR1, "ReliableTransport: updateackstatus end byteShifts = %d, bitShifts = %d \n",
	byteShifts, bitShifts);
}


task void processRelData(){

    

    if(signal VarRecv.putSegReq(relConnParams[lastDataIndex].handle, 
				lastRecFrag * relConnParams[lastDataIndex].fragSize,
				relConnParams[lastDataIndex].tmpFragStore,
				relConnParams[lastDataIndex].fragSize)){
	updateAckStatus();

    }
    processRelDataTask = REL_TASK_DONE;
}


//Purpose: Receive commands and data on the receive side. 
//This currently uses the DSDV protocol

result_t ReceiveReceive(wsnAddr source, void *payload, uint16_t len){
    
    RelHeaderPtr rHead = (RelHeaderPtr) payload;
    RelConnReqPtr rConn = (RelConnReqPtr)payload;
    RelDataPtr lRData = (RelDataPtr)payload;
    //    RelRecLastAckPtr rRecLastAck = (RelRecLastAckPtr)payload;
    uint8_t i,j;
    uint16_t lFragSize;

    DisplayStr("ReliableTransport: GOT DSDV packet\n");
    dbg(DBG_USR1, "ReliableTransport: GOT DSDV packet\n");
    switch(rHead->mtc){
    case REL_CONN_REQ:
	DisplayStr("ReliableTransport: GOT a ConnReq\n");
	dbg(DBG_USR1, "ReliableTransport: GOT a ConnReq\n");
	//First check if already accepted
	for(i = 0; i< REL_MAX_CONN_NUM; i++){
	    if(relConnParams[i].addr == source
	       && relConnParams[i].appId == rConn->rHead.appId
	       && relConnParams[i].tId == rConn->rHead.tId
	       && relConnParams[i].unusedIndex == FALSE){
		break;
	    }
	}

	if( i != REL_MAX_CONN_NUM){
	    if(relConnParams[i].connState == FALSE){
		break;
	    }
	    connAccIndex = i;
	    if(sendConnAccTask == REL_TASK_DONE){
		sendConnAccTask = REL_TASK_PENDING;
		DisplayStr("ReliableTransport: Posting a ConnAcc(Old conn)\n");
		dbg(DBG_USR1, "ReliableTransport: Posting a ConnAcc(Old conn)\n");
		post SendConnAcc();
	    }
	    
	    break;
	}
	
	for(i = 0; i < REL_MAX_CONN_NUM; i++){
	    if(relConnParams[i].unusedIndex == TRUE){
		break;
	    }
	}


#ifdef RELIABLE_TRANSPORT_DEBUG
	sprintf(temp,"ReliableTransport: Processing a ConnReq i = %d\n",i);
	DisplayStr(temp);
#endif
	dbg(DBG_USR1, "ReliableTransport: Processing a ConnReq i = %d\n",i);

	if(i != REL_MAX_CONN_NUM || ((rConn->fragSize %2) != 0)){

	    lastConnIndex = i;

	    // send connection accept
	    // For now the behaviour is to just accept whatever connection parameters are sent
	    // In future we may support connection parameter negotiation
	    dbg(DBG_USR1, "ReliableTransport: Got ConnReq with following params\n");
	    dbg(DBG_USR1, "ReliableTransport:appId=%d, tId =%d, ver=%d, dataSize=%d\n",
		rConn->rHead.appId, rConn->rHead.tId, rConn->ver, rConn->dataSize);
	    dbg(DBG_USR1, "ReliableTransport:fragSize=%d, fragPeriod=%d, winSize=%d\n",
		rConn->fragSize, rConn->fragPeriod, rConn->winSize);
	    dbg(DBG_USR1, "ReliableTransport: ConnReq Param list Ends\n");
	    relConnParams[lastConnIndex].addr           = source;
	
	    relConnParams[lastConnIndex].appId          = rConn->rHead.appId; 
	    relConnParams[lastConnIndex].tId            = rConn->rHead.tId; 
	    relConnParams[lastConnIndex].ver            = rConn->ver;
	    relConnParams[lastConnIndex].dataSize       = rConn->dataSize;
	    relConnParams[lastConnIndex].fragSize       = rConn->fragSize;
	    relConnParams[lastConnIndex].fragPeriod     = rConn->fragPeriod;
	    relConnParams[lastConnIndex].winSize        = rConn->winSize;
	    relConnParams[lastConnIndex].netDelay        = rConn->netDelay;
	    relConnParams[lastConnIndex].unusedIndex    = FALSE;
	    relConnParams[lastConnIndex].nackPeriod     = 
		rConn->fragPeriod*rConn->winSize + rConn->netDelay;

	    relConnParams[lastConnIndex].fatalTimeout   = 
		relConnParams[lastConnIndex].nackPeriod *REL_MAX_NACK_TRIES
	      + REL_MAX_DATA_STARTUP_TIME;
	    
	    relConnParams[lastConnIndex].nackMainTimer  = 
		relConnParams[lastConnIndex].nackPeriod
	      + REL_MAX_DATA_STARTUP_TIME;

	    relConnParams[lastConnIndex].nackShortTimer = 
		REL_NMAX_ACKS * relConnParams[lastConnIndex].fragPeriod 
	      + rConn->netDelay + REL_MAX_DATA_STARTUP_TIME;

	    relConnParams[lastConnIndex].nackDataTimeout = 	    
		relConnParams[lastConnIndex].fatalTimeout;
	    relConnParams[lastConnIndex].startFrag = 0;
	    relConnParams[lastConnIndex].nackSeq  = 1;
	    
	    for( j=0; j < REL_MAX_ACK_BITMAP_SIZE; j++){
		relConnParams[i].ackBitmap[j] = 0;
	    }
	    if(!signal VarRecv.recvReq(relConnParams[lastConnIndex].addr,
		relConnParams[lastConnIndex].dataSize, lastConnIndex)){
		// set these parameters up also in case the connection is rejected
		/*
		  // connection hasn't really been rejected. But, it can't be 
		  // processed right now
		connRejAddr   = source;
		connRejTid    = rConn->rHead.tId;

		connRejReason =  REL_CONN_REJ_MAX_CONN_ERR;
		if(sendConnRejTask == REL_TASK_DONE){
		    sendConnRejTask = REL_TASK_PENDING;
		    dbg(DBG_USR1, "ReliableTransport: Posting a ConnRej\n");
		    post SendConnRej();
		}
		*/
	    }
	    /*
	      else{
	      if(sendConnAccTask == REL_TASK_DONE){
	      sendConnAccTask = REL_TASK_PENDING;
	      dbg(DBG_USR1, "ReliableTransport: Posting a ConnAcc(New conn)\n");
	      post SendConnAcc();
	      }
	      }
	    */
	}
	else{
	    if(sendConnRejTask == REL_TASK_DONE){
		
		connRejAddr   = source;
		connRejTid    = rConn->rHead.tId;
		connRejReason =  REL_CONN_REJ_MAX_CONN_ERR;
		sendConnRejTask = REL_TASK_PENDING;
		DisplayStr("ReliableTransport: Posting a ConnRej\n");
		dbg(DBG_USR1, "ReliableTransport: Posting a ConnRej\n");
		post SendConnRej();
	    }
	}
	
	break;
    case REL_DATA:
	
	dbg(DBG_USR1, 
	    "ReliableTransport: GOT Data packet frag num %d, processRelDataTask = %d\n", 
	    lRData->fragIndex, processRelDataTask);
	
	dbg(DBG_USR1, "ReliableTransport: addr = %d, appId = %d, tId = %d\n",
	    source, rConn->rHead.appId, rConn->rHead.tId);

	if(processRelDataTask == REL_TASK_DONE){
	    

	    
	    for(i = 0; i< REL_MAX_CONN_NUM; i++){
		if(relConnParams[i].addr ==source
		   && relConnParams[i].appId == rConn->rHead.appId
		   && relConnParams[i].tId == rConn->rHead.tId
		   && relConnParams[i].unusedIndex == FALSE){
		    break;
		}
	    }
		
	    if(i == REL_MAX_CONN_NUM){
		break; // should never happen
	    }

	    DisplayStr("ReliableTransport: Found active connection\n"); 
	    dbg(DBG_USR1, "ReliableTransport: Found active connection\n"); 
	    if(lRData->fragIndex >= relConnParams[i].startFrag && 
	       !alreadyReceived(i, lRData->fragIndex)){

		lastDataIndex = i;
		
		relConnParams[i].nackShortTimer   = 0;
		relConnParams[i].nackDataTimeout  = relConnParams[i].fatalTimeout;;

		lastRecFrag = lRData->fragIndex;
		lFragSize = relConnParams[i].fragSize;
		for( j= 0; j< lFragSize; j++){
		    relConnParams[i].tmpFragStore[j] = lRData->data[j];
		}
		processRelDataTask = REL_TASK_PENDING;
		post processRelData();
	    }
	}

	break;
    case REL_REC_LAST_ACK:
#ifdef RELIABLE_TRANSPORT_DEBUG
	sprintf(temp, "RT: Got ReclastAck addr = %d, appId = %d, tId = %d\n",
	    source, rConn->rHead.appId,
	    rConn->rHead.tId);
        DisplayStr(temp);
#endif
	dbg(DBG_USR1, "RT: Got ReclastAck addr = %d, appId = %d, tId = %d\n",
	    source, rConn->rHead.appId,
	    rConn->rHead.tId);

 
	for(i = 0; i< REL_MAX_CONN_NUM; i++){
	    if(relConnParams[i].addr == source
	       && relConnParams[i].appId == rConn->rHead.appId
	       && relConnParams[i].tId == rConn->rHead.tId
	       && relConnParams[i].unusedIndex == FALSE){
		break;
	    }
	}

	if(i != REL_MAX_CONN_NUM){

	    relConnParams[i].lastAckResendTimer = 0; 
	    DisplayStr("RT: Calling recv done \n"); 
	    dbg(DBG_USR1, "RT: Calling recv done \n"); 
	    relConnParams[i].unusedIndex = TRUE;
	    signal VarRecv.recvDone(relConnParams[i].handle, SUCCESS);
	}
	
	break;
    default: // should never happen
	// signal error??
	break;
    }
    
    
    return SUCCESS;
}

   command result_t VarRecv.acceptRecv(void *Handle, uint8_t TransactionID){
       if(sendConnAccTask == REL_TASK_DONE){
	   DisplayStr("RT: Got VarRecv.acceptRecv\n");
	   dbg(DBG_USR1, "RT: Got VarRecv.acceptRecv\n");
	   connAccIndex = TransactionID;
	   sendConnAccTask = REL_TASK_PENDING;
	   relConnParams[TransactionID].connState = TRUE;
	   relConnParams[TransactionID].handle = Handle;
	   post SendConnAcc();
       }
       
       return SUCCESS;
   }

   command result_t VarRecv.rejectRecv(uint8_t TransactionID){
       if(sendConnRejTask == REL_TASK_DONE){
	   sendConnRejTask = REL_TASK_PENDING;
	   relConnParams[TransactionID].unusedIndex    = TRUE;
	   connRejReason =  REL_CONN_REJ_APP_ERR;
	   post SendConnRej();
       }
       
       return SUCCESS;
   }
   
   command result_t VarRecv.putSegDone(void *Handle, uint16_t MsgOffset){
       return SUCCESS;
   }
   command result_t VarRecv.abortRecv(void *Handle){
       return SUCCESS;
   }


   event result_t  GenericPacket.Receive(wsnAddr Source, 
					 uint8_t *Buffer, uint16_t PayloadSize){
       
       if (ReceiveCmdReceive(Source, Buffer,PayloadSize) == FAIL) {
	   ReceiveReceive(Source, Buffer, PayloadSize);
       }

       return SUCCESS;
   }
}

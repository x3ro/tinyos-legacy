/* -*-C-*- */
/**********************************************************************
Copyright ©2003 The Regents of the University of California (Regents).
All Rights Reserved.

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose, without fee, and without written 
agreement is hereby granted, provided that the above copyright notice 
and the following three paragraphs appear in all copies and derivatives 
of this software.

IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY 
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES 
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF 
THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE 
PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF 
CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, 
ENHANCEMENTS, OR MODIFICATIONS.

This software was created by Ram Kumar {ram@ee.ucla.edu}, 
Saurabh Ganeriwal {saurabh@ee.ucla.edu} at the 
Networked & Embedded Systems Laboratory (http://nesl.ee.ucla.edu), 
University of California, Los Angeles. Any publications based on the 
use of this software or its derivatives must clearly acknowledge such 
use in the text of the publication.
**********************************************************************/
/****************************************************************
 * TPSN: Timing Synchronization Protocol for Sensor Networks
 *---------------------------------------------------------------
 * Description: TPSN is a NTP-like protocol for establishing
 * fine grained timing synchronization between the nodes. Refer
 * to the following paper for more details:
 * "Timing Sync Protocol for Sensor Networks", SenSys 2003
 *---------------------------------------------------------------
 * Implementation Details:
 *
 * 1. The root node initially transmits a Level Discovery Message
 * (LDSMsg). The nodes receive it and further propagate this
 * message further into the network.
 *
 * 2. There is a LEVEL_DISCOVERY_TIMEOUT defined in TPSNMsg.h file
 * which determines the time for which each node in the network
 * waits to receive a level. If it does not receive a level by
 * the timeout, then it sends out a Level Request Message (LREQMsg).
 * This message is transmitted every LEVEL_DISCOVERY_TIMEOUT
 * interval subsequently till a level is received.
 *
 * 3. Time Synchronization can be initiated by two commands provided
 * by the API viz. instantSync and periodicSync. The sychronization
 * is initiated by the node sending a TimeSync (TSMsg). A timeout
 * for receiving the acknowledgement is set at that time to
 * the value TS_ACK_TIMEOUT. This value is defined in the TPSNMsg.h
 * If the timeout expires, the node sends another TimeSync message.
 * If the node does not receive a respone for ACK_MISS_TOLERANCE
 * times, then a Level Request Message is broadcast.
 *
 * 4. The TimeSync messages received by a node are buffered. In this
 * implementation, maximum of 4 simultaneous TimeSync messages can
 * be serviced. The TimeSync message buffer is implemented as a 
 * circular buffer.
 *
 *****************************************************************/

includes TPSNMsg;

module TPSNsyncM{
  provides{
    interface StdControl;
    interface TPSNsync;
  }
  
  uses {
    interface SClock;
    interface Leds;
    interface StdControl as SubControl;
    interface SendMsg as SendTSMsg;
    interface SendMsg as SendTSACKMsg;
    interface SendMsg as SendLDSMsg;
    interface SendMsg as SendLREQMsg;
    interface ReceiveMsg as ReceiveTSMsg;
    interface ReceiveMsg as ReceiveTSACKMsg;
    interface ReceiveMsg as ReceiveLDSMsg;
    interface ReceiveMsg as ReceiveLREQMsg;
    //    interface TimeStamp;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
  }
}

implementation {

  /************************ GLOBAL VARIABLES *******************************/
  struct TOS_Msg DataPkt;

  GTime  Recvpkt, RecvPrevpkt, PrevTS4, TS4, TS1, TS2, TS3;

  GTime TS[2];

  /* The set of TSACK Buffers*/
  GTime TStamp1[4];
  GTime RecvTS[4];
  GTime RecvPrevTS[4];
  uint8_t RecvTSOffset[4];
  uint16_t ACKAddress[4];

  uint8_t TSMsgSent, TSACKMsgSent, RecvOffset, RecvTSACKOffset, current, PosOrNeg, isRoot, TimerAttribute, MyLevel, AckWrPtr, AckRdPtr, isAckBuffFull, ACKTaskPosted , TSACKsNotReceived;
  uint16_t SyncTimeVar, TSParent, SyncPeriod, TimerInterval, TimeToSync, TimerFireInstant, LDSTimeOut, LDSAddress, TSACKTimeOut, alarmTime;
  uint32_t CorrectTicks;


  /******************** LOCAL FUNCTIONS *************************************/

  /**
   * Local Function to subtract C = (A - B) 
   * of two time readings A and B.
   * The difference is stored in C
   **/
  void SubTime(GTime* C, GTime* A, GTime* B){
    if (B->sticks > A->sticks){
      C->sticks = MAX_VAL - (B->sticks - A->sticks);
      C->mticks = A->mticks - (B->mticks + 1);
    }
    else {
      C->sticks = A->sticks -  B->sticks;
      C->mticks = A->mticks -  B->mticks;
    }
  }
  
  /**
   * Local Function to 
   * divide time by 2.
   **/
  void DivTime2(GTime* B, GTime* A){ 
    if (A->mticks%2 == 1){
      B->mticks = A->mticks/2;
      B->sticks = A->sticks/2 + (MAX_VAL)/2;
    }
    else{
      B->mticks = A->mticks/2;
      B->sticks = A->sticks/2;
    }
  }
  
  /**
   * Local Function to Add C = (A + B)
   * of two time readings A and B.
   * The sum is stored in C.
   **/
  void AddTime(GTime* C, GTime* A, GTime* B){
    if ((MAX_VAL - B->sticks) < A->sticks){
      C->sticks = A->sticks - (MAX_VAL - B->sticks);
      C->mticks = A->mticks + B->mticks + 1;
    }
    else{
      C->sticks = A->sticks + B->sticks;
      C->mticks = A->mticks + B->mticks;
    }
  }


  /**
   * Local Function to subtract C = |A - B|
   * of the two time readings A and B and also
   * return the sign of the result
   **/
  uint8_t ModSubTime(GTime* C, GTime* A, GTime* B){
    uint8_t retval;
    if (A->mticks > B->mticks) 
      retval = POSITIVE;
    else if (A->mticks < B->mticks) 
      retval = NEGATIVE;
    else{
      if (A->sticks > B->sticks)
	retval = POSITIVE;
      else if (A->sticks < B->sticks)
	retval = NEGATIVE;
      else
	retval = ZERO;
    }
    if (retval == POSITIVE) SubTime(C,A,B);
    else if (retval == NEGATIVE) SubTime(C,B,A);
    else {
      C->sticks = 0;
      C->mticks = 0;
    }
    return retval;
  }

  /************************ TASK DECLARATIONS ***********************************************/

  /**
   * Task to send a Level Discovery Packet
   **/
  task void sendLDSPkt(){
    LDSMsg* ldsmessage = (LDSMsg *)DataPkt.data;
    atomic{
      ldsmessage->src = TOS_LOCAL_ADDRESS;
      ldsmessage->level = MyLevel + 1;
    }
    call SendLDSMsg.send(LDSAddress, sizeof(LDSMsg), &DataPkt);
    call Leds.greenOn();
  }

  /**
   * Task to request for a level if we timeout
   **/
  task void sendLREQPkt(){
    LREQMsg* lreqmessage = (LREQMsg *)DataPkt.data;
    atomic{
      lreqmessage->src = TOS_LOCAL_ADDRESS;
    }
    call SendLREQMsg.send(TOS_BCAST_ADDR, sizeof(LREQMsg), &DataPkt);
    call Leds.greenOn();
  }

  /**
   * Task to send a Time Sync Packet
   * 
   **/
  task void sendTSPkt(){
    TSMsg* tsmessage = (TSMsg *)DataPkt.data;
    if (isRoot == 0){
      atomic{
	tsmessage->src = TOS_LOCAL_ADDRESS;
	TSACKTimeOut = (uint16_t)TS_ACK_TIMEOUT;
      }
      if (call SendTSMsg.send(TSParent, sizeof(TSMsg), &DataPkt) == SUCCESS) 
	TSMsgSent = 1;
      else
	post sendTSPkt();
    }
  }


  /** 
   * Task to send out a Time Sync Ack Packet
   **/
  task void sendTSACKPkt(){
    TSACKMsg* tsackmessage = (TSACKMsg*)DataPkt.data;
    atomic{
      tsackmessage->src = TOS_LOCAL_ADDRESS;
      tsackmessage->timestamp1.sticks = TStamp1[AckRdPtr].sticks;
      tsackmessage->timestamp1.mticks = TStamp1[AckRdPtr].mticks;
    }
    SubTime(&RecvPrevTS[AckRdPtr],&RecvTS[AckRdPtr],&RecvPrevTS[AckRdPtr]);
    
    CorrectTicks = (uint32_t)((RecvPrevTS[AckRdPtr].sticks * RecvTSOffset[AckRdPtr])/8);
    
    if (RecvTS[AckRdPtr].sticks < (uint16_t)CorrectTicks){
      tsackmessage->timestamp2.sticks = MAX_VAL - ((uint16_t)CorrectTicks - RecvTS[AckRdPtr].sticks);
      tsackmessage->timestamp2.mticks = RecvTS[AckRdPtr].mticks - 1;
    }
    else{
      tsackmessage->timestamp2.sticks = RecvTS[AckRdPtr].sticks -  (uint16_t)CorrectTicks;
      tsackmessage->timestamp2.mticks = RecvTS[AckRdPtr].mticks;
    }


    if (call SendTSACKMsg.send(ACKAddress[AckRdPtr], sizeof(TSACKMsg), &DataPkt) == SUCCESS) 
      TSACKMsgSent = 1;
  }

  /**
   * Task to Sync the local node clock
   **/
  task void SyncTime(){
    SubTime(&PrevTS4,&TS4,&PrevTS4);
    //CorrectTicks = (uint32_t)((PrevTS4.sticks * RecvTSACKOffset)/8);
    CorrectTicks = (uint32_t)((PrevTS4.sticks * RecvTSACKOffset)>>3);
    if ((uint16_t)CorrectTicks > TS4.sticks){
      TS4.mticks--;
      TS4.sticks = MAX_VAL - ((uint16_t)CorrectTicks - TS4.sticks);
    }
    else {
      TS4.sticks -= (uint16_t)CorrectTicks;
    }

    AddTime(&TS2,&TS2,&TS3);/* T2 + T3 */ 
    AddTime(&TS1,&TS1,&TS4);/* T1 + T4 */
    PosOrNeg = ModSubTime(&TS2,&TS2,&TS1);/* 2*Delta = (T2 - T1) - (T4 - T3) */ 
    DivTime2(&TS2,&TS2); /* Delta */
    call SClock.setTime(PosOrNeg, &TS2);
  }


  /********************* Interface StdControl ************************************/
  /**
   * Initialize the component, leds, radio
   *
   * @return return <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    current = 1; /* The index into the TimeStamp array */
    TSMsgSent = 0; /* Boolean variable to indicate that a Time Sync message has been sent */
    TSACKMsgSent = 0; /* Boolean variable to indicate that a Time Sync Ack message has been sent */
    SyncTimeVar = 0; /* Variable for maintaining the MTicks of the current time */
    SyncPeriod = MAX_VAL; /* Default period of synchronization */
    TimeToSync = MAX_VAL;
    TimerFireInstant = MAX_VAL;
    TimerInterval = MAX_VAL; /* Default period of the timer */
    TimerAttribute = ONE_SHOT; /* Default attribute of the timer */
    TSParent = TOS_BCAST_ADDR; /* Initially we just broadcast the TS Message if we dont know the parent */
    LDSTimeOut = (uint16_t) LEVEL_DISCOVERY_TIMEOUT;
    TSACKTimeOut = MAX_VAL;
    TSACKsNotReceived = 0;
    LDSAddress = TOS_BCAST_ADDR; /* Initially we broadcast the level discovery address. Then we respond to level requests.*/
    if (TOS_LOCAL_ADDRESS == 1){
      isRoot = 1; /* The root node for the Timing Sync. is based on node ID */
      MyLevel = 0;
    }
    else{ 
      isRoot = 0;                     /* Need to change this though ... */
      MyLevel = 255;
    }
    AckWrPtr = 0; /* The Write pointer into the buffer for storing the received TS Pkt information */
    AckRdPtr = 0; /* The Read pointer into the buffer for storing the received TS Pkt information */
    isAckBuffFull = 0; /* Initially the buffer is empty */
    ACKTaskPosted = 0; /* Initially no sendTSACKPkt is posted */
    call Leds.init(); /* Initialize the LEDS */
    call SubControl.init(); /* Initialize the radio*/
    return SUCCESS;
  }
  
  /**
   * Start the component
   *
   * @return reutrn <code>SUCCESS</code> or <code>FAIL</code>
   **/
  command result_t StdControl.start() {
    call SubControl.start(); /* Start the radio module */
    call SClock.SetRate(MAX_VAL,CLK_DIV_64); /* The SClock ticks at Clk/64 and fires interrupt on counting 0xffff */
    call Leds.redOn(); /* Indicates Mote is alive */
    if (isRoot) post sendLDSPkt(); /* Initiate the level discovery process in the network */
    return SUCCESS;
  }
  
  /**
   * Stop the component, Leds, Clock
   *
   * @return returns <code>SUCCESS</code> or <code>FAIL</code>
   **/
  command result_t StdControl.stop() {
    call SClock.SetRate(MAX_VAL, CLK_STOP); /* Stop the Clock */
    call SubControl.stop(); /* Stop the radio module */
    return SUCCESS;
  }

  /****************** Interface TPSNsync ******************************/

  /**
   * periodic Sync command
   **/
  async command void TPSNsync.periodicSync(uint16_t period){
    SyncPeriod = period;
    TimeToSync = SyncPeriod;
  }

  /**
   * instant Sync command
   **/
  async command result_t TPSNsync.instantSync(){
    SyncPeriod = MAX_VAL; /* These two statements disable the periodic sync */
    TimeToSync = MAX_VAL; /* Periodic Sync needs to be re-invoked */
    if (MyLevel < 255) {
      post sendTSPkt();
      return SUCCESS;
    }
    else
      return FAIL;
  }

  /**
   * periodic set Timer
   **/
  async command void TPSNsync.setTimer(uint16_t interval, uint8_t attribute){
    TimerAttribute = attribute;
    atomic{
      TimerInterval = interval;
      if (TimerAttribute == TIMER_STOP)
	TimerFireInstant = MAX_VAL;
      else
	TimerFireInstant = TimerInterval;
    }
  }

  /**
   * setAlarm: This command enables the application to set an Alarm for some global time
   **/
  async command result_t TPSNsync.setAlarm(uint16_t alarm){
    if (SyncTimeVar > alarm) return FAIL;
    alarmTime = alarm;
    return SUCCESS;
  }

  /*
   * getTime: This command returns the current value of the SyncTimeVar
   */
  async command uint16_t TPSNsync.getTime(){
    return SyncTimeVar;
  }

  /*
   * freeze: This command will freeze the Timer3
   */
  async command void TPSNsync.freeze(){
    call SClock.SetRate(MAX_VAL, CLK_STOP);
  }

  /*************** Interface SClock *****************************/
  /**
   * SClock Fires
   *
   * @return returns <code>SUCCESS</code>
   **/
  async event result_t SClock.fire(uint16_t mTicks){
    SyncTimeVar = mTicks;

    if (SyncTimeVar == alarmTime){
      signal TPSNsync.alarmRing();
      alarmTime = MAX_VAL;
    }
    
    TimerFireInstant--;
    if (TimerFireInstant == 0) {
      signal TPSNsync.timerFire();
      if (TimerAttribute == PERIODIC){
	TimerFireInstant = TimerInterval;
      }
      else
	TimerFireInstant = MAX_VAL; 
    }
    
    TimeToSync--;
    if (TimeToSync == 0) {
      if (MyLevel < 255)
	post sendTSPkt();
      TimeToSync = SyncPeriod;
    }
    
    TSACKTimeOut--;
    if (TSACKTimeOut == 0){
      TSACKsNotReceived++;
      if (TSACKsNotReceived == ACK_MISS_TOLERANCE){
	MyLevel = 255;
	LDSTimeOut = LEVEL_DISCOVERY_TIMEOUT;
	TSACKTimeOut = MAX_VAL;
	post sendLREQPkt();
      }
      else{
	if (TimeToSync > TS_ACK_TIMEOUT){
	  post sendTSPkt();
	}
      }
    }
    
    LDSTimeOut--;
    if (LDSTimeOut == 0){
      if ((isRoot == 0) & (MyLevel == 255)){
	post sendLREQPkt();
	LDSTimeOut = LEVEL_DISCOVERY_TIMEOUT;
      }
    }

    /* Toggling of red Led is just for visualization */
    /* Precise waveform can be obtained from the connector pin 26 */
    if (SyncTimeVar%2)
      call Leds.redOn();
    else
      call Leds.redOff();
    return SUCCESS;
  }
  
  /**
   * SClock SyncDone Event
   **/
  async event result_t SClock.syncDone(){
    signal TPSNsync.syncDone();
    return SUCCESS;
  }

  /********************** Interface RadioSendCoordinator ****************/

  /**
   * This event indicates that the start symbol has been sent.
   */
  async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff){
    TSMsg* tsmessage = (TSMsg*)msgBuff->data;
    TSACKMsg* tsackmessage = (TSACKMsg*)msgBuff->data;
    if (TSMsgSent){
      atomic{
	tsmessage->timestamp1.sticks = TS[current].sticks;
	tsmessage->timestamp1.mticks = TS[current].mticks;
      }
      TSMsgSent = 0;
      call Leds.greenOn();
    }
    if (TSACKMsgSent){
      atomic{
	tsackmessage->timestamp3.sticks = TS[current].sticks;
	tsackmessage->timestamp3.mticks = TS[current].mticks;
      }
      TSACKMsgSent = 0;
      call Leds.greenOn();
    }
  }

  /**
   * This event indicates that another byte of the current packet has been sent
   */
  async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount){};

  /**
   * Signals the start of processing of a new block by the radio. This
   * event is signaled regardless of the state of the radio.  This
   * function is currently used to aid radio-based time synchronization.
   * We use this instead of the RadioReceiveCoordinator because this is called
   * first in the radio stack thereby reducing jitter.
   */
  async event void RadioSendCoordinator.blockTimer(){
    current = current ^ (uint8_t)1;
    atomic{
      call SClock.getTime(&TS[current]);
    }
  }


  /************************** RadioReceiveCoordinator **************************/
  /**
   * This event indicates that the start symbol has been detected 
   * and its offset
   */
  async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff){
    atomic{
      Recvpkt.sticks = TS[current].sticks;     
      Recvpkt.mticks = TS[current].mticks;
      RecvPrevpkt.sticks = TS[current^(uint8_t)1].sticks;
      RecvPrevpkt.mticks = TS[current^(uint8_t)1].mticks;
    } 
    RecvOffset = offset;
    call Leds.yellowOn();
  }

  /**
   * This event indicates that another byte of the current packet has been rxd
   */
  async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount){};

  /**
   * Signals the start of processing of a new block by the radio. This
   * event is signaled regardless of the state of the radio.  This
   * function is currently used to aid radio-based time synchronization.
   */
  async event void RadioReceiveCoordinator.blockTimer(){};

  /********************** Interface TimeStamp ***************************/
  /**
   * byteTime signals as soon as SPI finishes sending a byte
   * This is the byte boundary time which we want to timestamp
   **/

/*   async event void TimeStamp.byteTime(){ */
/*     current = current ^ (uint8_t)1; */
/*     atomic{ */
/*       call SClock.getTime(&TS[current]); */
/*     } */
/*   } */

  /**
   * sentPacket signals on sending the Start Symbol
   *
   * @return returns <code>SUCCESS</code>
   **/

 /*  async event void TimeStamp.sentPacket(TOS_MsgPtr m){ */
/*     TSMsg* tsmessage = (TSMsg*)m->data; */
/*     TSACKMsg* tsackmessage = (TSACKMsg*)m->data; */
/*     if (TSMsgSent){ */
/*       atomic{ */
/* 	tsmessage->timestamp1.sticks = TS[current].sticks; */
/* 	tsmessage->timestamp1.mticks = TS[current].mticks; */
/*       } */
/*       TSMsgSent = 0; */
/*       call Leds.greenOn(); */
/*     } */
/*     if (TSACKMsgSent){ */
/*       atomic{ */
/* 	tsackmessage->timestamp3.sticks = TS[current].sticks; */
/* 	tsackmessage->timestamp3.mticks = TS[current].mticks; */
/*       } */
/*       TSACKMsgSent = 0; */
/*       call Leds.greenOn(); */
/*     } */
/*   } */
    
  /**
   * ReceiveTimingSignal signals on receiving the Start Symbol
   *
   * @return returns <code>SUCCESS</code>
   **/

 /*  async event void TimeStamp.startSymbol(uint8_t offset){ */
/*     atomic{ */
/*       Recvpkt.sticks = TS[current].sticks;      */
/*       Recvpkt.mticks = TS[current].mticks; */
/*       RecvPrevpkt.sticks = TS[current^(uint8_t)1].sticks; */
/*       RecvPrevpkt.mticks = TS[current^(uint8_t)1].mticks; */
/*     }  */
/*     RecvOffset = offset; */
/*     call Leds.yellowOn(); */
/*   } */
  
  /************* Interface SendTSMsg **************************/
  /**
   * SendTSMsg SendDone Event
   *
   **/
  event result_t SendTSMsg.sendDone(TOS_MsgPtr msg, result_t success){
    call Leds.greenOff();
    return SUCCESS;
  }

  /************ Interface ReceiveTSMsg **************************/
  /**
   * ReceiveTSMsg Event
   *
   **/
  event TOS_MsgPtr ReceiveTSMsg.receive(TOS_MsgPtr m){
    TSMsg* recvTSPtr = (TSMsg*)m->data;
    if (!isAckBuffFull)
      {
	atomic{
	  ACKAddress[AckWrPtr] = recvTSPtr->src;
	  TStamp1[AckWrPtr].sticks = recvTSPtr->timestamp1.sticks;
	  TStamp1[AckWrPtr].mticks = recvTSPtr->timestamp1.mticks;
	  RecvTS[AckWrPtr].sticks = Recvpkt.sticks;
	  RecvTS[AckWrPtr].mticks = Recvpkt.mticks;
	  RecvPrevTS[AckWrPtr].sticks = RecvPrevpkt.sticks;
	  RecvPrevTS[AckWrPtr].mticks = RecvPrevpkt.mticks;
	}
	RecvTSOffset[AckWrPtr] = RecvOffset;
	AckWrPtr = (AckWrPtr+1)%4;
	if (AckWrPtr == AckRdPtr) isAckBuffFull = 1;
	if (!ACKTaskPosted){
	  ACKTaskPosted = 1;
	  post sendTSACKPkt();
	}
      }
    call Leds.yellowOff();
    return m;
  }
  
  /********************* Interface SendTSACKMsg **********************/
  /**
   * SendTSACKMsg SendDone Event
   *
   **/
  event result_t SendTSACKMsg.sendDone(TOS_MsgPtr msg, result_t success){
    call Leds.greenOff();
    isAckBuffFull = 0;
    AckRdPtr = (AckRdPtr+1)%4;
    if (AckRdPtr == AckWrPtr) ACKTaskPosted = 0;
    else
      post sendTSACKPkt();
    return SUCCESS;
  }

  /*********************** Interface ReceiveTSACKMsg ******************/
  /** 
   * ReceiveTSACKMsg Event
   *
   **/
  event TOS_MsgPtr ReceiveTSACKMsg.receive(TOS_MsgPtr m){
    TSACKMsg* recvTSACKPtr = (TSACKMsg*)m->data;
    atomic{
      TS3.sticks = recvTSACKPtr->timestamp3.sticks;
      TS3.mticks = recvTSACKPtr->timestamp3.mticks;
      TS2.sticks = recvTSACKPtr->timestamp2.sticks;
      TS2.mticks = recvTSACKPtr->timestamp2.mticks;
      TS1.sticks = recvTSACKPtr->timestamp1.sticks;
      TS1.mticks = recvTSACKPtr->timestamp1.mticks;
      TS4.sticks = Recvpkt.sticks;
      TS4.mticks = Recvpkt.mticks;
      PrevTS4.sticks = RecvPrevpkt.sticks;
      PrevTS4.mticks = RecvPrevpkt.mticks;
      TSACKsNotReceived = 0;
      TSACKTimeOut = MAX_VAL;
    }
    RecvTSACKOffset = RecvOffset;
    post SyncTime();
    call Leds.yellowOff();
    return m;
  }

  /******************* Interface SendLDSMsg **********************/
  /**
   * SendLDSMsg SendDone Event
   **/
  event result_t SendLDSMsg.sendDone(TOS_MsgPtr msg, result_t success){
    call Leds.greenOff();
    if (!success) post sendLDSPkt();
    return SUCCESS;
  }

  /******************* Interface ReceiveLDSMsg ******************/
  /**
   * ReceiveLDSMsg receive Event
   **/
  event TOS_MsgPtr ReceiveLDSMsg.receive(TOS_MsgPtr m){
    LDSMsg* recvLDSMsg = (LDSMsg *)m->data;
    if (MyLevel > recvLDSMsg->level){ /* If already received a level discovery packet then discard this one */
      atomic{
	TSParent = recvLDSMsg->src;
	MyLevel = recvLDSMsg->level;
	LDSAddress = TOS_BCAST_ADDR;
      }
      LDSTimeOut = MAX_VAL;
      post sendLDSPkt();
    }
    call Leds.yellowOff();
    return m;
  }

  /************** Interface SendLREQMsg **************************/
  /**
   * SendLREQMsg sendDone Event
   **/
  event result_t SendLREQMsg.sendDone(TOS_MsgPtr msg, result_t success){
    call Leds.greenOff();
    if (!success) post sendLREQPkt();
    return SUCCESS;
  }

  /*************** Interface ReceiveLREQMsg *********************/
  /**
   * ReceiveLREQMsg receive event
   **/
  event TOS_MsgPtr ReceiveLREQMsg.receive(TOS_MsgPtr m){
    LREQMsg* recvLREQMsg = (LREQMsg *)m->data;
    atomic{
      LDSAddress = recvLREQMsg->src;
    }
    if (MyLevel < 255)
      post sendLDSPkt();
    call Leds.yellowOff();   
    return m;
  }
}

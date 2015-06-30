/*
 *
 * "Copyright (c) 2002-2004 The Regents of the University  of California.  
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
/*
 *	Power Scheduler for Application Mote
 *
 * Author:	Barbara Hohlt		
 * Project: 	Ivy 
 *
 */


module AppScheduler {
 
    
  provides {
    interface StdControl as Control;
    interface PowerModeSendApp as PowerModeSend ; 
  }

  uses {
    command bool bestCandidate(TOS_MsgPtr msg);
    interface StdControl as SubControl;
    interface Timer as Timer0;
    interface Timer as Timer1;
    interface Leds;
    interface RouteSelect;
    interface ReceiveMsg as ReceiveAdv;
    interface SendMsg as SendReq;
    interface ReceiveMsg as ReceiveAck;
  }
}

implementation {

  int hops;	/* number of hops from the base station */
  int tmpgrad;
  int tmphops;
  int demand;
  int supply;
  int schedule_counter;
  uint16_t local_parent; /* used for testing */
  bool send_good;
  uint32_t FREQ;
  bool begin_init;
  bool begin_synch;
  int synch_period;
  int  timeout_synch;
  bool have_parent;
  bool found_parent;
  int listen_count;
  int prev_r;	/* timeout RECEIVE_PENDING */
  int prev_t;	/* timeout TRANSMIT_PENDING */
  powermode theMode;
  uint8_t schedule[NUM_SLOTS];
  int slot_i;	/* current time slot */
  int slot_a;	/* current advertisement slot */
  int slot_r;	/* available to receive, the slot being advertised */
  int slot_t;	/* available to transmit, the slot being requested  */
  TOS_Msg msgAdv;
  TOS_Msg msgReq;
  IvyNet parentInfo;

  bool ack_pending;
  TOS_Msg msgAck;
  TOS_MsgPtr ackPtr;
  TOS_Msg msgSched;

  void startOver();
  void timeSync();
  void initSchedule();
  int pickIdleSlot();
  void setMode() ;
  void radioOn();
  void radioOff();
  void staticHops();	/* only used for fixed nodes */
  void printSchedule();
  result_t moreSupply();
  result_t moreDemand();

  /*
   *
   * Send reservation request 
   * 
   */
  task void sendReq() {

    IvyNet *message = (IvyNet *) msgReq.data;
    memset(msgReq.data,0,DATA_LENGTH);


    /*
     * I am node mote_id. 
     * Here is my time-to-live. 
     * I am h hops from the base station.
     * This is the current time slot slot_i.
     * Receive from me during slot_t;
     */
    message->mote_id = (uint16_t) TOS_LOCAL_ADDRESS; 
    /* message->ttl = (uint8_t) TTL; */
    message->hop_count = (uint8_t) hops;
    message->cur_slot = (uint8_t) slot_i;
    message->reserv_slot = (uint8_t) slot_t;

    TOSH_uwait(REQ_WAIT); /* let destination receiver warmup */
    call SendReq.send(parentInfo.mote_id,sizeof(IvyNet),&msgReq);

    return ;
  }
 event result_t SendReq.sendDone(TOS_MsgPtr msg, result_t success)
 {
	return SUCCESS;
 }


  /*
   *  sendSchedule
   * 
   *  NOT USED OR CALLED 
   * 
   *  sends the current power schedule 
   *  to BTS 
   * 
   */
  task void sendSchedule() {


    int slen, ss, i, j;
    uint8_t packed_data;
    uint8_t schedBuf[NUM_SLOTS];

    IvyMsg *message = (IvyMsg *) msgSched.data;
    memset (msgSched.data,0,DATA_LENGTH);
    dbg(DBG_ROUTE, "AppScheduler:sendSchedule().\n" );

    message->myapp_id = IVY_APPID;
    message->mymote_id = TOS_LOCAL_ADDRESS;
    message->app_id = IVY_APPID;
    message->mote_id = TOS_LOCAL_ADDRESS;
    message->hop_count = 1;


    dbg(DBG_ROUTE, "AppScheduler: copy schedule\n");

    ss = sizeof(schedule);
    slen = (ss < IVY_DATA_LEN) ? ss : IVY_DATA_LEN;
    memcpy(&schedBuf[0],&schedule[0],ss);
    for (j=0,i=0; i<IVY_DATA_LEN; i++)
    {
        packed_data &= 0x00;

        packed_data |= (schedBuf[j] << 4);
        j++;
        packed_data |= (schedBuf[j] & 0x0f);
        j++;
        message->data[i] = packed_data;
    }

    dbg(DBG_ROUTE, "AppScheduler: Forward schedule to BTS.\n");

    //signal PowerModeSend.scheduleNotify(&msgSched,sizeof(IvyMsg));
    schedule_counter = GET_SCHED;
    send_good = TRUE;
    printSchedule();

    return;
   }


  void startOver() {

    call Timer0.stop();
    call Timer1.stop();

    demand = 1;
    supply = 0;
    slot_i = 0;	  /* the current time slot */
    slot_a = -1;  /* advertisement slot unknown */
    slot_r = -1;  /* available to receive unknown */
    prev_r = -1; 
    slot_t = -1;  /* available to transmit unknown */
    prev_t = -1; 
    hops   = -1;  /* hops from base station unknown */
    tmphops = 999;
    tmpgrad = 999;
    begin_init = FALSE;
    have_parent = FALSE;
    found_parent = FALSE;
    listen_count = LISTEN_PERIOD;
    timeout_synch  = FAULT_FREQ;
    ackPtr = &msgAck;
    ack_pending = FALSE;
    parentInfo.mote_id = 0;
    parentInfo.hop_count = 0;
    parentInfo.cur_slot = 0;
    parentInfo.reserv_slot = 0;

    theMode = AWAKE_MODE;
    initSchedule();
    staticHops();
    tmphops = hops; /* init tmphops to self */

    return; 
  }

  command result_t Control.init() {


    demand = 1;
    supply = 0;
    slot_i = 0;	  /* the current time slot */
    slot_a = -1;  /* advertisement slot unknown */
    slot_r = -1;  /* available to receive unknown */
    prev_r = -1; 
    slot_t = -1;  /* available to transmit unknown */
    prev_t = -1; 
    hops   = -1;  /* hops from base station unknown */
    tmphops = 999;
    tmpgrad = 999;
    begin_init = FALSE;
    have_parent = FALSE;
    found_parent = FALSE;
    listen_count = LISTEN_PERIOD;
    timeout_synch  = FAULT_FREQ;
    FREQ = (uint32_t) SLOT_FREQ;
    ack_pending = FALSE;
    ackPtr = &msgAck;
    parentInfo.mote_id = 0;
    parentInfo.hop_count = 0;
    parentInfo.cur_slot = 0;
    parentInfo.reserv_slot = 0;

    theMode = AWAKE_MODE;
    initSchedule();

    call SubControl.init();
    return SUCCESS;
  }

  command result_t Control.start() {

    call SubControl.start();
    /* 
     * static hops from the base station.
     *	-- this is testbed specific ! 
     */ 
    staticHops();
    tmphops = hops; /* init tmphops to self */

    schedule_counter = GET_SCHED;  /* sendSchedule timer */
    send_good = FALSE;

   /* NidoHack */
   if(NidoHack)
   {
	supply = 1;
    	have_parent = TRUE;
    	found_parent = TRUE;
    	slot_t = (TOS_LOCAL_ADDRESS % NUM_SLOTS);
	schedule[slot_t] = TRANSMIT;

    	parentInfo.mote_id = TOS_BCAST_ADDR;
    	parentInfo.hop_count = 0;
    	parentInfo.cur_slot = 0;
    	parentInfo.reserv_slot = slot_t; 

    	call Timer0.start(TIMER_REPEAT, FREQ);

   }

    return SUCCESS;
  }

  command result_t Control.stop() {
    
    call Timer0.stop();
    call Timer1.stop();

    call SubControl.stop();
    return SUCCESS;
  }

  command void PowerModeSend.setRadioModeOff() {

    radioOff(); 

    return;
  }

  /*
   * Initialize Timer 
   *  
   * Step: 1 FALSE 
   * node is listening for a 
   * parent for one full cycle  
   * and then waits for it's
   * reservation slot slot_t and  
   * then sends a reservation request  
   * TODO: sendReq with probability p  
   *  
   * the confirmation ack should come   
   * in the very same time slot  
   *  
   * Step: 2 TRUE  
   * verify confirmation ack has come 
   * stop Init Timer   
   * start Power Schedule Timer 
   *   
   */
  event result_t Timer1.fired() {
    slot_i = (slot_i + 1) % NUM_SLOTS;

    dbg(DBG_ROUTE, "PowerScheduler: Init, slot_i[%d] slot_t[%d].\n", slot_i, slot_t);

    if (SynchLeds || InitLeds)
        call Leds.redToggle();

    switch(found_parent)
    {
	case FALSE:
    	    listen_count--;
    	    if (listen_count > 0)
    		return SUCCESS;

    	    if (slot_i != slot_t)
    		return SUCCESS;


    	    if (slot_t != -1)
    	    {
    		dbg(DBG_ROUTE, "PowerScheduler: Found parent!\n");
		found_parent = TRUE;
    		schedule[slot_t] = TRANSMIT_PENDING;
		if (slot_i == slot_t)
        	  post sendReq();	
    	    } else {
    		dbg(DBG_ROUTE, "PowerScheduler: Parent not found!\n");
 		startOver();
    	    }
	    break;
	case TRUE:
    	    call Timer1.stop();
	    if (have_parent)
	    {
    		if (SynchLeds)
        	    call Leds.redOff();
		begin_synch = FALSE;
		synch_period = SYNCH_FREQ;
    	    	call Timer0.start(TIMER_REPEAT, FREQ);
	    } else {
    		dbg(DBG_ROUTE, "PowerScheduler: Reservation request failed!\n");
		startOver();
	    }
	    break;
     }
	
    return SUCCESS;
  }

  /*
   * Power Schedule Timer: 
   *  
   * the general case 
   * - advance current time slot 
   * - set mode
   * - listen for advertisements
   * - do state:
   *	TRANSMIT
   *	TRANSMIT_PENDING
   *	IDLE
   *
   * - signal new mode
   *
   */
  event result_t Timer0.fired() {

    slot_i = (slot_i + 1) % NUM_SLOTS;


    if (InitLeds)
        call Leds.redOff();
    if (SynchLeds)
        call Leds.greenToggle();

    timeSync();
    
    if (theMode == SLEEP_MODE)
	return SUCCESS;

    if ( supply < demand )
	moreSupply();

    dbg(DBG_USR1, "PowerScheduler: Schedule, supply=%d demand=%d slot_i[%d] slot_t[%d] slot_r[%d].\n\n", 
	supply, demand, slot_i, slot_t,slot_r);


    if ((theMode == AWAKE_MODE) && (schedule[slot_i] == TRANSMIT) &&
		(parentInfo.mote_id >0))
    signal PowerModeSend.modeNotify(parentInfo.mote_id,schedule[slot_i],slot_i);


/*    if (Monitor)
    	schedule_counter--;
    if (Monitor && (schedule_counter <= 0) && !send_good ) 
	post sendSchedule(); */

    return SUCCESS;
  }

  /*
   *  timeSync
   *
   *  Every SYNCH_FREQ listen for parent
   *  and re-synch. If you do not hear
   *  from your parent after FAULT_FREQ
   *  start over. This allows for mobility 
   *  in the application mote and fault
   *  tolerance (hardware failure) of the 
   *  network motes. 
   *
   */

 void timeSync() {

    if (FaultTolerance) {
    /* duration of synch period */
      if (begin_synch)
   	timeout_synch--;

      if (timeout_synch < 0)
	startOver();
    }


    /* frequency of synch period */
    synch_period--;
    if (synch_period < 0) {
	
 	radioOn();	

	if (NidoHack) {
	    synch_period = SYNCH_FREQ;
	    theMode = AWAKE_MODE;


	} else {
	    begin_synch = TRUE;
	    timeout_synch = FAULT_FREQ;
	    synch_period = SYNCH_FREQ;

	}
	
    }

   return;
 }

 void radioOn() {
    signal PowerModeSend.radioOnNotify();
    return;
 }
 void radioOff() {
    theMode = SLEEP_MODE;
    return;
 }

  default event void PowerModeSend.modeNotify(uint16_t parent, 
		uint8_t slotState, int s)
  { return ; }


  default event void PowerModeSend.radioOnNotify()
  { return ; }



  result_t moreSupply()
  {

    if ( schedule[slot_t] == IDLE )
	schedule[slot_t] = TRANSMIT_PENDING;


    if ( (slot_i == slot_t) && (schedule[slot_i] == TRANSMIT_PENDING) )
        post sendReq();	

    return SUCCESS;
  }
 
  /*
   *  ReceiveAdv
   *
   *  - receive advertisements
   *  - save nearest parent
   *  - synch current slot_i
   *  - reset Timer1
   *
   * Note: If do not hear from parent after FAULT_FREQ 
   *	   startOver() is called. 
   *
   */
  event TOS_MsgPtr ReceiveAdv.receive(TOS_MsgPtr adv) {

    IvyNet *message = (IvyNet *) adv->data;

    dbg(DBG_ROUTE, "PowerScheduler: Received an advertisement from mote %d.\n",
							message->mote_id);
    /*
     * Here we already have a parent
     * and we keep track of available
     * reservation slots for when we
     * may need more ie
     *  supply < demand	
     *
     * If it's time to re-synch we do
     * that and wake up the Applicatino mote. 
     *
     * We wait 2 cycles for a confirmation ack before
     * we timeout TP - this can be changed
     *
     */
    // NOTE IN PROGRESS
    if (have_parent)
    {
	if (message->mote_id == parentInfo.mote_id)
	{
	    if (begin_synch) {
		begin_synch = FALSE;
                call Timer0.stop();
                slot_i = message->cur_slot;
                call Timer0.start(TIMER_REPEAT, FREQ);
		theMode = AWAKE_MODE;

            }

	    if( (prev_t >= 0) && (schedule[prev_t] == TRANSMIT_PENDING))
	    	schedule[prev_t] = IDLE;

	    prev_t = slot_t;
	    slot_t = (int) message->reserv_slot;
	}
	return adv;
    }

    /* This means we have already selected a parent
     * and are waiting for the confirmation ACK.
     */
    if (found_parent)
	return adv;

    /* This means we have already selected a parent
     * and are waiting to send the reservation REQ.
     */
    if (begin_init && (listen_count <= 0))
        return adv;

    /* Testing Only  - staticHops */
    /* if (message->hop_count != (hops - 1) )
	return adv; */

    /*
     *
     *  - TODO: closest IvyNet node to self becomes parent 
     *  - FOR NOW: pick a dummy parent 
     *  - save advertisement info
     *  - synch timer to slot_i
     */
    if (call bestCandidate(adv))
    {

    	call Timer1.stop();
	tmpgrad = message->gradient;
	tmphops = message->hop_count;
	memcpy(&parentInfo, message, sizeof (IvyNet));

   	hops = message->hop_count + 1; /* readjust my hop count */ 
	slot_i = message->cur_slot;
	slot_t = message->reserv_slot;

    	call Timer1.start(TIMER_REPEAT, FREQ);
	/* now listen for one full cycle */
	if (!begin_init)
	{
	    begin_init = TRUE;
	    listen_count = LISTEN_PERIOD;
	}

    	dbg(DBG_ROUTE, "PowerScheduler: This is time slot %d. Advertisement for slot %d received.\n",slot_i,slot_t);
    } else {
    	dbg(DBG_ROUTE, "PowerScheduler: Advertisement rejected.\n");
    }

    return adv;
  }

  /*
   *  ReceiveAck
   *
   *  - receive immediate confirmation ack 
   * 	  during same time slot as SendReq
   *  - verify confirmation ack 
   *  - update schedule
   *  - increment supply
   *  - signal parentNotify()
   *
   */
  event TOS_MsgPtr ReceiveAck.receive(TOS_MsgPtr ack) {

    IvyNet *m = (IvyNet *) ack->data;


//    if ((schedule[slot_i] == TRANSMIT_PENDING) && (slot_i == (int)m->reserv_slot))
    if (schedule[m->reserv_slot] == TRANSMIT_PENDING) 
    {
    	schedule[m->reserv_slot] = TRANSMIT;
	supply++;

	if (!have_parent) {
	    have_parent = TRUE;
	    //signal PowerModeSend.parentNotify(parentInfo.mote_id);
	}
    	dbg(DBG_ROUTE, "PowerScheduler: Confirmation ack succeeded.\n");
    } else
    	dbg(DBG_ROUTE, "PowerScheduler: Confirmation ack failed.\n");
	

    return ack;
  }


  void initSchedule() {
    int i;

    for (i=0; i< NUM_SLOTS; i++)
    {
	schedule[i] = (uint8_t) IDLE;
    }

	return;
  } 

  void setMode() {

    if (theMode == SLEEP_MODE)
	return;

    switch(slot_i)
    {
	case TRANSMIT:
	case TRANSMIT_PENDING:
		theMode = TRANSMIT_MODE;
		break;
	case RECEIVE:
	case RECEIVE_PENDING:
		theMode = RECEIVE_MODE;
		break;
	case ADVERTISE:
		theMode = ADVERTISE_MODE;
		break;
	default:	
		theMode = IDLE_MODE;
    }

    return;
  }

  void staticHops() {
    hops = 10;	
    return;
  }

  void staticHopsTestBed() {
    hops = 5;	
  }

  void printSchedule() {
    	dbg(DBG_ROUTE, "PowerSchedule:printSchedule() %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
schedule[0], schedule[1], schedule[2], schedule[3], schedule[4], schedule[5],
schedule[6], schedule[7], schedule[8], schedule[9], schedule[10], schedule[11],
schedule[12], schedule[13], schedule[14], schedule[15], schedule[16], 
schedule[17], schedule[18], schedule[19], schedule[20], schedule[21],
schedule[22], schedule[23], schedule[24], schedule[25], schedule[26],
schedule[27], schedule[28], schedule[29], schedule[30], schedule[31],
schedule[32], schedule[33], schedule[34], schedule[35], schedule[36],
schedule[37], schedule[38], schedule[39]);

    return;
  }

}

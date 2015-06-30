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
 *
 * Author:	Barbara Hohlt		
 * Project: 	Ivy 
 *
 */


module PowerScheduler {
 
    
  provides {
    interface StdControl as Control;
    interface PowerModeRoute ; 
    interface PowerModeSend ; 
  }

  uses {
    interface StdControl as CommControl;
    interface StdControl as SubControl;
    interface Timer as Timer0;
    interface Timer as Timer1;
    interface Random;
    interface Leds;
    interface SendMsg as SendAdv;
    interface SendMsg as SendReq;
    interface SendMsg as SendAck;
    interface ReceiveMsg as ReceiveAdv;
    interface ReceiveMsg as ReceiveReq;
    interface ReceiveMsg as ReceiveAck;
  }
}

implementation {

  int hops;	/* number of hops from the base station */
  int tmphops;
  int tmpgrad;
  int demand;
  int supply;
  int schedule_counter;
  bool radio_on; 
  bool send_good;
  bool begin_init;
  bool begin_synch;
  bool begin_reroute;
  int synch_period;
  int timeout_synch;
  uint32_t FREQ;
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
  void reRoute();
  void initSchedule();
  void initRoute();
  int pickIdleSlot();
  bool setRadioMode() ;
  void turnRadioOn();
  void turnRadioOff();
  void staticHops();	/* network motes use static hops */
  void printSchedule();
  void timeSync(); 
  result_t moreSupply();
  result_t moreDemand();
  result_t setAdvertisement();

 
/*
 *  start advertisements 
 *   a NidoHack
 */
void initBaseSlacker() {
  int tmp1;
  int tmp2;

    dbg(DBG_ROUTE, "PowerScheduler:initBaseSlacker()\n" );
    begin_init = TRUE;
    found_parent = TRUE;
    have_parent = TRUE;
    demand = 1;
    supply = 1;
    slot_a = pickIdleSlot();
    schedule[slot_a] = ADVERTISE;
    slot_r = pickIdleSlot();
    schedule[slot_r] = RECEIVE_PENDING;

    tmp1 = pickIdleSlot();
    schedule[tmp1] = TRANSMIT;
    slot_t = tmp1;

    tmp2 = -1;
    if ( DummyDemand )
    {
      tmp2 = pickIdleSlot();
      schedule[tmp2] = RECEIVE;
    }

    dbg(DBG_ROUTE, "PowerScheduler:initBase: slot_a[%d] slot_r[%d] transmit[%d] receive[%d].\n", slot_a, slot_r,tmp1,tmp2);

    call Timer0.start(TIMER_REPEAT, FREQ);
    signal PowerModeSend.modeNotify(theMode, schedule[slot_i], slot_i);

    return;
}

/*
 *  select advertisement slot 
 *  select reservation slot 
 */
void selectAdvertisement() {

    dbg(DBG_ROUTE, "PowerScheduler:selectAdvertisement\n" );

    if( (slot_a >= 0) && (schedule[slot_a] == ADVERTISE) )
    	schedule[slot_a] = IDLE;

    /*
     * we wait 2 cycles for a reservation request before
     * we timeout - this can be changed
     */
    if( (prev_r >= 0) && (schedule[prev_r] == RECEIVE_PENDING) )
    		schedule[prev_r] = IDLE;

    slot_a = pickIdleSlot();
    schedule[slot_a] = ADVERTISE;
    prev_r = slot_r;
    slot_r = pickIdleSlot();
    schedule[slot_r] = RECEIVE_PENDING;
    dbg(DBG_ROUTE, "PowerScheduler:selectAdv: slot_a[%d] slot_r[%d].\n", slot_a, slot_r);


    return;
}
  /*
   *
   * Broadcast advertisement 
   * 
   */
  task void sendAdv() {

    IvyNet *message = (IvyNet *) msgAdv.data;
    memset(msgAdv.data,0,DATA_LENGTH);

    /*
     * I am node mote_id. 
     * This is my current demand (number of reserved slots). 
     * I am h hops from the base station.
     * This is the current time slot slot_i.
     * Transmit to me during slot_r;
     */
    message->mote_id = (uint16_t) TOS_LOCAL_ADDRESS; 
    message->gradient = (uint8_t) demand;
    message->hop_count = (uint8_t) hops;
    message->cur_slot = (uint8_t) slot_i;
    message->reserv_slot = (uint8_t) slot_r;

    if (SynchLeds)
    {
	call Leds.redOff();
	call Leds.yellowOn();
    }

    call SendAdv.send(TOS_BCAST_ADDR,sizeof(IvyNet),&msgAdv);

    return ;
  }

 event result_t SendAdv.sendDone(TOS_MsgPtr msg, result_t success)
 {
	return SUCCESS;
 }
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
     * Here is my TTL. 
     * I am h hops from the base station.
     * This is the current time slot slot_i.
     * Receive from me during slot_t;
     */
    message->mote_id = (uint16_t) TOS_LOCAL_ADDRESS; 
    /* message->ttl = (uint8_t) TTL; */
    message->hop_count = (uint8_t) hops;
    message->cur_slot = (uint8_t) slot_i;
    message->reserv_slot = (uint8_t) slot_t;

    /*
     * NOTE: hack !!
     *
     * This allows the radio receiver of the destination
     * mote to warm up. This is radio specific.
     *
     */
     TOSH_uwait(REQ_WAIT);

    if (call SendReq.send(parentInfo.mote_id,sizeof(IvyNet),&msgReq))
    {
	if (SynchLeds)
	  call Leds.yellowOn();
    } 

    return ;
  }
 event result_t SendReq.sendDone(TOS_MsgPtr msg, result_t success)
 {
	return SUCCESS;
 }


  /*
   *  sendSchedule
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
    dbg(DBG_ROUTE, "PowerScheduler:sendSchedule().\n" );

    message->myapp_id = IVY_NETID;
    message->mymote_id = TOS_LOCAL_ADDRESS;
    message->app_id = IVY_NETID;
    message->mote_id = TOS_LOCAL_ADDRESS;
    message->hop_count = 1;

    dbg(DBG_ROUTE, "PowerScheduler: copy schedule\n");
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

    dbg(DBG_ROUTE, "PowerScheduler: Forward schedule to BTS.\n");

    signal PowerModeRoute.scheduleNotify(&msgSched,sizeof(IvyMsg));
    schedule_counter = GET_SCHED;
    send_good = TRUE;
    printSchedule();

    return;
   }


  void reRoute() {
    dbg(DBG_ROUTE, "PowerScheduler:reRoute().\n");

    begin_reroute = TRUE;
    call Timer0.stop();
    call Timer1.stop();

    supply = 0;
    slot_t = -1;  	/* available to transmit unknown */
    prev_t = -1;
    begin_init = FALSE;
    begin_synch = FALSE;
    have_parent = FALSE;
    found_parent = FALSE;
    listen_count = LISTEN_PERIOD;
    timeout_synch = FAULT_FREQ;
    ackPtr = &msgAck;
    ack_pending = FALSE;
    parentInfo.mote_id = 0;
    parentInfo.reserv_slot = 0;

    initRoute();
    tmphops = hops; /* init tmphops to self */
    tmpgrad = 999;

    return; 
  }
  void startOver() {

    call Timer0.stop();
    call Timer1.stop();
    if (SynchLeds)
      call Leds.yellowOff();
    turnRadioOn();

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
    begin_synch = FALSE;
    begin_reroute = FALSE;
    have_parent = FALSE;
    found_parent = FALSE;
    listen_count = LISTEN_PERIOD;
    timeout_synch = FAULT_FREQ;
    ackPtr = &msgAck;
    ack_pending = FALSE;
    parentInfo.mote_id = 0;
    parentInfo.hop_count = 0;
    parentInfo.cur_slot = 0;
    parentInfo.reserv_slot = 0;

    theMode = IDLE_MODE;
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
    radio_on = TRUE;
    begin_init = FALSE;
    begin_synch = FALSE;
    begin_reroute = FALSE;
    have_parent = FALSE;
    found_parent = FALSE;
    listen_count = LISTEN_PERIOD;
    timeout_synch = FAULT_FREQ;
    FREQ = (uint32_t) SLOT_FREQ;
    ack_pending = FALSE;
    ackPtr = &msgAck;
    parentInfo.mote_id = 0;
    parentInfo.hop_count = 0;
    parentInfo.cur_slot = 0;
    parentInfo.reserv_slot = 0;

    theMode = IDLE_MODE;
    initSchedule();

    /* Random is also initialized in MicaHighSpeedRadioM */
    call Random.init(); 
    call CommControl.init();
    call SubControl.init();
    return SUCCESS;
  }

  command result_t Control.start() {

    call CommControl.start();
    call SubControl.start();
    /* 
     * static hops from the base station.
     *	-- this is testbed specific ! 
     */ 
    staticHops();
    tmphops = hops; /* init tmphops to self */

    schedule_counter = GET_SCHED;  /* sendSchedule timer */
    send_good = FALSE;

    /* 
     * hack for Nido
     * actually the base station kicks things off
     */
    dbg(DBG_ROUTE, "PowerScheduler:Start: TOS_LOCAL_ADRESS %d.\n", TOS_LOCAL_ADDRESS);
    if (NidoHack && (TOS_LOCAL_ADDRESS == IVY_BASE_STATION_ADDR))
    {
    	initBaseSlacker();
    } 


    return SUCCESS;
  }

  command result_t Control.stop() {
    
    signal PowerModeSend.modeNotify(IDLE_MODE, IDLE, 0);
    call Timer0.stop();
    call Timer1.stop();

    call CommControl.stop();
    call SubControl.stop();
    return SUCCESS;
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
    int tmp;
    slot_i = (slot_i + 1) % NUM_SLOTS;

    dbg(DBG_USR1, "PowerScheduler: Init, slot_i[%d] slot_t[%d].\n", slot_i, slot_t);

    /* If we are rerouting we still need
     * to send Advertisements/Synch packets
     * for our children.
     */
    if (begin_reroute)
    {
        setAdvertisement();	/* send advertisement once per cycle */
	moreDemand();
    }

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
		if (begin_reroute)
		    reRoute();
		else
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
                if ( NidoHack && DummyDemand ) {
    			tmp = pickIdleSlot();
    			schedule[tmp] = RECEIVE;
    			dbg(DBG_ROUTE, "PowerScheduler: schedule[%d] = RECEIVE.\n", tmp);
		}
	    } else {
    		dbg(DBG_ROUTE, "PowerScheduler: Reservation request failed!\n");
		if (begin_reroute)
		    reRoute();
		else
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
   *   or send advertisements 
   * - do state:
   *	TRANSMIT
   *	RECEIVE
   *	ADVERTISE
   *	TRANSMIT_PENDING
   *    RECEIVE_PENDING
   *	IDLE
   *
   * - signal new mode
   *
   */
  event result_t Timer0.fired() {

    slot_i = (slot_i + 1) % NUM_SLOTS;


    dbg(DBG_USR1, "PowerScheduler: Sync, slot_i[%d] slot_t[%d].\n", slot_i, slot_t);
    if (InitLeds)
        call Leds.redOff();
    if (SynchLeds)
        call Leds.greenToggle();

    setAdvertisement();		/* send advertisement once per cycle */
    if ( supply < demand )
    {
	turnRadioOn();
	moreSupply();
    }
    else { 
        setRadioMode();
    	moreDemand();	/* send advertisement once per cycle */
   }

    dbg(DBG_ROUTE, "PowerScheduler: Schedule, supply=%d demand=%d slot_i[%d] slot_t[%d] slot_r[%d].\n\n", 
	supply, demand, slot_i, slot_t,slot_r);


    if (radio_on && (schedule[slot_i] == TRANSMIT))
      signal PowerModeSend.modeNotify(theMode, schedule[slot_i], slot_i);

    if (TimeSynch)
    	timeSync();

    if (Monitor)
    	schedule_counter--;
    if (Monitor && (schedule_counter <= 0) && !send_good ) 
	post sendSchedule();

    return SUCCESS;
  }

  /*
   *  timeSync
   *
   *  Every SYNCH_FREQ listen for parent 
   *  and re-synch. If you do not hear 
   *  from your parent after FAULT_FREQ 
   *  re-route to a new parent. This allows
   *  for fault tolerance (hardware failure)
   *  of the network motes.
   *
   */
  void timeSync() {

    /* Ivy base mote does not do timeSync  */
    if (NidoHack && (TOS_LOCAL_ADDRESS == IVY_BASE_STATION_ADDR))
	return;

/* 
 * NOTE IN PROGRESS
 *
 * As it turns out, we usually have FaultTolerance = FALSE.
 * Because of the lossy nature of wireless links false positives
 * occur rather frequently. You can alleviate this by setting
 * a really large FAULT_FREQ parameter in IvyNet.h.
 *
 */
    if (FaultTolerance) {
    /* duration of synch period */
    	if (begin_synch)
          timeout_synch--;

    	if (timeout_synch < 0)
          reRoute();
    }

    /* frequency of synch period */
    synch_period--;
    if (synch_period < 0)
    {
	turnRadioOn();
	begin_synch = TRUE;
	timeout_synch = FAULT_FREQ;
	synch_period = SYNCH_FREQ;
    }


    return;
 }
 
  default event void PowerModeSend.radioOnNotify()
  { return ; }

  default event void PowerModeSend.parentNotify(uint16_t newparent)
  { return ; }

  default event void PowerModeSend.modeNotify(powermode powerMode, 
		uint8_t slotState, int s)
  { return ; }
  default event void PowerModeRoute.messageNotify(powermode powerMode, 
		uint8_t slotState, int s)
  { return ; }

  default event void PowerModeRoute.scheduleNotify(TOS_MsgPtr sched, uint16_t len)
  { return ; }

  /*
   *  moreDemand
   *
   *  - select an advertisement slot
   *	once per cycle
   *  - send advertisement
   *
   */
  result_t setAdvertisement()
  {
    /* set slot_r and slot_a */
    if (slot_i == 0) {
    	selectAdvertisement();
	call Leds.yellowOff();
    }

    return SUCCESS;
  }

  result_t moreDemand()
  {

    if ( (schedule[slot_i] == ADVERTISE) && (slot_r >= 0) 
		&& (slot_a >= 0) )
    {
	turnRadioOn();
	post sendAdv();
    }

    return SUCCESS;
  }

  result_t moreSupply()
  {
    int tmp1;

    if ( (slot_t >=0) && (schedule[slot_t] == IDLE) )
	schedule[slot_t] = TRANSMIT_PENDING;

    tmp1 = -1;
    if ( NidoHack && (TOS_LOCAL_ADDRESS == IVY_BASE_STATION_ADDR)  )
    {
     	tmp1 = pickIdleSlot();
    	schedule[tmp1] = TRANSMIT;
        slot_t = tmp1;
        supply++;
    	dbg(DBG_ROUTE, "PowerScheduler::moreSupply: new transmit[%d].\n",tmp1);
        return SUCCESS;
    }


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
   *	   reRoute() is called. 
   *
   */
  event TOS_MsgPtr ReceiveAdv.receive(TOS_MsgPtr adv) {

    IvyNet *message = (IvyNet *) adv->data;

    dbg(DBG_ROUTE, "PowerScheduler: Received an advertisement from mote %d.\n",
							message->mote_id);
    /*
     * Here we keep track of available
     * reservation slots for when we
     * may need more ie
     *  supply < demand	
     *
     * If it's time to re-synch we do
     * that as well. 
     *
     * We wait 2 cycles for a confirmation ack before
     * we timeout - this can be changed
     *
     */
    // NOTE IN PROGRESS
    if (have_parent)
    {
	if (message->mote_id == parentInfo.mote_id)
	{
	    // NOTE IN PROGRESS
 	    if (begin_synch ) {
		begin_synch = FALSE;
    	        call Timer0.stop();
    		dbg(DBG_USR1, "Doing Synch curr_slot[%u] -> mote:%u_slot[%d]\n",
				slot_i,message->mote_id,message->cur_slot);
	        slot_i = message->cur_slot;
    	        call Timer0.start(TIMER_REPEAT, FREQ);
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

    /* NOTE: network motes use staticHops */
    if (message->hop_count != (hops - 1) )
	return adv;

    /*
     * Here were are listening for candidate parents.
     *
     * lowest hop node becomes parent
     *	    - with lowest gradient (ie reserved Tx slots)
     *	    - must be less than self!
     *	    - TODO: closest parent to self toward base station
     * save advertisement info
     * synch timer to slot_i
     */
    if  ((message->hop_count < tmphops) ||   
	(message->hop_count == tmphops) && (message->gradient < tmpgrad))
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
        if ( !begin_init )
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
   *  ReceiveReq
   *
   *  - receive reservation request 
   *  - verify slot availability 
   *  - send immediate confirmation ack 
   *  - increment demand
   */
  event TOS_MsgPtr ReceiveReq.receive(TOS_MsgPtr req) {

    uint16_t sendMote;
    TOS_MsgPtr tmp;
    IvyNet *m = (IvyNet *) req->data;

    if (SynchLeds)
      call Leds.redOn();

    /* do not respond to requests when we are rerouting */
    if (begin_reroute)
	return req;

    tmp = req;
    if ( schedule[m->reserv_slot] == RECEIVE_PENDING )
    {
	if (!ack_pending) 
	{
    	    ack_pending = TRUE;
            tmp = ackPtr;
            ackPtr = req; 
	
	    sendMote = m->mote_id;
	    m->mote_id = TOS_LOCAL_ADDRESS;
	    m->hop_count = hops;
	    m->cur_slot = slot_i;
	    /* TOSH_uwait(5000);	NOTE: hack! */
    	    if (call SendAck.send(sendMote,sizeof(IvyNet),ackPtr)) {
    	    	schedule[m->reserv_slot] = RECEIVE;

 		demand++;

    	        dbg(DBG_ROUTE, "PowerScheduler: Reservation request for slot_i %d=%d from mote[%u] succeeded.\n",slot_i,m->reserv_slot,sendMote);
     	    } else {
                ack_pending = FALSE;
	    } 
	}

    } else {
    	dbg(DBG_ROUTE, "PowerScheduler: Reservation request for slot_i %d=%d failed.\n",slot_i,m->reserv_slot);

   }

    return tmp;
  }
 event result_t SendAck.sendDone(TOS_MsgPtr msg, result_t success)
 {

    if (msg == ackPtr) {
	ack_pending = FALSE;
//        if (SynchLeds)
//            call Leds.redOn();
    }

    return SUCCESS;
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

    dbg(DBG_ROUTE,"PowerScheduler:ReceiveAck for slot[%u], cur slot[%d]=%u.\n",
	m->reserv_slot, slot_i, schedule[slot_i]);

//    if ((schedule[slot_i] == TRANSMIT_PENDING) && (slot_i == (int)m->reserv_slot))
    if (schedule[m->reserv_slot] == TRANSMIT_PENDING) 
    {
    	schedule[m->reserv_slot] = TRANSMIT;
	supply++;

	if (!have_parent) {
	    have_parent = TRUE;
	    begin_reroute = FALSE;
	    signal PowerModeSend.parentNotify(parentInfo.mote_id);
	}
    	dbg(DBG_ROUTE, "PowerScheduler: Confirmation ack succeeded.\n");
    } else
    	dbg(DBG_ROUTE, "PowerScheduler: Confirmation ack failed.\n");
	

    return ack;
  }

  void initRoute() {
    int i;

    for (i=0; i< NUM_SLOTS; i++)
    {
	if ((schedule[i] == TRANSMIT) || (schedule[i] == TRANSMIT_PENDING))
		schedule[i] = (uint8_t) IDLE;
    }

	return;
  } 

  void initSchedule() {
    int i;

    for (i=0; i< NUM_SLOTS; i++)
    {
	schedule[i] = (uint8_t) IDLE;
    }

	return;
  } 

  void turnRadioOn() {

    if (!radio_on)
    {
	radio_on = TRUE;
	if (PowerMgntOn)
	 call CommControl.start();
    }
    return;
  }
  void turnRadioOff() {

    if (radio_on)
    {
	radio_on = FALSE;
	if (PowerMgntOn)
	 call CommControl.stop();
    }
    return;
  }

  bool setRadioMode() {
    if (begin_synch)
    {
	/* turn radio on */
	turnRadioOn();
	return radio_on;
    }

    if (schedule[slot_i] == IDLE) 
    {
	/* turn radio off */
	turnRadioOff();

    } else if (schedule[slot_i] != IDLE) { 
    
	/* turn radio on */
	turnRadioOn();

    }
   
    return radio_on;
  }

 /*
  * staticHops
  *
  * Most multihop algorithms rely on some kind of geographic information
  * like GPS. Ivy network motes only need to know how many hops they
  * are from the nearest base station. Modify PowerScheduler.staticHops()
  * to reflect how many hops from the base station your Ivy network motes are.
  * 
  */
  void staticHops() {
    switch(TOS_LOCAL_ADDRESS)
    {
   	case IVY_BASE_STATION_ADDR:
	    hops = 0; 
	    break;	
   	case 1:
   	case 2:
	    hops = 1; 
	    break;	
   	case 3:
   	case 4:
   	case 5:
	    hops = 2; 
	    break;	
   	default:
	    hops = 3; 
    }

    return;
  }
  void staticHopsX() {
    switch(TOS_LOCAL_ADDRESS)
    {
   	case IVY_BASE_STATION_ADDR:
	    hops = 0; 
	    break;	
   	case 1:
   	case 2:
	    hops = 1; 
	    break;	
   	default:
	    hops = 2; 
    }

    return;
  }

  void staticHopsTestBed() {
    switch(TOS_LOCAL_ADDRESS)
    {
   	case IVY_BASE_STATION_ADDR:
	    hops = 0; 
	    break;	
   	case 1:
   	case 2:
	    hops = 1; 
	    break;	
   	case 3:
	    hops = 2; 
	    break;	
   	case 5:
	    hops = 3; 
	    break;	
   	case 4:
	    hops = 4; 
   	default:
	    hops = 2; 
    }

    return;
  }

  void printSchedule() {
    	dbg(DBG_ROUTE, "PS: %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
		schedule[0],
		schedule[1],
		schedule[2],
		schedule[3],
		schedule[4],
		schedule[5],
		schedule[6],
		schedule[7],
		schedule[8],
		schedule[9],
		schedule[10],
		schedule[11],
		schedule[12],
		schedule[13],
		schedule[14],
		schedule[15],
		schedule[16],
		schedule[17],
		schedule[18],
		schedule[19],
		schedule[20],
		schedule[21],
		schedule[22],
		schedule[23],
		schedule[24],
		schedule[25],
		schedule[26],
		schedule[27],
		schedule[28],
		schedule[29],
		schedule[30],
		schedule[31],
		schedule[32],
		schedule[33],
		schedule[34],
		schedule[35],
		schedule[36],
		schedule[37],
		schedule[38],
		schedule[39]);

    return;
  }

/*
 *	pickIdleSlot
 *
 * Pick a slot at random from a list of IDLE slots.
 * Return an index into the schedule[] array;
 * To be used for Advertisement messages.
 *
 * comment:
 * Make sure the values for BITSHIFT and BITMASK make
 * sense. BITMASK is related to NUM_SLOTS.
 *
 */
  int pickIdleSlot() {
    uint16_t theRand, a, count;
    int i ;

    /* count the number of IDLE slots */
    count = 0;
    i = 0;
    for (i=0; i< NUM_SLOTS; i++)
    {
	if (schedule[i] == IDLE)
		count = count + 1;
    }

    /* pick a number between zero and count-1 */

    if (count != 1)
    {
      theRand  = 1 + ((call Random.rand() >> BITSHIFT) & BITMASK);
      a = theRand % count;

    } else
      a = 0; 

    dbg(DBG_USR2,"Random[%u]: r%ur from %u idle slots\n",theRand,a,count );

    count=0;
    for (i=0; i< NUM_SLOTS; i++)
    {
	if (schedule[i] == IDLE)
	{
  	    if (count == a)
		return i;
	    count++;
	}
    }

    dbg(DBG_USR2,"Random failed: r%ur\n",a);
    return -1;
  }
}

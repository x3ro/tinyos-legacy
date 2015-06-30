includes Beacon;
includes Time;

module TsyncM
{
  provides interface StdControl;
  provides interface Time;
  uses {
    interface StdControl as CommControl;
    interface StdControl as AlarmControl;
    interface StdControl as TimerControl;
    interface StdControl as Sounder;

    interface SendMsg as BeaconSendMsg; 
    interface SendVarLenPacket as UARTSend;
    interface ReceiveMsg as BeaconReceiveMsg;
    interface ReadClock;
    interface Leds;
    interface Alarm;

    interface Timer as Timer0;
    interface Timer as Timer1;

  }
}
implementation
{
  uint32_t  Vdisplace; 
  uint32_t BeaconReceivedClock;  // timestamp of Receive
  uint32_t BeaconReceivedVclock; // Vclock of Receive
  TOS_Msg msg;        // used only for send
  TOS_Msg buf;        // used only for receive
  TOS_MsgPtr bufP;
  uint16_t ourId;
  bool slockV;
  bool rlockV;
  bool msgFree;
  bool bufFree;
  
  /* sync chirping */
  uint16_t rcvLeaderId;  // used for chirping in sync
  uint16_t count, newcount;
  uint8_t soundOn;
  bool valid2;


  result_t getVclock( timeSyncPtr p, uint32_t * P_clock );  

  command result_t StdControl.init() {
    bufP = &buf;
    call CommControl.init();
    call AlarmControl.init();
    call TimerControl.init();
    call Leds.init();
    call Sounder.init(),

    call Leds.greenOn();
    call Leds.redOn();
    call Leds.yellowOn();

    ourId = TOS_LOCAL_ADDRESS;  
    BeaconReceivedClock = 0;
    Vdisplace = 0;
    msgFree = TRUE;
    bufFree = TRUE;
    slockV = FALSE;
    rlockV = FALSE;

    rcvLeaderId = 1;
    valid2 = FALSE;
    count = 0;
    soundOn = 0;
    newcount = 0;

    return SUCCESS;
    }

  /**
   * Tsync startup.  Starts communication and Alarm components;
   * and to "prime" the synchronization, a batch of beacons are
   * launched in order to quickly get in sync (we hope).
   * also sets first wakeup to trigger main task in one second.
   * @author herman@cs.uiowa.edu
   */
  command result_t StdControl.start() {
    call CommControl.start();
    call TimerControl.start();
    call ReadClock.set(100);    // must be done before starting Timer
    call AlarmControl.start();
    call Alarm.set(0,1);
    call Timer0.start(TIMER_REPEAT, 1000); 

    return SUCCESS;
    }

  /**
   * Tsync stop.  Stops communication and alarm components.
   * @author herman@cs.uiowa.edu
   */
  command result_t StdControl.stop() {
    call CommControl.stop();
    call Timer0.stop();
    call Timer1.stop();
    call Alarm.clear();
    call AlarmControl.stop();  // ? This is questionable
    return SUCCESS;
    }

    
  /**
   * Time.getLocalTime merely returns current local clock,
   * provided by ReadClock.read().
   * @author herman@cs.uiowa.edu
   */
  command result_t Time.getLocalTime( timeSyncPtr p ) { 
    p->clock = call ReadClock.read();
    return SUCCESS;
    }

  /**
   * Time.getGlobalTime returns Vclock, possibly adjusting
   * to the targeted global time in a monotonic fashion - 
   * but if the target strays too far, we make a forced
   * adjustment to the target.  Also, if the mote has never
   * synchronized, then getGlobalTime returns FAIL.
   * Even if it returns FAIL, a clock value is provided.
   * (Note: Implemented by a subroutine called "getVclock".)
   * @author herman@cs.uiowa.edu
   */
  command result_t Time.getGlobalTime( timeSyncPtr p ) { 
    uint32_t c = call ReadClock.read();
    return getVclock(p,&c); 
    }
  result_t getVclock( timeSyncPtr p, uint32_t * P_clock ) { 

    p->clock = *P_clock + Vdisplace;
    p->quality = tSynNorm;
    //rlockV = FALSE;  
    return SUCCESS;
    }


  /**
   * Subroutine:  set new target for Vclock.
   * (Maybe someday this should be included in the Time 
   *  interface, but for now, it's just internal.)
   * NOTE: the setVclock MUST BE CALLED from the 
   * fileBeacon task, so that variables such as 
   * BeaconReceivedClock are available.
   * @author herman@cs.uiowa.edu
   */
  void setVclock( uint32_t newVclock ) {

    Vdisplace = newVclock - BeaconReceivedClock;
    slockV = FALSE;
    return;
    }

  /**
   * Dummy "sendBeacon" command just avoids task
   * pre-empting to that we can get more "atomic"
   * timestamping of Beacon messages before they are sent.
   * @author herman@cs.uiowa.edu
   */
command result_t Time.sendBeacon( void * p ) {
    uint32_t OldClock;

    OldClock = call ReadClock.read();
    ((beaconMsgPtr) p)->sndClock = OldClock;
    ((beaconMsgPtr) p)->sndVclock = OldClock + Vdisplace;
    ((beaconMsgPtr) p)->sndLeaderId = rcvLeaderId;
    
    if(call BeaconSendMsg.send(TOS_BCAST_ADDR, sizeof(beaconMsg), &msg) == FAIL)      {
    	msgFree = TRUE;
    }	 

    return SUCCESS;
    }


  /**
   * genBeacon is a task to generate a Beacon message.
   * Planned (but not implemented here) is support for 
   * GPS-triggered posting, via the pulse-per-second of 
   * an attached GPS, which can be useful for instrumentation
   * and debugging.  But not yet included in the NestArch context.
   * @author herman@cs.uiowa.edu
   */
  task void genBeacon() {
    beaconMsgPtr p;
    if (!msgFree) return;
	
    if (ourId == 0) return;
    msgFree = FALSE;
    p = (beaconMsgPtr) msg.data;
    p->sndId = ourId;
    call Time.sendBeacon( (void *) p );
    }

  /**
   * Tsync's main task: schedules, by alarm wakeup, 
   * beacon and aging tasks (and also reschedules itself).
   * The timimgs should be adjusted based on experience
   * in actual networks.
   * @author herman@cs.uiowa.edu
   */
  task void mainTask() {
    uint16_t i, bstep, limit;
    bstep = BEACON_ITVL;
    limit = bstep << 2;      // four step sequence
    for ( i=bstep; i<=limit; i += bstep ) call Alarm.set(1,i); 
    call Alarm.set(0,limit);
    }

  /**
   * Task to process a beacon message.  The algorithm
   * embodied in this task adjusts the clock, deals with
   * fault tolerance (via aged neighbor set).
   * @author herman@cs.uiowa.edu
   */
  task void fileBeacon() { 
    uint32_t x;
    beaconMsgPtr p;

    p = (beaconMsgPtr) bufP->data;
    x = p->sndVclock + CLOCK_FUZZ;  // crude approximation to sent Vclock

    if (x > BeaconReceivedVclock) 
       setVclock(x);
    if(p->sndLeaderId == 1)
	 rcvLeaderId = 1;

    bufFree = TRUE;

    if(valid2 == FALSE) {
		call Timer1.start(TIMER_REPEAT, 20);
		valid2 = TRUE;
    }
    }

  /**
   * relayBeacon (for mote # 0) just resends a beacon
   * to the UART so that basestation can eavesdrop ...
   * @author herman@cs.uiowa.edu
   */
  task void relayBeacon() { 
    beaconMsgPtr p = (beaconMsgPtr) bufP->data;
    bufP->addr = TOS_UART_ADDR;
    call UARTSend.send((uint8_t *)bufP,36); // hardcode 36
    p = NULL; // keep NeSC quiet.
    }

  /**
   * Receive a beacon message and post fileBeacon to 
   * process it (provided there is a free buffer). 
   * @author herman@cs.uiowa.edu
   */
  event TOS_MsgPtr BeaconReceiveMsg.receive( TOS_MsgPtr m ) {
    TOS_MsgPtr p;
    timeSync_t v;
    if (!bufFree) return m;
    bufFree = FALSE;
    p = bufP;  
    bufP = m;
    BeaconReceivedClock = call ReadClock.read(); 
    //getVclock(&v,&BeaconReceivedClock);
    BeaconReceivedVclock = BeaconReceivedClock + Vdisplace; 
    
    if (ourId != 0) post fileBeacon();
    else post relayBeacon();
    return p;  
    }

  /**
   * Free up beacon buffer after sendDone posted. 
   * @author herman@cs.uiowa.edu
   */
  event result_t BeaconSendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    msgFree = TRUE;
    return SUCCESS;
    }
 
  /**
   * Free up beacon buffer after UART send is done.
   * @author herman@cs.uiowa.edu
   */
  event result_t UARTSend.sendDone(uint8_t * sent, result_t success) {
    bufFree = TRUE; 
    return SUCCESS; 
    }

  /**
   * Alarm wakeup.  Here's where we use the index feature of wakeups
   * to post the appropriate task for the event.  
   * @author herman@cs.uiowa.edu
   */
  event result_t Alarm.wakeup(uint8_t indx, uint32_t wake_time) {
    switch (indx) {
      case 0: post mainTask(); break;
      case 1: post genBeacon(); break;
      }
    return SUCCESS;
    }


  event result_t Timer0.fired() {

	newcount = newcount + 1;
	if(valid2 == FALSE) {

	       if(soundOn == 0) {
      			call Sounder.start();
			      soundOn = 1;
	       }
	       else if(soundOn == 1) {
			call Sounder.stop();
		      	soundOn = 0;
	       }

	       call Leds.redToggle();
	}

	if(newcount >= 7) {
		valid2 = TRUE;
		call Timer0.stop();
		call Timer1.start(TIMER_REPEAT, 20);
	}

	return SUCCESS;

	

  }

  event result_t Timer1.fired() {

  timeSync_t globaltime;
  uint32_t sync1;
  uint32_t perc ;

  if(rcvLeaderId == 1)
	  perc = 32000;
  else 
	  perc = 64000;

  if(valid2 == TRUE) {

		call Time.getGlobalTime(&globaltime);
		sync1 = globaltime.clock % perc; 

		if ((sync1 <= 1000) || (perc - sync1 <= 1000)) {
     			call Sounder.start();
			call Leds.yellowOn();
			call Leds.redOn();
	            call Leds.greenOff();
		}
		else {
			call Sounder.stop();
	            call Leds.greenOn();
	            call Leds.yellowOff();
			call Leds.redOff();
		}
 
    }
     return SUCCESS;
  }

}


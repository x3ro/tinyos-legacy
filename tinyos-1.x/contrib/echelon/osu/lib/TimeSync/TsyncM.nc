includes OTime;
includes Beacon;

module TsyncM
{
  provides interface StdControl;
  uses {
    interface StdControl as CommControl;
    interface StdControl as AlarmControl;
    interface StdControl as OTimeControl;
    interface SendMsg as BeaconSendMsg; 
    interface ReceiveMsg as BeaconReceiveMsg;
    interface SendMsg as ProbeSendMsg;
    interface ReceiveMsg as ProbeReceiveMsg;
    interface TimeStamping;
    interface OTime;
    interface Leds;
    interface Alarm;
  }
}
implementation
{
  /* These are "outbound" beacon variables */
  timeSync_t genTime;

  /* These are variables for processing a received beacon */
  timeSync_t receiveTime;
  int16_t theDiff;

  /* Buffers, switches, etc */
  TOS_Msg msg;        // used only for send
  TOS_Msg buf;        // used only for receive
  TOS_MsgPtr bufP;
  uint16_t ourId;
  bool msgFree;
  bool bufFree;

  /**
   * Tsync initialization. 
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.init() {
    bufP = &buf;
    call CommControl.init();
    call AlarmControl.init();
    call OTimeControl.init();
    ourId = TOS_LOCAL_ADDRESS;  
    msgFree = TRUE; 
    bufFree = TRUE;
    theDiff = 0;
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
    uint8_t i;
    call CommControl.start();
    call AlarmControl.start();
    call OTimeControl.start();
    for (i=1; i<13; i++) call Alarm.set(1,5*i);
    call Alarm.set(0,60);
    return SUCCESS;
    }

  /**
   * Tsync stop.  Stops communication and alarm components.
   * @author herman@cs.uiowa.edu
   */
  command result_t StdControl.stop() {
    call CommControl.stop();
    call Alarm.clear();
    call AlarmControl.stop();  // ? This is questionable
    call OTimeControl.stop();
    return SUCCESS;
    }

  /**
   * genBeacon is a task to generate a Beacon message.
   * @author herman@cs.uiowa.edu
   */
  task void genBeacon() {
    beaconMsgPtr p;
    result_t r;

    if (!msgFree) return;  
    if (ourId == 0) return;
    msgFree = FALSE;
    p = (beaconMsgPtr) msg.data;

    call OTime.getLocalTime( &genTime );

    p->sndId = ourId;
    p->prevDiff = theDiff;
    p->Local.ClockH = genTime.ClockH; 
    p->Local.ClockL = genTime.ClockL;
    p->AdjClock = 0;
    p->Dummy = 0;

    call OTime.convLocalTime( &genTime ); 
    p->Virtual.ClockH = genTime.ClockH; 
    p->Virtual.ClockL = genTime.ClockL; 

    dbg(DBG_USR1, "generating Beacon\n");

    r = call BeaconSendMsg.send(TOS_BCAST_ADDR, sizeof(beaconMsg), &msg); 

    if (r != SUCCESS) {
       msgFree = TRUE;  // if failure, exit
       return;
       }

    call TimeStamping.addStamp((int8_t)
       ( (uint16_t)(&p->AdjClock) - (uint16_t)p) ); 
    //call Leds.greenToggle();
    }

  /**
   * Tsync's main task: schedules, by alarm wakeup, 
   * beacon and aging tasks (and also reschedules itself).
   * The timimgs should be adjusted based on experience
   * in actual networks.
   * @author herman@cs.uiowa.edu
   */
  task void mainTask() {
    call Alarm.set(1,60);
    call Alarm.set(0,60);
    }

  /**
   * Task to process a beacon message.  The algorithm
   * embodied in this task adjusts the clock, deals with
   * fault tolerance (via aged neighbor set).
   * @author herman@cs.uiowa.edu
   */
  task void fileBeacon() { 
    beaconMsgPtr q;
    uint32_t w;
    timeSync_t saveLocal;
    timeSync_t V;

    q = (beaconMsgPtr) bufP->data;
    saveLocal.ClockH = receiveTime.ClockH;
    saveLocal.ClockL = receiveTime.ClockL;

    call OTime.convLocalTime( &receiveTime );  // our Glolal Time when recvd

    call Leds.redToggle();

    // increment q->VClock due to MAC delay
    // manual processing instead of OTime arithmetic calls 
    // because of incomplete MAC delay representation
    if (q->AdjClock <= q->Local.ClockL) {
       bufFree = TRUE;  // cannot process rollover of other guy's clock
       return; 
       }
    w = q->Virtual.ClockL + (q->AdjClock - q->Local.ClockL);
    // consider carry bit if necessary
    if (w < q->Virtual.ClockL) q->Virtual.ClockH++;
    q->Virtual.ClockL = w;

    // now adjust q->Local so that transcription will be accurate
    q->Local.ClockL = q->AdjClock;

    // *** Compute Delta for Instrumentation ********************
    // compute difference between our VClockL and incoming VClockL
    if (call OTime.lesseq(&q->Virtual,&receiveTime)) { 
       // if we are ahead of other guy
       call OTime.subtract(&receiveTime,&q->Virtual,&V);
       if (V.ClockH != 0 || V.ClockL > 32767u) theDiff = 32767;
       else theDiff = (int16_t)((uint16_t)V.ClockL);
       }
    else {  // we are behind the other guy 
       call OTime.subtract(&q->Virtual,&receiveTime,&V);
       if (V.ClockH != 0 || V.ClockL > 32767u) theDiff = - 32767;
       else theDiff = - (int16_t)((uint16_t)V.ClockL);
       }

    // exit now if incoming time is smaller than our own
    if (call OTime.lesseq(&q->Virtual,&receiveTime)) {
       bufFree = TRUE;
       return; 
       }

    call Leds.yellowToggle();

    // incoming beacon has larger VClock -- adjust upwards
    // first, compute difference when our VClockL was behind 
    // second, use the difference to adjust upwards
    call OTime.subtract(&q->Virtual,&receiveTime,&V);
    call OTime.adjGlobalTime( &V );
    bufFree = TRUE;
    }

  /**
   * Receive a beacon message and post fileBeacon to 
   * process it (provided there is a free buffer). 
   * @author herman@cs.uiowa.edu
   */
  event TOS_MsgPtr BeaconReceiveMsg.receive( TOS_MsgPtr m ) {
    TOS_MsgPtr p;
    beaconMsgPtr q;
    uint32_t recClock;
    if (!bufFree) return m; 

    q = (beaconMsgPtr) m->data;
    recClock = call TimeStamping.getStamp();  // get local clock at time 
                                           // when it was actually received 
    call OTime.getLocalTime( &receiveTime );  // also, get current 48-bit time
    if (receiveTime.ClockL < recClock) return m;
                                      // abort if local clock rolled over
    receiveTime.ClockL = recClock; 
    
    atomic { bufFree = FALSE; }
    p = bufP;  
    bufP = m;
    post fileBeacon();
    return p;  
    }

  /**
   * Receive a probe message and immediately respond 
   * (provided there is a free buffer). 
   */
  event TOS_MsgPtr ProbeReceiveMsg.receive( TOS_MsgPtr m ) {
    beaconProbeMsgPtr q;
    beaconProbeAckPtr r;
    uint32_t recTime;
    if (!msgFree) return m;
    
    q = (beaconProbeMsgPtr) m->data;
    call OTime.getLocalTime( &genTime );

    recTime = call TimeStamping.getStamp();
    if (recTime > genTime.ClockL) {
        return m;   // currently doesn't handle rollover at this point 
        }

    msgFree = FALSE;

    genTime.ClockL = recTime; 

    r = (beaconProbeAckPtr) msg.data; 
    r->count = q->count;
    r->sndId = ourId;
    r->Local.ClockH  = genTime.ClockH;
    r->Local.ClockL  = genTime.ClockL;
    call OTime.convLocalTime( &genTime );
    r->Virtual.ClockH = genTime.ClockH;
    r->Virtual.ClockL = genTime.ClockL;
    call ProbeSendMsg.send(TOS_BCAST_ADDR, sizeof(beaconProbeAck), &msg);
    return m;  
    }

  /**
   * Free up beacon buffer after sendDone posted. 
   * @author herman@cs.uiowa.edu
   */
  event result_t BeaconSendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    msgFree = TRUE;
    return SUCCESS;
    }
  event result_t ProbeSendMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    msgFree = TRUE;
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

}


/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Ted Herman (herman@cs.uiowa.edu)
 *
 */

includes Beacon;
includes Time;

module TsyncM
{
  provides interface StdControl;
  provides interface Time;
  uses {
    interface StdControl as CommControl;
    interface StdControl as AlarmControl;
    interface SendMsg as BeaconSendMsg; 
    interface SendVarLenPacket as UARTSend;
    interface ReceiveMsg as BeaconReceiveMsg;
    interface ReadClock;
    interface Leds;
    interface Alarm;
  }
}
implementation
{
  // Define Virtual Clock:  Vclock to be the sum of 
  // a displacement (Vdisplace) and the Clock,
  // Similarly, define a target virtual clock: VclockT
  // to be the sum of a displacement (VdisplaceT) and
  // the Clock. 
  uint32_t  Vdisplace; 

  /* These are variables for processing a received beacon */
  uint32_t BeaconReceivedClock;  // timestamp of Receive
  uint32_t BeaconReceivedVclock; // Vclock of Receive

  /* Buffers, switches, etc */
  TOS_Msg msg;        // used only for send
  TOS_Msg buf;        // used only for receive
  TOS_MsgPtr bufP;
  uint16_t ourId;
  bool slockV;
  bool rlockV;
  bool msgFree;
  bool bufFree;
  

  /* subroutine definitions filled out below */
  result_t getVclock( timeSyncPtr p, uint32_t * P_clock );  

  /**
   * Tsync initialization. 
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.init() {
    bufP = &buf;
    call CommControl.init();
    call AlarmControl.init();
    ourId = TOS_LOCAL_ADDRESS;  
    BeaconReceivedClock = 0;
    Vdisplace = 0;
    msgFree = TRUE;
    bufFree = TRUE;
    slockV = FALSE;
    rlockV = FALSE;
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
    call ReadClock.set(100);    // must be done before starting Timer
    call AlarmControl.start();
    call Alarm.set(0,1);
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

    // avoid concurrent update while someone is reading
    slockV = TRUE;
    if (rlockV) {
       slockV = FALSE;
       return;
       }

    // assign new target displacement only
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
    timeSync_t v;
    uint32_t OldClock;
    OldClock = call ReadClock.read();
    getVclock(&v,&OldClock);
    ((beaconMsgPtr) p)->sndClock = OldClock;
    ((beaconMsgPtr) p)->sndVclock = v.clock;
    
	if( call BeaconSendMsg.send(TOS_BCAST_ADDR, sizeof(beaconMsg), &msg)== FAIL)
		msgFree = TRUE; 
    return;

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

    bufFree = TRUE;

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
    getVclock(&v,&BeaconReceivedClock);
    BeaconReceivedVclock = v.clock;
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

}


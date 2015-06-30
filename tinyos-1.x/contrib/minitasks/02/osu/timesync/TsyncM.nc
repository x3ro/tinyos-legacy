/*
 * Copyright Ted Herman, 2003, All Rights Reserved.
 * To the user: Ted Herman does not and cannot warrant the
 * product, information, documentation, or software (including
 * any fixes and updates) included in this package or the
 * performance or results obtained by using this product,
 * information, documentation, or software. This product,
 * information, documentation, and software is provided
 * "as is". Ted Herman makes no warranties of any kind,
 * either express or implied, including but not limited to,
 * non infringement of third party rights, merchantability,
 * or fitness for a particular purpose with respect to the
 * product and the accompanying written materials. To the
 * extent you use or implement this product, information,
 * documentation, or software in your own setting, you do so
 * at your own risk. In no event will Ted Herman be liable
 * to you for any damages arising from your use or, your
 * inability to use this product, information, documentation,
 * or software, including any lost profits, lost savings,
 * or other incidental or consequential damages, even if
 * Ted Herman has been advised of the possibility of such
 * damages, or for any claim by another party. All product
 * names are trademarks or registered trademarks of their
 * respective holders. Any resemblance to real persons, living
 * or dead is purely coincidental. Contains no peanuts. Void
 * where prohibited. Batteries not included. Contents may
 * settle during shipment. Use only as directed. No other
 * warranty expressed or implied. Do not use while operating a
 * motor vehicle or heavy equipment. This is not an offer to
 * sell securities. Apply only to affected area. May be too
 * intense for some viewers. Do not stamp. Use other side
 * for additional listings. For recreational use only. Do
 * not disturb. All models over 18 years of age. If condition
 * persists, consult your physician. No user-serviceable parts
 * inside. Freshest if eaten before date on carton. Subject
 * to change without notice. Times approximate. Simulated
 * picture. Children under 12 must wear a helmet. May cause
 * oily discharge. Contents under pressure. Pay before pumping
 * after dark. Paba free. Please remain seated until the ride
 * has come to a complete stop. Breaking seal constitutes
 * acceptance of agreement. For off-road use only. As seen on
 * TV. One size fits all. Many suitcases look alike. Contains
 * a substantial amount of non-tobacco ingredients. Colors
 * may, in time, fade. Slippery when wet. Not affiliated with
 * the American Red Cross. Drop in any mailbox. Edited for
 * television. Keep cool; process promptly. Post office will
 * not deliver without postage. List was current at time of
 * printing. Not responsible for direct, indirect, incidental
 * or consequential damages resulting from any defect,
 * error or failure to perform. At participating locations
 * only. Not the Beatles. See label for sequence. Substantial
 * penalty for early withdrawal. Do not write below this
 * line. Falling rock. Lost ticket pays maximum rate. Your
 * canceled check is your receipt. Add toner. Avoid
 * contact with skin. Sanitized for your protection. Be
 * sure each item is properly endorsed. Sign here without
 * admitting guilt. Employees and their families are not
 * eligible. Beware of dog. Contestants have been briefed
 * on some questions before the show. You must be present
 * to win. No passes accepted for this engagement. Shading
 * within a garment may occur. Use only in a well-ventilated
 * area. Keep away from fire or flames. Replace with same
 * type. Approved for veterans. Booths for two or more. Check
 * if tax deductible. Some equipment shown is optional. No
 * Canadian coins. Not recommended for children. Prerecorded
 * for this time zone. Reproduction strictly prohibited. No
 * solicitors. No alcohol, dogs or horses. No anchovies
 * unless otherwise specified. Restaurant package, not for
 * resale. List at least two alternate dates. First pull up,
 * then pull down. Call before digging. Driver does not carry
 * cash. Some of the trademarks mentioned in this product
 * appear for identification purposes only. Objects in
 * mirror may be closer than they appear. Record additional
 * transactions on back of previous stub. Do not fold,
 * spindle or mutilate. No transfers issued until the bus
 * comes to a complete stop. Package sold by weight, not
 * volume. Your mileage may vary. Parental discretion is
 * advised. Warranty void if this seal is broken. Employees
 * do not know combination to safe. Do not expose to rain
 * or moisture. To prevent fire hazard, do not exceed listed
 * wattage. Do not use with any other power source. May cause
 * radio and television interference. Consult your doctor
 * before starting this, or any other program. Drain fully
 * before recharging.
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
    interface ReceiveMsg as BeaconReceiveMsg;
    interface readClock;
    interface Leds;
    interface Alarm;
  }
}
implementation
{
  uint32_t GPSclock;  // mainly for instrumentation (supported by
  uint32_t GPSshow;   // code during development;  removed for NestArch,
                      // but maybe dropped in later, so we keep it)
  uint16_t lowId;
  uint16_t ourId;
  uint8_t hopDist;
  neighbor N[NUM_NEIGHBORS];  
  TOS_Msg msg;
  TOS_Msg buf;
  TOS_MsgPtr bufP;
  bool msgFree;
  bool bufFree;
  bool gotSync;

  /**
   * Tsync initialization. 
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.init() {
    uint8_t i;
    bufP = &buf;
    for (i=0; i<NUM_NEIGHBORS; i++) N[i].bCnt = 0;
    call CommControl.init();
    call AlarmControl.init();
    ourId = TOS_LOCAL_ADDRESS;  
    lowId = 0;
    hopDist = 0;
    GPSclock = 0;
    GPSshow = 0;
    msgFree = TRUE;
    bufFree = TRUE;
    gotSync = FALSE;
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
    call readClock.set(0);  // must be done before starting Timer
    call AlarmControl.start();
    for (i=1; i<6; i++) call Alarm.set(1,i);
    call Alarm.set(0,6);
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
   * Subroutine:  calculate how many neighbors we have.
   */
  uint8_t nCnt() {
    uint8_t i,s;
    // (re)-compute nCnt
    for (i=0, s=0; i<NUM_NEIGHBORS; i++) if (N[i].bCnt != 0) s++;
    return s;
    }

  /**
   * Time.getLocalTime merely returns current local clock,
   * provided by readClock.read().
   * @author herman@cs.uiowa.edu
   */
  command result_t Time.getLocalTime( timeSyncPtr p ) { 
    p->clock = call readClock.read();
    return SUCCESS;
    }

  /**
   * Time.getGlobalTime returns current local clock,
   * provided by readClock.read() if this mote has 
   * established contact with other motes to synchronize.
   * Even if it returns FAIL, a clock value is provided.
   * @author herman@cs.uiowa.edu
   */
  command result_t Time.getGlobalTime( timeSyncPtr p ) { 
    p->clock = call readClock.read();
    if (gotSync ||
        (lowId == ourId && nCnt() > 0)) return SUCCESS;
    return FAIL;
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
    dbg(DBG_USR1, "generating Beacon\n");
    if (lowId == 0) lowId = ourId;
    p = (beaconMsgPtr) & msg.data[0];
    if (!msgFree) return;
    p->sndId = ourId;
    p->lowId = lowId; 
    p->nCount = nCnt();
    p->sndClock = call readClock.read();
    p->GPSClock = GPSshow;  
    GPSshow = 0;
    p->hops = hopDist;
    msgFree = FALSE;
    call BeaconSendMsg.send(TOS_BCAST_ADDR, sizeof(beaconMsg), &msg); 
    call Leds.redToggle();
    }

  /**
   * Tsync's main task: schedules, by alarm wakeup, 
   * beacon and aging tasks (and also reschedules itself).
   * The timimgs should be adjusted based on experience
   * in actual networks.
   * @author herman@cs.uiowa.edu
   */
  task void mainTask() {
    // schedule two beacons at +15 and +30 second delay 
    call Alarm.set(1,15);
    call Alarm.set(1,30);
    // schedule aging of neighbor set at +45 delay
    call Alarm.set(2,45);
    // schedule restart of this task at +60 delay
    call Alarm.set(0,60);
    }

  /**
   * Subroutine:  figure out from neighbor table
   * who has the best idea for a root mote id. 
   * @author herman@cs.uiowa.edu
   */
  void calcLowId() { 
    uint8_t i;

    // start by assumption: we are the root
    lowId = ourId; 
    hopDist = 0; 

    // Now see if any neighbor can offer a better root
    for (i=0; i<NUM_NEIGHBORS; i++) { 
      if (N[i].bCnt == 0 || N[i].lowId > lowId) continue;
      if (N[i].lowId < lowId && N[i].hops < BOUND_DIAMETER) {
         lowId = N[i].lowId;
	 hopDist = 1 + N[i].hops;
	 }
      if (N[i].id == lowId && (1 + N[i].hops) < hopDist)  
         hopDist = 1 + N[i].hops;
      }
    }

  /**
   * Task to process a beacon message.  The algorithm
   * embodied in this task adjusts the clock, deals with
   * fault tolerance (via aged neighbor set).
   * @author herman@cs.uiowa.edu
   */
  task void fileBeacon() { 
    uint8_t i,j;
    uint16_t oldLowId;
    uint32_t v;
    beaconMsgPtr p;

    p = (beaconMsgPtr) &bufP->data[0];

    // if there are no neighbors currently, then make a special
    // one-time clock setting (so as to retain the network time
    // in case we have the lowest Id)
    if (nCnt() == 0) {
       call readClock.set(p->sndClock);
       gotSync = TRUE;
       call Leds.greenToggle();
       }

    // either find active id matching beacon or empty slot
    for (i=0; i<NUM_NEIGHBORS; i++) 
      if (N[i].bCnt != 0 && N[i].id == p->sndId) break;
    if (i==NUM_NEIGHBORS) 
      for (i=0; i<NUM_NEIGHBORS; i++) if (N[i].bCnt == 0) break;

    // kick out a neighbor entry if candidate is superior
    if (i==NUM_NEIGHBORS)  
      for (i=0; i<NUM_NEIGHBORS; i++) 
        if ( p->lowId < N[i].lowId ||
            (p->lowId == N[i].lowId && p->hops < N[i].hops) ) break;
    if (i==NUM_NEIGHBORS) {
       bufFree = TRUE;
       return;  // ignore msg if table full!
       }

    // now slot i is for recording
    N[i].bCnt |= 0x80;  // indicate a message received
    N[i].id = p->sndId;
    N[i].lowId = p->lowId;
    N[i].hops = p->hops;

    oldLowId = lowId;
    calcLowId();

    // Maybe it's a good idea to adopt a new clock value
    if (p->nCount == 0) { // but ignore a loner 
       bufFree = TRUE;
       return;
       }
    for (i=0, j=BOUND_DIAMETER; i<NUM_NEIGHBORS; i++) { 
       if (N[i].bCnt == 0 || N[i].lowId != lowId) continue;
       if (N[i].hops < j) j = N[i].hops;
       }
    if (p->lowId == lowId && p->hops == j && j < hopDist) { 
       if (oldLowId != lowId) { 
          call readClock.set(p->sndClock);
          gotSync = TRUE;
          call Leds.greenToggle();
          }
       else {
         v = call readClock.read();
         if (p->sndClock < v) {
            call readClock.set(p->sndClock);  
            gotSync = TRUE;
            call Leds.greenToggle();
            }
         }
       }
    bufFree = TRUE;
    }

  /**
   * Task to "age" neighbor set --- mainly we want
   * to discard from neighbor set anyone who hasn't
   * sent out a beacon for a while. 
   * @author herman@cs.uiowa.edu
   */
  task void age() {
    // force a kind of "TTL" on neighbors
    uint8_t i;
    for (i=0; i<NUM_NEIGHBORS; i++) N[i].bCnt >>= 1;
    calcLowId();
    }

  /**
   * Receive a beacon message and post fileBeacon to 
   * process it (provided there is a free buffer). 
   * @author herman@cs.uiowa.edu
   */
  event TOS_MsgPtr BeaconReceiveMsg.receive( TOS_MsgPtr m ) {
    TOS_MsgPtr p;
    if (!bufFree) return m;
    call Leds.yellowToggle();
    bufFree = FALSE;
    p = bufP;  
    bufP = m;
    post fileBeacon();
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
   * Alarm wakeup.  Here's where we use the index feature of wakeups
   * to post the appropriate task for the event.  
   * @author herman@cs.uiowa.edu
   */
  event result_t Alarm.wakeup(uint8_t indx, uint32_t wake_time) {
    switch (indx) {
      case 0: post mainTask(); break;
      case 1: post genBeacon(); break;
      case 2: post age(); break;
      }
    return SUCCESS;
    }

}


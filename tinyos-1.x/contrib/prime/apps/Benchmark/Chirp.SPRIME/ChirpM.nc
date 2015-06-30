/*									tab:4
 * CHIRP.c - periodically emits an active message containing light reading
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:   Lin Gu
 * History:   Modified 11/28/2002
 *
 * Authors:   David Culler
 * History:   created 10/5/2000
 *
 */

/**
 * The Chirp application periodically sends a broadcast packet over the
 * radio using a timer.  The packet contains the current photo sensor
 * reading.
 */

includes PktDef;

module ChirpM
{
  provides interface StdControl;
  uses {
    interface Leds;
    interface Timer;
    interface ADC;
    interface StdControl as ADCControl;
    interface StdControl as CommControl;
    interface SendMsg as SendChirpMsg;
    interface ReceiveMsg as ReceiveChirpMsg;
    interface Peek;
  }
}
implementation
{
#define MASK 2
#define JUST_LISTENno
#define CHP_START 80 /* 50 */

  //#define  MAX_CHIRPS (20+TOS_LOCAL_ADDRESS * 2)
#define  MAX_CHIRPS 160
#define dest ((TOS_LOCAL_ADDRESS + 1) % MASK)

  int nlastseq;
  uint16_t nLastSrc;
  typedef struct {
    long nSeq;
    long lGot;
    long me;
    long desti;
  } ChirpPacket;

  uint16_t counter;		/* Component counter counter */
  Cell msg;			/* Message to be sent out */
  bool sendPending;		/* Variable to store counter of buffer*/
  long lGot;

  /**
   * Chirp initialization: <p>
   * turn on the LEDs<br>
   * initialize lower components.<br>
   * initialize component counter, including constant portion of msgs.<br>
   *
   * @return the result from <code>ADCControl.init()</code> 
   *         and <code>CommControl.init()</code>
   */
  command result_t StdControl.init() {
    call Leds.init();
    /* call Leds.redOn();
    call Leds.greenOn();
    call Leds.yellowOn();*/
    counter = 0;
    nlastseq  = 0;
    lGot = 0;
    nLastSrc = 0xffff;
    sendPending = FALSE;
    msg.data[0] = TOS_LOCAL_ADDRESS; //record your id in the packet.
    dbg(DBG_BOOT, "CHIRP initialized\n");
    dbg(DBG_USR1, "CHIRP initialized\n");
    return rcombine(call ADCControl.init(),
		    call CommControl.init());
  }

  /**
   * Chirp start starts the Timer
   *
   * @return the result from <code>Timer.start()</code>
   */
  command result_t StdControl.start() {
    call CommControl.start();
    call Timer.start(TIMER_REPEAT, 400);
    call Leds.greenOff();
    return SUCCESS;
  }

  /**
   * Chirp stop stops the Timer
   *
   * @return the result from <code>Timer.stop()</code>
   */
  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /**
   * Triggers completion activities such as turning the Green LED off
   * and setting the <code>sendPending</code> variable.
   */
  void sendComplete() {
    // //////// call Leds.greenOff();
    sendPending = FALSE;
  }

  void dumpPacket(CellPtr pmsg)
    {
      if (pmsg)
	{
	  char *p0 = (char *)(pmsg->data),
	    *p1 = ((char *)pmsg)+(sizeof(Cell));
      
	  dbg(DBG_AM, "PRIME:dumpPacket: pmsg %x\n", pmsg);
	  dbg(DBG_AM, "addr:%x ty:%hhx grp:%hhx\n",
	      pmsg->addr, pmsg->type, pmsg->group, pmsg->length);

	  while (p0<p1)
	    {
	      dbg_clear(DBG_AM, "%hhx,", *p0++);
	    }
	  dbg(DBG_AM, ("\n"));
	} // pmsg
    } // dumpPacket

  /** Timer Event Handler:<br>
   * Signaled at end of each clock interval.
   * When a Timer event occurs, sample the photo sensor.
   *
   * @return SUCCESS always
   */
  event result_t Timer.fired(){
    // call Leds.redOff();
    static char cRot;
    
    //    cRot++;

    if (cRot & 0x1)
      {
	// dump to UART
#ifdef JUST_LISTEN
	call Peek.print4Int(nlastseq, nLastSrc, lGot, 0xcdab);
	call Leds.redToggle();
#endif
	return SUCCESS;
      }

#ifdef JUST_LISTEN
    return SUCCESS;
#endif

    if (counter < MAX_CHIRPS + CHP_START/* && !sendPending*/)
      {
	ChirpPacket *pchpMsg = (ChirpPacket *)(msg.data);
	counter++;

	if (counter < CHP_START)
	  {return SUCCESS;}

	//turn on the red led while data is being read.

	sendPending = TRUE;
	pchpMsg->nSeq = counter;
	pchpMsg->lGot = lGot;
	pchpMsg->me = TOS_LOCAL_ADDRESS;
	pchpMsg->desti = dest;

	call Leds.redToggle();

	// call Leds.set( counter & 0x7);

	dbg(DBG_USR1, "ChirpM: sending #%d\n", pchpMsg->nSeq);
	if (call SendChirpMsg.send(dest, 10, ((TOS_MsgPtr)(&msg))) == FAIL)
	  {
	    dbg(DBG_USR1, "ChirpM: send fail\n");
	  }
	sendComplete();
      }
    return SUCCESS;
  }

  /**
   * Handler for subsystem data event, fired when data ready from the photo
   * sensor.  Put int data in a broadcast message to handler 0.
   * Post msg to be sent over the radio.
   *
   * @param data the value of the photo sensor
   *
   * @return SUCCESS always
   */
  event result_t ADC.dataReady(uint16_t data) {
    // /////// call Leds.redOff();
    // call Leds.greenToggle(); /* Green LED while sending */
  
    msg.data[1] = (data >> 8) & 0xff;
    msg.data[2] = data & 0xff;
    if (call SendChirpMsg.send(TOS_BCAST_ADDR, 20, 
			       ((TOS_MsgPtr)(&msg))) == FAIL)
      sendComplete();

    return SUCCESS;
  }

  /**
   * Notification that the message has been sent over the radio
   *
   * @param sent the message buffer of the sent message
   * @param success the result of sending the message
   *
   * @return SUCCESS always
   */
  event result_t SendChirpMsg.sendDone(TOS_MsgPtr sent, result_t success) {
    //check to see if the message that finished was yours.
    //if so, then clear the sendPending flag.
    if (((TOS_MsgPtr)(&msg)) == sent)
      sendComplete();

    return SUCCESS;
  }

  /**
   * Message Handler for Chirp packets.  When a new packet comes in,
   * blink the yellow LED.
   *
   * @param data msg buffer passed (incoming packet)
   *
   * @return msg buffer to be reused
   */
  event TOS_MsgPtr ReceiveChirpMsg.receive(TOS_MsgPtr data) {
    ChirpPacket *pchpIn = (ChirpPacket *)(data->data);

    dbg(DBG_USR1, "ChirpM: receive chirp %x from ...\n",
	pchpIn->nSeq/*, data->nSrc*/);
    /*if (nlastseq < pchpIn->nSeq)
      {	*/
    lGot++;
    nlastseq = pchpIn->nSeq;
    nLastSrc = ((Cell *)data)->nSrc;
    /*}*/
    call Leds.greenToggle();
    return data;
  }
}

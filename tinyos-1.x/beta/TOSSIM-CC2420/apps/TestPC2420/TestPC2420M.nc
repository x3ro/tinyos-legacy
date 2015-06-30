// $Id: TestPC2420M.nc,v 1.2 2005/05/16 07:00:52 overbored Exp $

/*									tab:4
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

// TODO finish the last test
// TODO add tests where we start/stop the radio
// TODO fix the segfault bug when this is run on a huge network

/**
 * Implementation for the TestPC2420 application.
 **/
module TestPC2420M {
  provides {
    interface StdControl;
  }
  uses {
    interface CC2420Control;
    interface MacControl;
    interface Timer as SendTimer;
    interface Timer as ResponseTimer;
    interface Leds;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
//    interface HPLCC2420Interrupt as FIFOP;
//    interface HPLCC2420Interrupt as CCA;
  }
}

implementation {

  //
  // Values for testId (somewhat ordered from least to most sophisticasted):
  //  0/ nothing
  //  1/ 0 > 1
  //  2/ 0 > all
  //  3/ 0 1 > 2
  //  4/ 0 1 > all
  //  5/ 0 > 1 ; 1 > 0
  //  6/ 0 > 1
  //     1 > 0
  //  7/ 0 > all ; all > 0
  //  8/ 0 > all
  //     all > 0
  //  9  0 > all ; all > +1
  // 10  all > +1
  //
  // Status;
  // * = works
  // / = works with acks
  //

#define POWERTOSSIM

  //
  // Constants.
  //

  // Which test to run.
  static uint8_t testId = 1;
  // Time in ms to wait before responding to a message.
  static uint8_t responseDelay = 0;
  // Time in ms to wait before sending a new message.
  static uint32_t sendDelay = 1000;
  // Max length of the debug buffer.
  static uint8_t maxBufLen = 255;

  //
  // Fixed variables.
  //

  // The number of senders (defaults to 1).
  uint8_t senderCount = 1;
  // Whether we will be a sender.
  bool doSend = FALSE;
  // Whether we will be responding.
  bool doRespond = FALSE;

  //
  // State variables.
  //

  // Are we currently sending a packet? (Means the radio is busy;
  // overwriting it at this point could screw up CC2420RadioM.)
  bool isSending = FALSE;
  // Is the send we're about to do a response to a received packet?
  bool isResponding = FALSE;
  // The actual message buffer we're using for sending and receiving data.
  TOS_Msg msg;

  // Convenience function for outputting debug information
  void pp(const char *fmt, ...) {
#ifndef POWERTOSSIM
    va_list argp;
    char str[maxBufLen];
    char timeStr[128];

    va_start(argp, fmt);
    vsnprintf(str, maxBufLen, fmt, argp);
    va_end(argp);

    printTime(timeStr, 128);
    dbg(DBG_USR2, "TEST (%s): %s\n", timeStr, str);
#endif // POWERTOSSIM
  }

  // Convenience function for outputting debug information.
  void p(const char *str) {
    pp("%s", str);
  }

  result_t sendMsg(uint16_t addr) {
    if (!isSending) {
      p("sendMsg(): sending");
      isSending = TRUE;
      msg.length = 20;
      msg.addr = addr;
      msg.type = 0;
#ifdef POWERTOSSIM
      memcpy(msg.data, "happy", 6);
#else // POWERTOSSIM
      snprintf((char*) msg.data, 15, "%x > %x",
          TOS_LOCAL_ADDRESS, addr);
#endif // POWERTOSSIM
      return call Send.send(&msg);
    }
    p("sendMsg(): couldn't send message");
    return FAIL;
  }

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    p("StdControl.init()");
    switch (testId) {
      case 3:
      case 4:
      case 6:
        senderCount = 2;
        break;
    }
    switch (testId) {
      case 5:
        doRespond = TOS_LOCAL_ADDRESS == 1;
        break;
      case 7:
        doRespond = TOS_LOCAL_ADDRESS >= senderCount;
        break;
    }
    return SUCCESS;
  }

  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    // Start a repeating timer that fires every 1000ms
    p("StdControl.start(): starting timer");
    call MacControl.enableAck();

    doSend = TOS_LOCAL_ADDRESS < senderCount ? TRUE : FALSE;
    switch (testId) {
      case 0:
        doSend = FALSE;
        break;
      case 8:
        doSend = TRUE;
        break;
    }

    if (doSend) {
      return call SendTimer.start(TIMER_REPEAT, sendDelay);
    }

    return SUCCESS;
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    result_t result = SUCCESS;
    p("StdControl.stop()");
    if (TOS_LOCAL_ADDRESS == 0) {
      result_t sendTimerResult = call SendTimer.stop();
      result_t responseTimerResult = call ResponseTimer.stop();
      result = rcombine(sendTimerResult, responseTimerResult);
    }
    return result;
  }

  /**
   * Send a message in response to the <code>SendTimer.fired</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t SendTimer.fired() {
    uint16_t addr = TOS_BCAST_ADDR;

    p("SendTimer.fired()");

//    if (isResponding) {
//      addr = 0;
//      switch (testId) {
//        case 9:
//        case 10:
//          addr = TOS_LOCAL_ADDRESS + 1;
//          break;
//      }
//      isResponding = FALSE;
//    } else {
      switch (testId) {
        case 1:
        case 5:
          addr = 1;
          break;
        case 3:
          addr = 2;
          break;
        case 6:
          addr = TOS_LOCAL_ADDRESS == 0 ? 1 : 0;
          break;
        case 8:
          addr = TOS_LOCAL_ADDRESS == 0 ? TOS_BCAST_ADDR : 0;
          break;
//      }
    }

    return sendMsg(addr);
  }

  event result_t ResponseTimer.fired() {
    uint16_t addr = 0;
    p("ResponseTimer.fired()");
    switch (testId) {
      case 9:
      case 10:
        addr = TOS_LOCAL_ADDRESS + 1;
        break;
    }
    isResponding = FALSE;

    return sendMsg(addr);
  }

  event TOS_MsgPtr Receive.receive(TOS_MsgPtr rcvMsg) {
    pp("Receive.receive(): '%s'", (char*) rcvMsg->data);
    call Leds.redToggle();

    if (doRespond) {
      isResponding = TRUE;
      call ResponseTimer.start(TIMER_ONE_SHOT, responseDelay);
    }

    return rcvMsg;
  }

  event result_t Send.sendDone(TOS_MsgPtr doneMsg, result_t success) {
    pp("Send.sendDone(): %s", success ? "succeeded" : "failed");
    isSending = FALSE;
    return SUCCESS;
  }
}


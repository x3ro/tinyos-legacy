// $Id: HFSM.nc,v 1.3 2003/10/07 21:44:50 idgay Exp $

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
/**
 * Perform sampling in response to outside request
 */
module HFSM {
  provides {
    interface StdControl;
  }
  uses {
    interface Sampling;
    interface SendMsg;
    interface ReceiveMsg;
    interface AllocationReq;
    //interface ReadData;
    interface Leds;
  }
}
implementation {
  // green: ready, red: error, yellow: sampling
  bool ready;
  TOS_Msg msg;
  uint32_t dataEnd;
  struct SampleRequestMsg o;	/* outside sampling orders */

  void setReady() {
    ready = TRUE;
    call Leds.greenOn();
  }

  void notReady() {
    ready = FALSE;
    call Leds.greenOff();
  }

  command result_t StdControl.init() {
    call AllocationReq.request(MAX_SAMPLES * sizeof(sample_t));
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event result_t AllocationReq.requestProcessed(result_t success) {
    // Allocation must succeed
    if (success)
      setReady();
    return SUCCESS;
  }

  task void doSampling();

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    o = *(struct SampleRequestMsg *)m->data;
    post doSampling();
    return m;
  }

  void sendMsg(uint8_t outcome) {
    struct SampleDoneMsg *m = (struct SampleDoneMsg *)msg.data;
    m->outcome = outcome;
    m->bytesUsed = dataEnd;
    call SendMsg.send(TOS_BCAST_ADDR, sizeof *m, &msg);
  }

  event result_t SendMsg.sendDone(TOS_MsgPtr m, result_t ok) {
    return SUCCESS;
  }

  // Report sampling completion
  void complete(uint8_t outcome) {
    setReady();
    if (outcome == SAMPLE_FAILED)
      call Leds.redOn();
    sendMsg(outcome);
  }

  task void doSampling() {
    if (!ready)
      sendMsg(SAMPLE_NOTREADY);

    call Leds.redOff();
    notReady();

    if (o.sampleCount > MAX_SAMPLES ||
	!call Sampling.prepare(o.sampleInterval, o.sampleCount))
      complete(SAMPLE_FAILED);
  }

  event result_t Sampling.ready(result_t ok) {
    if (!ok || !call Sampling.start())
      complete(SAMPLE_FAILED);
    else
      call Leds.yellowOn();
    return SUCCESS;
  }

  event result_t Sampling.done(result_t ok, uint32_t lastOffset) {
    dataEnd = lastOffset;
    call Leds.yellowToggle();
    complete(ok ? SAMPLE_SUCCESS : SAMPLE_FAILED);
    return SUCCESS;
  }
}

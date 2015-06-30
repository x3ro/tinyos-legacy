/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 * Authors:  David Gay  <dgay@intel-research.net>
 *           Intel Research Berkeley Lab
 *
 */
/*
 * ident.c - simple people identifier application
 *	     each mote has a (programmable) ID which it broadcasts
 *	     continuously
 *
 * Authors: David Gay
 * History: created 12/6/01
 *          adaptive rate extension 12/14/01
 *	    port to nesC 7/16/02
 */

includes SimpleFP;
includes Identity;
includes IdentMsg;

/**
 * Broadcast an "identity" message at regular intervals. The interval is
 * adapted to the number of identity messages heard from other motes (to
 * avoid overuse of radio bandwidth). The identity message includes the
 * current interval. Users of this component must provide an Identity.h
 * file which defines the identity_t type which will be included in 
 * identity messages (see IdentMsg.h)
 */

module IdentC
{
  provides {
    interface StdControl;
    interface Ident;
  }
  uses {
    interface Leds;
    interface Timer;
    interface SendMsg as SendIdMsg;
    interface ReceiveMsg as ReceiveIdMsg;
    interface Range;
  }
}
implementation
{
  enum {
    /* Clock frequency (1 per second) */
    TIMER_INTERVAL = 1000,

    /* All values below are in x.8 fixed point */

    /* Minimum and maximum identity message intervals */
    MINIMUM_IDENTITY_PERIOD = 10 * FP_SCALE,
    MAXIMUM_IDENTITY_PERIOD = 60 * FP_SCALE,

    /* Exponential decay (factor per second) */
    MSG_DECAY_RATE = (int)(0.97 * FP_SCALE),

    /* Multiplicative interval increase (aka frequency decrease) */
    PERIOD_ADJUST_RATE = (int)(1.25 * FP_SCALE),

    /* Additive frequency increase */
    FREQUENCY_INCREASE = (int)(.012 * FP_SCALE),

    /* Maximum total rate (from this and heard motes) of id messages per 
       second */
    MAX_IDMSG_RATE = 1 * FP_SCALE,

    /* Minimum total rate (interval decreases when rate below this) */
    MIN_IDMSG_RATE = (int)(0.5 * FP_SCALE)
  };

  bool pending1;
  TOS_Msg msg1;			/* The identity is saved in here */

  bool haveIdentity;

  uint8_t seconds;
  uint8_t messageCount; /* In the last second */
  FPType scaledMsgRate; 
  FPType broadcastPeriod; 
  uint16_t seqno;
  uint16_t vcc;
  uint8_t pot;

  static void clearIdentity() {
    call Timer.stop();
    haveIdentity = FALSE;
  }

  static void setIdentity(identity_t *newid) {
    struct IdentMsg *m = (struct IdentMsg *)msg1.data;

    m->identity = *newid;
    haveIdentity = TRUE;

    /* We reset these variables because we stop keeping track of
       message rates while we have no id */
    seconds = 0;
    messageCount = 0;
    call Timer.stop();
    call Timer.start(TIMER_REPEAT, TIMER_INTERVAL);
  }

  command bool Ident.haveIdentity() {
    return haveIdentity;
  }

  command result_t StdControl.init() {
    call Range.set(RANGE_6FT);

    seqno = 0;

    call Leds.yellowOff();

    clearIdentity();
  
    pending1 = FALSE;
    broadcastPeriod = MINIMUM_IDENTITY_PERIOD;
    scaledMsgRate = fpDiv(fpDiv(intToFp(1), MINIMUM_IDENTITY_PERIOD),
			  intToFp(1) - MSG_DECAY_RATE);

    return SUCCESS;
  }

  command result_t StdControl.start() {
    if (haveIdentity)
      call Timer.start(TIMER_REPEAT, TIMER_INTERVAL);
    return SUCCESS;
  }
    
  command result_t StdControl.stop() {
    return call Timer.stop();
  }
  
  command result_t Ident.clearId() {
    clearIdentity();
    return SUCCESS;
  }

  command result_t Ident.setId(identity_t *id) {
    setIdentity(id);
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveIdMsg.receive(TOS_MsgPtr m) {
    call Leds.yellowToggle();
    messageCount++;
    return m;
  }

  /* All this stuff should worry about overflow */

  /* Update current message rate to reflect exponential decay and 
     messages received in the last second */
  static void updateMsgRate() {
    scaledMsgRate = fpMul(scaledMsgRate, MSG_DECAY_RATE) +
      intToFp(messageCount);
    messageCount = 0;
  }

  /* Adjust the broadcast period based on the current message rate */
  static void adaptBroadcastPeriod() {
    FPType newperiod = broadcastPeriod;
    FPType msgRate = fpMul(scaledMsgRate, intToFp(1) - MSG_DECAY_RATE);

    if (msgRate > MAX_IDMSG_RATE) /* multiplicative frequency decrease */
      newperiod = fpMul(newperiod, PERIOD_ADJUST_RATE);
    else if (msgRate < MIN_IDMSG_RATE)
      // additive frequency increase
      newperiod = fpDiv(newperiod, intToFp(1) + fpMul(FREQUENCY_INCREASE, newperiod));

    if (newperiod < MINIMUM_IDENTITY_PERIOD)
      broadcastPeriod = MINIMUM_IDENTITY_PERIOD;
    else if (newperiod > MAXIMUM_IDENTITY_PERIOD)
      broadcastPeriod = MAXIMUM_IDENTITY_PERIOD;
    else
      broadcastPeriod = newperiod;
  }

  event result_t Timer.fired() {
    updateMsgRate();

    if (intToFp(++seconds) < broadcastPeriod)
      return SUCCESS;

    adaptBroadcastPeriod();

    seconds = 0;

    /* Send identity */
    if (haveIdentity && !pending1)
      {
	struct IdentMsg *m = (struct IdentMsg *)msg1.data;

	m->seqno = seqno++;
	m->broadcastPeriod = broadcastPeriod;
	m->msgRate = scaledMsgRate;

	if (call SendIdMsg.send(TOS_BCAST_ADDR, sizeof(struct IdentMsg), &msg1))
	  {
	    messageCount++; /* This message counts too! */
	    call Leds.greenToggle();
	    pending1 = TRUE;
	  }
      }
    return SUCCESS;
  }

  event result_t SendIdMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    if (pending1 && msg == &msg1) 
      pending1 = FALSE;
    return SUCCESS;
  }
}

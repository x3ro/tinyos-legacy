// $Id: DigitalIOM.nc,v 1.1.1.1 2007/11/05 19:10:02 jpolastre Exp $

/*									tab:4
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Access to the digital I/O facilities of the PCF8574APWR used
 * on the mda300ca board. 
 *
 * @author David Gay <dgay@intel-research.net>
 */
module DigitalIOM {
  provides {
    interface DigitalIO;
    interface StdControl;
  }
  uses {
    interface I2CPacket;
    interface Completion as I2CComplete;
  }
}
implementation {
  /* Each state which represents an I2C operation uses two values:
       S_xxx: operation not yet initiated
       S_xxx + 1: operation initiated
     This scheme supports automatic retries of I2C operations that failed
     because the I2C component was busy.

     The XXn values are just placeholders to make it simpler to define the
     S_xxx constants.
  */
  enum {
    S_IDLE, 
    S_SET, XX1,
    S_GET, XX2
  };
  uint8_t state;
  char i2cdata; /* 1-byte I2C packet contents */

  command result_t StdControl.init() {
    /* Configure "our" INT0 (atmega128 INT4) as falling-edge interrupt.
       This means we will get a single interrupt when the PCF8574APWR
       drives its interrupt line low in response to an input change.
    */
    TOSH_MAKE_INT0_INPUT();
    sbi(EICRB, 1); // falling-edge mode
    cbi(EICRB, 0);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /* (Re)try any uninitiated I2C packet operation (see discussion of
     state value encoding above) */
  result_t i2cretry() {
    result_t ok = FAIL;

    switch (state)
      {
      case S_SET: ok = call I2CPacket.writePacket(1, &i2cdata, 0x03); break;
      case S_GET: ok = call I2CPacket.readPacket(1, 0x03); break;
      default: break;
      }
    if (ok)
      state++; /* switch to "op initiated" state */

    return SUCCESS;
  }

  command result_t DigitalIO.get() {
    if (state != S_IDLE)
      return FAIL;
    state = S_GET;
    return i2cretry();
  }

  command result_t DigitalIO.set(uint8_t port) {
    if (state != S_IDLE)
      return FAIL;
    i2cdata = port;
    state = S_SET;
    return i2cretry();
  }

  /* If true, the change task has been posted (and not cancelled by
     calling enable(FALSE)). Used to avoid duplicate task postings. */
  bool changePosted;

  command result_t DigitalIO.enable(bool detectChange) {
    if (detectChange)
      sbi(EIMSK, 4);
    else
      {
	cbi(EIMSK, 4);
	/* Cancel any pending change event */
	atomic changePosted = FALSE;
      }
    return SUCCESS;
  }
  

  task void changeTask() {
    bool notCancelled;

    atomic
      {
	/* enable may cancel the event */
	notCancelled = changePosted;
	changePosted = FALSE;
      }
    if (notCancelled)
      signal DigitalIO.change();
  }

  TOSH_SIGNAL(SIG_INTERRUPT4) {
    atomic
      if (!changePosted)
	{
	  changePosted = TRUE;
	  post changeTask();
	}
  }

  event result_t I2CPacket.readPacketDone(char length, char* data) {
    state = S_IDLE;
    return signal DigitalIO.getDone(data[0], length == 1);
  }

  event result_t I2CPacket.writePacketDone(bool result) {
    state = S_IDLE;
    return signal DigitalIO.setDone(result);
  }

  event result_t I2CComplete.done() {
    return i2cretry(); // retry any outstanding i2c op
  }
}

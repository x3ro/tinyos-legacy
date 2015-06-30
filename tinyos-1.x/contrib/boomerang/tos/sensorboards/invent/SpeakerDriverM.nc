// $Id: SpeakerDriverM.nc,v 1.1.1.1 2007/11/05 19:11:36 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Speaker.h"

/**
 * Implementation of the speaker driver, and associated automatic
 * shutdown logic.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module SpeakerDriverM
{
  provides {
    interface SplitControl;
    interface PowerControl;
    interface PowerKeepAlive;
    interface Speaker;
  }
  uses {
    interface StdControl as AD524XControl;
    interface StdControl as DACControl;
    interface AD524X;
    interface TimerExclusive;
    interface MSP430DAC as DAC;
    interface MSP430DMA as DMA;
    interface MSP430DMAControl as DMAControl;
    interface Timer2<TMilli> as TimerKeepAlive;
    interface Timer2<TMilli> as TimerDelay;
    interface ResourceCmdAsync as Resource;
  }
}

implementation
{

  enum {
    OFF = 0,
    IDLE,
    START,
    START_2,
    START_KA,
    STOP,
    READY,
    INUSE,
  };

  norace uint8_t state;

  void* buf;
  uint16_t length;
  uint16_t freq;
  norace uint8_t rh; // resource handle

  enum {
    FLAGS_REPEAT =      0x01,
    FLAGS_WORD =        0x02,
    FLAGS_DACON =       0x04,
    FLAGS_SPKON =       0x08,
    FLAGS_SPKONALWAYS = 0x10,
    FLAGS_KAPENDING   = 0x20,
    FLAGS_KASTART =     0x40,
    FLAGS_SIGNAL_DONE = 0x80,
  };

  norace uint8_t f; // all bit operations are atomic by virtue of being bit ops

  void releaseResources();
  void startOutput();
  result_t prepareDAC();
  result_t checkSpeakerPower();


  // module control

  task void initDone() {
    signal SplitControl.initDone();
  }

  void speakerStartFail() {
    void* _buf;
    uint16_t _length;
    f &= ~FLAGS_DACON; // bit operation, compiles to 1 instruction
    f &= ~FLAGS_SPKON; // bit operation, compiles to 1 instruction
    _buf = buf;
    _length = length;
    state = READY;
    atomic {
      call Resource.release();
      rh = RESOURCE_NONE;
    }
    signal Speaker.started(_buf, _length, FAIL);
  }

  command result_t SplitControl.init() {
    atomic {
      // state is off
      state = OFF;
      f = 0;
    }
    call DACControl.init();
    // setup DMA
    call DMAControl.init();
    call DMAControl.setFlags(FALSE,FALSE,FALSE);
    // setup digital pot
    call AD524XControl.init();
    return post initDone();
  }

  task void startDone() {
    signal SplitControl.startDone();
  }

  command result_t SplitControl.start() {
    uint8_t _state = OFF;
    atomic {
      if (state == OFF) {
	state = READY;
	_state = state;
      }
    }
    if (_state == READY) {
      call DACControl.start();
      call AD524XControl.start();
      return post startDone();
    }
    return FAIL;
  }


  // power control

  bool testSignalDone() {
    atomic {
      if( f & FLAGS_SIGNAL_DONE ) {
        f &= ~FLAGS_SIGNAL_DONE;
        return TRUE;
      }
      return FALSE;
    }
  }

  void powerStartDone() {
    if( testSignalDone() )
      signal PowerControl.started();
  }

  void powerStopDone() {
    if( testSignalDone() )
      signal PowerControl.stopped();
  }

  task void keepAliveTask() {
    f &= ~FLAGS_KAPENDING; //atomic operation
    call TimerKeepAlive.startOneShot( SPEAKER_TIMEOUT );
    powerStartDone();
  }

  task void keepAliveStartTask() {
    if( state == START_KA ) {
      if( call AD524X.setOutput( SPEAKER_ON_ADDR, SPEAKER_ON_OUTPUT, TRUE, SPEAKER_ON_TYPE ) != SUCCESS ) {
	post keepAliveStartTask();
      }
      else {
	atomic {
	  state = START;
	  f |= FLAGS_KASTART;
	}
      }
    }
  }

  result_t powerStart( bool signalDone ) {
    result_t success = FAIL;

    if( f & FLAGS_SPKON ) {
      // keep the speaker from shutting down
      f |= FLAGS_KAPENDING;
      post keepAliveTask();
      success = SUCCESS;
    }
    else if( state == READY ) {
      // try to start the speaker
      atomic state = START_KA;
      post keepAliveStartTask();
      success = SUCCESS;
    }

    if( (success == SUCCESS) && signalDone )
      f |= FLAGS_SIGNAL_DONE;

    return success;
  }

  result_t powerStop( bool signalDone ) {
    uint8_t _state = READY;
    atomic {
      if ((state == READY) && (f & FLAGS_DACON) && (!(f & FLAGS_KAPENDING))) {
	state = STOP;
	_state = STOP;
      }
    }
    if (_state == STOP) {
      signal PowerKeepAlive.shutdown();
      if (f & FLAGS_KAPENDING) {
	atomic state = READY;
      }
      else {
	if (!(call AD524X.setOutput(SPEAKER_ON_ADDR, SPEAKER_ON_OUTPUT, FALSE, SPEAKER_ON_TYPE))) {
	  state = READY;
	  call TimerKeepAlive.startOneShot( SPEAKER_TIMEOUT );
	}
	else {
	  f &= ~FLAGS_SPKON;
          if( signalDone )
            f |= FLAGS_SIGNAL_DONE;
          return SUCCESS; //going to sleep
	}
      }
    }
    else {
      call TimerKeepAlive.startOneShot( SPEAKER_TIMEOUT );
    }

    return FAIL; //staying awake
  }

  bool isAlive() {
    return ((f & FLAGS_SPKON) == FLAGS_SPKON);
  }

  command result_t PowerControl.start() {
    return powerStart( TRUE ); // true means signal done
  }

  command result_t PowerControl.stop() {
    return powerStop( TRUE ); // true means signal done
  }

  async command bool PowerKeepAlive.isAlive() {
    return isAlive();
  }

  command result_t PowerKeepAlive.keepAlive() {
    return powerStart( FALSE ); // false means don't signal done
  }

  event void TimerKeepAlive.fired() {
    powerStop(FALSE);
  }


  // stuff

  event void AD524X.startDone(uint8_t _addr, result_t _result, ad524x_type_t type) {
  }

  command result_t SplitControl.stop() {
    return FAIL;
  }

  event void AD524X.stopDone(uint8_t addr, result_t result, ad524x_type_t type) {
  }

  event void TimerDelay.fired() {
    if( state == START_2 ) {
      if (f & FLAGS_KASTART) {
	atomic {
	  state = READY;
	  f &= ~FLAGS_KASTART;
	}
        powerStartDone();
      }
      else {
	startOutput();
      }
    }
    else if( state == STOP ) {
      f &= ~FLAGS_DACON;
      call DAC.disableOutput();
      if (call DAC.disable() != SUCCESS) {
	// try again in 100ms
	call TimerDelay.startOneShot( 100 );
      }
      else {
        powerStopDone();
      }
    }
  }

  event void AD524X.setOutputDone(uint8_t _addr, bool _output, result_t _result, ad524x_type_t _type) { 
    uint8_t _state = OFF;
    atomic {
      _state = state;
      if( state == START )
	state = START_2;
    }
    if (_state == START) {
      f |= FLAGS_SPKON; // bit operation, compiles to 1 instruction
      call TimerDelay.startOneShot( SPEAKER_WARMUP );
    }
    else if (_state == STOP) {
      call TimerDelay.startOneShot( SPEAKER_WARMUP );
    }
  }


  event void DAC.disableDone(result_t success) { 
    if (state == STOP) {
      state = READY;
    }
  }

  event void AD524X.setPotDone(uint8_t _addr, bool _rdac, result_t _result, ad524x_type_t _type) { 
  }

  event void AD524X.getPotDone(uint8_t addr, bool rdac, uint8_t value, result_t result, ad524x_type_t type) { }

  /************* SPEAKER INTERFACE **************/

  command result_t Speaker.start(void* _addr, uint16_t _length, bool _word, uint16_t _freq, bool _repeat) {
    uint8_t _state;
    uint8_t _rh;

    atomic {
      _state = IDLE;
      if (state == READY) {
	state = INUSE;
	_state = READY;
	buf = _addr;
	length = _length;
	freq = _freq;

	if (_repeat)
	  f |= FLAGS_REPEAT;
	else
	  f &= ~FLAGS_REPEAT;

	if (_word)
	  f |= FLAGS_WORD;
	else
	  f &= ~FLAGS_WORD;
      }
    }

    // are we in use?
    if (_state != READY)
      return FAIL;

    // get TimerA, we'll need it.
    atomic {
      if (rh == RESOURCE_NONE) {
	rh = call Resource.immediateRequest( RESOURCE_NONE );
      }
      _rh = rh;
    }

    if (_rh != RESOURCE_NONE) {
      return prepareDAC();
    }

    return FAIL;
  }

  result_t prepareDAC() {
    // stop the timer before anything happens
    call TimerExclusive.stopTimer(rh);
    
    // set Timer params
    call TimerExclusive.prepareTimer(rh,
				     freq,
				     MSP430TIMER_SMCLK, 
				     MSP430TIMER_CLOCKDIV_1
				     );

    // bind settings
    call DAC.bind(DAC12_REF_VREF,
		  f & FLAGS_WORD ? DAC12_RES_12BIT : DAC12_RES_8BIT,  /* 0 = 12bit, 1 = 8bit   */
		  DAC12_LOAD_TAOUT1, /* load on TimerA output */
		  DAC12_FSOUT_1X,
		  DAC12_AMP_HIGH_HIGH,
		  DAC12_DF_STRAIGHT,
		  DAC12_GROUP_OFF);
    
    // enable the DAC and wait for it to start
    if (!(f & FLAGS_DACON)) {
      if (call DAC.enable() == SUCCESS) {
	return SUCCESS;
      }
      else {
	atomic {
	  call Resource.release();
	  rh = RESOURCE_NONE;
	}
	atomic state = READY;
	return FAIL;
      }
    }
    else {
      // stop the timeout
      call TimerKeepAlive.stop();
      return checkSpeakerPower();
    }
    return FAIL;
  }

  // after the DAC starts...
  event void DAC.enableDone(result_t success) {
    // put the first byte into the DAC0 DATA register
    atomic {
      if (success) {
	f |= FLAGS_DACON;
      }
    }

    if ((success != SUCCESS) || (checkSpeakerPower() != SUCCESS)) {
      speakerStartFail();
    }
  }

  result_t checkSpeakerPower() {
    call DAC.enableOutput();

    if (f & FLAGS_WORD) {
      call DAC.set(((uint16_t*)buf)[0]);
    }
    else {
      call DAC.set(((uint8_t*)buf)[0]);
    }

    if (!(f & FLAGS_SPKON)) {
      if (call AD524X.setOutput(SPEAKER_ON_ADDR, SPEAKER_ON_OUTPUT, TRUE, SPEAKER_ON_TYPE) != SUCCESS) {
	atomic {
	  call Resource.release();
	  rh = RESOURCE_NONE;
	}
	return FAIL;
      }
      else {
	atomic state = START;
	return SUCCESS;
      }
    }
    else {
      // enable TimerA, set DMA, and go.
      startOutput();
      return SUCCESS;
    }
  }



  async command result_t Speaker.stop() {
    atomic {
      if (state == INUSE) {
        call DMA.stopTransfer();
        releaseResources();
        state = READY;
        return SUCCESS;
      }
      return FAIL;
    }
  }

  task void startTimeoutTimer() {
    call TimerKeepAlive.startOneShot( SPEAKER_TIMEOUT );
  }

  void releaseResources() {
    // release the timer
    call TimerExclusive.stopTimer(rh);
    atomic {
      call Resource.release();
      rh = RESOURCE_NONE;
    }
    // kill the output
    call DAC.disableOutput();
    // start the timeout
    post startTimeoutTimer();
  }

  void startOutput() {
    call DMA.setupTransfer( f & FLAGS_REPEAT ? DMA_REPEATED_SINGLE_TRANSFER : DMA_SINGLE_TRANSFER, 
		    DMA_TRIGGER_DAC12IFG, /* Trigger on DAC12 DAC0 */
		    DMA_EDGE_SENSITIVE, 
		    buf,                     /* Source */
		    (void *)DAC12_0DAT_,     /* Destination */
		    length,
		    f & FLAGS_WORD ? DAC12_RES_12BIT : DAC12_RES_8BIT,  /* 0 = 12bit, 1 = 8bit   */
		    f & FLAGS_WORD ? DAC12_RES_12BIT : DAC12_RES_8BIT,  /* 0 = 12bit, 1 = 8bit   */
		    DMA_ADDRESS_INCREMENTED, /* Source Increment */
		    DMA_ADDRESS_UNCHANGED    /* Dest Increment */
                    );
 
    call DMA.startTransfer();

    // start TimerA running
    call TimerExclusive.startTimer(rh);

    signal Speaker.started(buf, length, SUCCESS);
  }

  async event void DMA.transferDone(result_t s){
    void* _buf;
    uint16_t _length;
    bool _repeat;

    atomic {

      _repeat = f & FLAGS_REPEAT;

      if (_repeat) {
	//call DMA.startTransfer();
      }
      else {
	_buf = buf;
	_length = length;
	state = READY;
      }
      
    }

    if (_repeat) {
      //signal Speaker.repeat(_buf, _length);
    }
    // otherwise we're done with this sample
    else {
      releaseResources();
      signal Speaker.done(_buf, _length, _repeat);
    }
  }

  async event void Resource.granted( uint8_t _rh ) {
  }

  default event void Speaker.started(void* _addr, uint16_t _length, result_t success) { }
  default async event void Speaker.done(void* _addr, uint16_t _length, bool _repeat) { }
  default async event void Speaker.repeat(void* _addr, uint16_t _length) { }

  default event void PowerControl.started() { }
  default event void PowerControl.stopped() { }
  default event void PowerKeepAlive.shutdown() { }

}


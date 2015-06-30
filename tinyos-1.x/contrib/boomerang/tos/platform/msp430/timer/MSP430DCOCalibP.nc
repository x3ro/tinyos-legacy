//$Id: MSP430DCOCalibP.nc,v 1.1.1.1 2007/11/05 19:11:33 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * @author Cory Sharp <info@moteiv.com>
 */

module MSP430DCOCalibP {
  uses interface ResourceCmd as ResourceTimerA;
  uses interface MSP430Timer as TimerA;
  uses interface MSP430Timer as TimerB;
  uses interface MSP430Compare as TimerCompareB;
  uses interface MSP430TimerControl as TimerControlB;
}
implementation {

  enum {
    MEASURE_DELTA_RTC = 12, // number of ticks of the 32khz clock to measure
    TARGET_DELTA_SMCLK = 384, // number of SMCLK ticks that should occur during MEASURE_DELTA_RTC
    MAX_SMCLK_DEVIATION = 2, // about 0.5% error
  };


  async event void TimerA.overflow() {
  }


  async event void TimerB.overflow() {
    call ResourceTimerA.deferRequest();
  }

  async event void TimerCompareB.fired() {
  }

  uint16_t get_delta_dco() {
    uint16_t t0_dco;
    uint16_t t1_dco;

    call TimerControlB.disableEvents();

    call TimerCompareB.setEventFromNow(2);
    call TimerControlB.clearPendingInterrupt();
    while( !call TimerControlB.isInterruptPending() );
    t0_dco = call TimerA.get();

    call TimerCompareB.setEventFromPrev(MEASURE_DELTA_RTC);
    call TimerControlB.clearPendingInterrupt();
    while( !call TimerControlB.isInterruptPending() );
    t1_dco = call TimerA.get();

    return t1_dco - t0_dco;
  }


  void step_dco( uint16_t td_dco ) {
    if( td_dco > (TARGET_DELTA_SMCLK+MAX_SMCLK_DEVIATION) ) {
      // too many DCO ticks, slow it down
      if( DCOCTL > 0 ) {
        DCOCTL--;
      }
      else if( (BCSCTL1 & 7) > 0 ) {
        // a large step, sorry
        BCSCTL1--;
        DCOCTL = 128;
      }
    }
    else if( td_dco < (TARGET_DELTA_SMCLK-MAX_SMCLK_DEVIATION) ) {
      // too few DCO ticks, speed it up
      if( DCOCTL < 0xe0 ) {
        DCOCTL++;
      }
      else if( (BCSCTL1 & 7) < 7 ) {
        // a large step, sorry
        BCSCTL1++;
        DCOCTL = 96;
      }
    }
  }


  event void ResourceTimerA.granted( uint8_t rh ) {
    atomic {
      call TimerA.disableEvents();
      call TimerA.setClockSource( MSP430TIMER_SMCLK );
      call TimerA.setInputDivider( MSP430TIMER_CLOCKDIV_1 );
      call TimerA.setMode( MSP430TIMER_CONTINUOUS_MODE );

      step_dco( get_delta_dco() );
    }

    call ResourceTimerA.release();
  }
}


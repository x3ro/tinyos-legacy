//$Id: C55xxClockM.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

includes C55xxTimer;

module C55xxClockM
{
  provides interface StdControl;
  provides interface C55xxClockInit;
}
implementation
{

  volatile norace uint16_t m_dco_curr;
  volatile norace uint16_t m_dco_prev;
  volatile norace uint8_t m_aclk_count;

  enum
  {
    ACLK_CALIB_PERIOD = 128,
    ACLK_KHZ = 32,
    TARGET_DCO_KHZ = 4096, // prescribe the cpu clock rate in kHz
    TARGET_DCO_DELTA = (TARGET_DCO_KHZ / ACLK_KHZ) * ACLK_CALIB_PERIOD,
  };

  command void C55xxClockInit.defaultInitClocks()
  {
  }

  command void C55xxClockInit.defaultInitTimerA()
  {
  }
  
  command void C55xxClockInit.flagInitTimerA(uint16_t flag) {
  }
	  
  command void C55xxClockInit.defaultInitTimerB()
  {
  }

  default event void C55xxClockInit.initClocks()
  {
    call C55xxClockInit.defaultInitClocks();
  }

  default event void C55xxClockInit.initTimerA()
  {
    call C55xxClockInit.defaultInitTimerA();
  }

  default event void C55xxClockInit.initTimerB()
  {
    call C55xxClockInit.defaultInitTimerB();
  }


  command void C55xxClockInit.startTimerA()
  {
  }

  command void C55xxClockInit.stopTimerA()
  {
  }

  void startTimerB()
  {
  }

  void stopTimerB()
  {
  }


  void set_calib( int calib )
  {
  }

  void test_calib( int calib )
  {
  }

  uint16_t busywait_delta()
  {
    while( m_aclk_count != 0 ) { }
    return m_dco_curr - m_dco_prev;
  }

  uint16_t test_calib_busywait_delta( int calib )
  {
    test_calib( calib );
    return busywait_delta();
  }

  // busyCalibrateDCO: DESTRUCTIVE TO ALL TIMERS
  void busyCalibrateDCO()
  {
  }

  void garnishedBusyCalibrateDCO()
  {
    bool do_dint;
    do_dint = !are_interrupts_enabled();
    eint();
    busyCalibrateDCO();
    if(do_dint)
      dint();
  }
    
  command result_t StdControl.init()
  {
    atomic
    {
      signal C55xxClockInit.initClocks();
      signal C55xxClockInit.initTimerA();
      signal C55xxClockInit.initTimerB();
    }

    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    atomic
    {
      call C55xxClockInit.startTimerA();
      startTimerB();
    }
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    atomic
    {
      stopTimerB();
      call C55xxClockInit.stopTimerA();
    }
    return SUCCESS;
  }
}


/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
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
 */
/*
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 * Authors:		Lin Gu (Modify it to be general ACD reader)
 * Date last modified:  6/25/03
 *
 */
includes sensorboard;

module AdcMirToInt {
  provides {
    interface StdControl;
  }
  uses {
    //    interface Clock;
    interface ADC;
    interface StdControl as ADCControl;
    interface StdControl as TimerControl;
    interface IntOutput;
    interface Peek;
    interface Timer as AdcMirTimer;
    interface Snooze;
    interface StdControl as Sounder;
  }
}
implementation {

#define USE_SOUNDERno
#define USE_SOUNDER_LONG
#define USE_SOUNDER_SHORTno

#define MIRR_READ_INTERVAL 16
#define MIRR_WARMUP (22000L / MIRR_READ_INTERVAL)
#define MIRR_START 25000L
#define MIRR_STABLIZE (MIRR_START / MIRR_READ_INTERVAL)
#define MIRR_DETECT_MIR (9000/MIRR_READ_INTERVAL)
#define MIRR_DETECT_MIR_STOP (MIRR_DETECT_MIR + 120)
#define MIRR_DETECT_MIR_PRELUDE (8000/MIRR_READ_INTERVAL)
#define MIRR_DETECT_MIR_PRELUDE_END (8256/MIRR_READ_INTERVAL)
#define MIRR_SNOOZE (5800000L/MIRR_READ_INTERVAL)
#define MIRR_SNOOZE_END (6800000L/MIRR_READ_INTERVAL)
#define MIRR_READING_SHIFT 2
#define MIRR_DEFAULT_MIR_MIDDLE 0x3d

#define INDOORno

#ifdef INDOOR

#define MIRR_UPPER_THRESHOLD 101
#define MIRR_LOWER_THRESHOLD 35
#define MIRR_REPEAT_THRESHOLD 3
#define MIRR_SHIFT_HEAD_MASK 0xffff0
#define SHIFT_START 0x80000
#define MIRR_ALARM_SOUND_LENGTH 8

#else

#define MIRR_UPPER_OFFSET 21
#define MIRR_UPPER_THRESHOLD (cMirMiddle + MIRR_UPPER_OFFSET)
#define MIRR_LOWER_OFFSET 25
#define MIRR_LOWER_THRESHOLD (cMirMiddle - MIRR_LOWER_OFFSET)
#define MIRR_REPEAT_THRESHOLD 5
#define SHIFT_START 0x8000000
#define MIRR_SHIFT_HEAD_MASK 0xff00000
#define MIRR_ALARM_SOUND_LENGTH 5

#endif

  long lTick, lTick2, lPrematureRead, lAccumMir;
  uint16_t nCount;
  unsigned long lShift;
  unsigned char cMirMiddle;

  command result_t StdControl.init() {
    lTick = lTick2 = lPrematureRead = lAccumMir = 0;
    lShift = nCount = 0;
    cMirMiddle = 0;

    call ADCControl.init();
    call TimerControl.init();
    // call Sounder.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call ADCControl.start();
    TOSH_CLR_RED_LED_PIN();
    // return call Clock.setRate(TOS_I4PS, TOS_S4PS);
    // return call Clock.setRate(TOS_I32PS, TOS_S32PS);
    return call AdcMirTimer.start(TIMER_REPEAT, MIRR_READ_INTERVAL);

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call ADCControl.stop();
    //    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
    return call AdcMirTimer.stop();
  }

  task void retrieveData()
    {
      call ADC.getData();
    } // task retrieveData

  event result_t AdcMirTimer.fired() {
    if (lTick < MIRR_STABLIZE)
      { /////// ??? // need to consider snooze in net disabling and here
	lTick++;
	dbg(DBG_USR1, "lTick: %ld\n", lTick);

	if (lTick & 0x40)
	  {
	    TOSH_SET_YELLOW_LED_PIN();
	  }
	else
	  {
	    TOSH_CLR_YELLOW_LED_PIN();
	  }

	if (lTick == MIRR_DETECT_MIR)
	  {
	    dbg(DBG_LED, "AdcMirToInt:Clock.fire: red led off, green on\n");
	    TOSH_SET_RED_LED_PIN();
	    // TOSH_CLR_GREEN_LED_PIN();
	    post retrieveData();
	  } // if lTick == MIRR_DETECT_MIR

	if (lTick == MIRR_DETECT_MIR_STOP)
	  {
	    TOSH_CLR_SOUNDER_CTL_PIN();
	  } // if lTick == MIRR_DETECT_MIR_STOP

	if (lTick == MIRR_DETECT_MIR_PRELUDE)
	  {
	    // TOSH_SET_SOUNDER_CTL_PIN();
	    call Sounder.start();
	    TOSH_CLR_GREEN_LED_PIN();
	  } // if lTick == MIRR_DETECT_MIR_PRELUDE

	if (lTick == MIRR_DETECT_MIR_PRELUDE_END)
	  {
	    TOSH_CLR_SOUNDER_CTL_PIN();
	  } // if lTick == MIRR_DETECT_MIR_PRELUDE_END
      
	if ((lTick >= MIRR_WARMUP) &&
	    (cMirMiddle == MIRR_DEFAULT_MIR_MIDDLE))
	  {
	    post retrieveData();
	  } // lTick >= MIRR_WARMUP
      }
    else
      {
	if (lTick == MIRR_STABLIZE)
	  {
	    lTick++;
	    post retrieveData();

	    if (!lTick2)
	      {
		lTick2 = lTick;
	      }
	  } // if (lTick == MIRR_STABLIZE)
	else
	  {
	    if (lPrematureRead <= 100)
	      {
	    lPrematureRead ++;
	      }
	  }

	if (lTick2)
	  {
	    lTick2 ++;
	if (lTick2 == MIRR_SNOOZE)
	  {
	    TOSH_CLR_YELLOW_LED_PIN();
	    TOSH_CLR_RED_LED_PIN();
	    TOSH_CLR_GREEN_LED_PIN();

	    // call Snooze.snooze(7*32);
	  }

	if (lTick2 == MIRR_SNOOZE_END)
	  {
	    TOSH_CLR_SOUNDER_CTL_PIN();
	    // TOSH_SET_YELLOW_LED_PIN();
	    // TOSH_SET_RED_LED_PIN();
	    // TOSH_SET_GREEN_LED_PIN();
	    // call Snooze.stopSnooze();
	  }
	  } // if (lTick2)
      } // else lTick < MIRR_STABLIZE

    return SUCCESS;
  }

  event result_t Snooze.wakeup()
    {
       TOSH_CLR_YELLOW_LED_PIN();
       TOSH_SET_RED_LED_PIN();
       TOSH_SET_GREEN_LED_PIN();
	    TOSH_CLR_SOUNDER_CTL_PIN();

	    // cli();
	    // for (;;){volatile int a; if (a) a=0;};

      return SUCCESS;
    }

  inline char isFrequent(uint16_t nData)
    {
      unsigned char data = (unsigned char)(nData >> 2);

      if (lShift & 0x1)
	{
	  nCount --;
	}

      lShift >>= 1;

      if (data >= 125)
	{
	  lShift |= SHIFT_START;
	  nCount++;
	}

      if (nCount > 3)
	{
	  return 1;
	} // if nCount > 3
      else
	{
	  return 0;
	} // else nCount > 3
    } // IsFrequent

  typedef enum
    {
      VOLTAGE_MEDIUM = 0,
      VOLTAGE_HIGH = 1,
      VOLTAGE_LOW = 2,
    } VoltageStatus;
      
  inline char isFast(uint16_t nData)
    {
      unsigned char data = (unsigned char)(nData >> 2);
      static VoltageStatus vs;

      if (lShift & 0x1)
	{
	  nCount --;
	}

      lShift >>= 1;

      if (data < MIRR_UPPER_THRESHOLD)
	{
	  vs = VOLTAGE_LOW;
	}

      if ((vs == VOLTAGE_LOW) && (data >= MIRR_UPPER_THRESHOLD))
	{
	  vs = VOLTAGE_HIGH;
	  nCount++;
	  lShift |= SHIFT_START;
	}

      if (nCount >=5 )
	{
	  return 1;
	} // if nCount >= 2
      else
	{
	  return 0;
	} // else nCount >= 2
    } // isFast

  inline char isActive(uint16_t nData)
    {
      unsigned char data = (unsigned char)(nData >> 2);
      static VoltageStatus vsActive;

      if (lShift & 0x1)
	{
	  nCount --;
	}

      lShift >>= 1;

      if (data <= MIRR_LOWER_THRESHOLD)
	{
	  if (vsActive != VOLTAGE_LOW)
	    {
	      vsActive = VOLTAGE_LOW;
	      nCount++;
	      lShift |= SHIFT_START;
	    }
	}
      else
	{
	  if(data >= MIRR_UPPER_THRESHOLD)
	    {
	      if (vsActive != VOLTAGE_HIGH)
		{
		  vsActive = VOLTAGE_HIGH;
		  nCount++;
		  lShift |= SHIFT_START;
		}
	    }
	  else
	    {
	      vsActive = VOLTAGE_MEDIUM;
	    } // else data >= MIRR_UPPER_THRESHOLD
	} // else data <= MIRR_LOWER_THRESHOLD

      if ((nCount > MIRR_REPEAT_THRESHOLD) && (lShift & MIRR_SHIFT_HEAD_MASK))
	{
	  return 1;
	} // if nCount > MIRR_REPEAT_THRESHOLD
      else
	{
	  return 0;
	} // else nCount > MIRR_REPEAT_THRESHOLD
    } // isActive

  event result_t ADC.dataReady(uint16_t data) {
    // return call IntOutput.output(data /*>> 7*/);

    char cStatus;

#ifdef USE_SOUNDER
    static char cPrevStatus;
    static int nSounderCnt;
#endif

    if (lTick < MIRR_STABLIZE)
      {
	dbg(DBG_LED, "AdcMirToInt:Clock.fire:  green led off\n");
	// TOSH_SET_GREEN_LED_PIN();

	if (lTick >= MIRR_WARMUP)
	  {
	    lAccumMir += data >> MIRR_READING_SHIFT;
	    
	    if (lTick >= MIRR_STABLIZE - 3)
	      {
		cMirMiddle = lAccumMir / (lTick - MIRR_WARMUP + 1);
		if (lTick == MIRR_STABLIZE - 1 && 
		    (cMirMiddle > MIRR_LOWER_OFFSET) &&
		    (cMirMiddle + MIRR_UPPER_OFFSET < 127))
		  {
		    call Peek.bcastInt2(cMirMiddle);
		    TOSH_CLR_SOUNDER_CTL_PIN();
		  }
	      } // if lTick >= MIRR_STABLIZE-3

	    if (lTick == MIRR_WARMUP)
	      {
		TOSH_SET_SOUNDER_CTL_PIN();
		TOSH_CLR_RED_LED_PIN();
	      } // lTick == MIRR_WARMUP
	  } // if (lTick >= MIRR_WARMUP)
	else
	  {
	    if (data)
	      {
		TOSH_SET_SOUNDER_CTL_PIN();
		cMirMiddle = MIRR_DEFAULT_MIR_MIDDLE;
	      } // if (data)
	    call Peek.bcastInt2(data);
	  } // else lTick >= MIRR_WARMUP


	return SUCCESS;
      } // if lTick < MIRR_STABLIZE

    // post retrieveData();
    // call Peek.lazyBcastInt2(data);
    if (lPrematureRead)
      {
	call Peek.lazyBcastChar((char)lPrematureRead);
      }
    else
      {
	call Peek.lazyBcastChar(data>>MIRR_READING_SHIFT);
      }

    // if (isFrequent(data))
    // if (isFast(data))
    if (cStatus = isActive(data))
      {
#ifdef USE_SOUNDER
	if (!cPrevStatus)
	  {
	    TOSH_SET_SOUNDER_CTL_PIN();
	    nSounderCnt = MIRR_ALARM_SOUND_LENGTH;
	  }
#endif
	TOSH_CLR_YELLOW_LED_PIN();
      }
    else
      {
#ifdef USE_SOUNDER_LONG
	TOSH_CLR_SOUNDER_CTL_PIN();
#endif
	TOSH_SET_YELLOW_LED_PIN();
      } // else cPrevStatus = isActive(data)

#ifdef USE_SOUNDER
#ifdef USE_SOUNDER_SHORT
    if (nSounderCnt>0)
      {
	/*if (nSounderCnt == MIRR_ALARM_SOUND_LENGTH)
	  {
	    call Peek.bcastInt2(data);
	    }*/

	nSounderCnt--;
      }
    else
      {
	if (!nSounderCnt)
	  {
	    nSounderCnt--;
	    TOSH_CLR_SOUNDER_CTL_PIN();
	  }
      } // else nSounderCnt>0
    
    cPrevStatus = cStatus;
#endif
#endif

    lTick--;

    return SUCCESS;
  }

  event result_t IntOutput.outputComplete(result_t success) {
    return SUCCESS;
  }
}


/*************************************************************
 * Authors:  Lin Gu
 * Date:     6/12/2003
 *
 * For Advantaca ISM-002-I Radar
 *************************************************************/

includes sensorboard;

module MIRM {
  provides {
    interface StdControl;
    interface Radar;
    interface RadarSwitch;
   }
  uses {
    interface ADC as UnderlyingADC;
    interface StdControl as ADCControl;
    interface StdControl as SubControl;
    interface Peek;
    interface Timer as AdcMirTimer;
    interface StdControl as TimerControl;
    interface Snooze;
    interface StdControl as Sounder;
  }
}

implementation {

#include "common.h"

#undef USE_SOUNDERno
#define USE_LEDno
#define USE_SOUNDER_LONG
#define USE_SOUNDER_SHORTno
#define DUMP_MIR_READING

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
#define MIRR_ALARM_DELAY 0x30
#define MIRR_ALARM_STOP_POINT 0x10

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
#define MIRR_REPEAT_THRESHOLD 4
#define SHIFT_START 0x8000000
#define MIRR_SHIFT_HEAD_MASK 0xff00000
#define MIRR_ALARM_SOUND_LENGTH 5

#endif

  long lTick, lTick2,/* lPrematureRead,*/ lAccumMir;
  uint16_t nCount;
  unsigned long lShift;
  unsigned char cMirMiddle, gcGo, gcSensorOk;
  int nDelay;
  
  // lock var
  char gcGeneralState;
  unsigned long dGoodMe;

  // pin assignment
  TOSH_ASSIGN_PIN(MIR_DIN,E,2);

  command result_t StdControl.init() {
    call ADCControl.init();
    // pin setting
    // //////// TOSH_MAKE_MIR_DIN_INPUT();

    lTick = lTick2 =/* lPrematureRead = */lAccumMir = 0;
    lShift = nCount = 0;
    cMirMiddle = 0;
    nDelay = 0;
    gcGo = 0;
    gcSensorOk = 0;

    // lock var
    gcGeneralState = 0;
    dGoodMe = 0;

    call ADCControl.init();
    call TimerControl.init();
    call SubControl.init();
    // call Sounder.init();

    dbg(DBG_BOOT, "MIRM: init\n");

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call ADCControl.start();

    // Start the motion sensor (MIR sensor) by asserting some pin signals
    /* TOSH_SET_PW0_PIN();
    TOSH_SET_PW1_PIN();
    TOSH_SET_PW4_PIN(); /////// */

    call ADCControl.start();
    TOSH_CLR_RED_LED_PIN();
    // return call Clock.setRate(TOS_I4PS, TOS_S4PS);
    // return call Clock.setRate(TOS_I32PS, TOS_S32PS);

    call SubControl.start();

    gcGo = 1;

    dbg(DBG_BOOT, "MIRM: start\n");

    return call AdcMirTimer.start(TIMER_REPEAT, MIRR_READ_INTERVAL);
  }

  command result_t StdControl.stop() {
    call ADCControl.stop();
    // Turn off the mica power board
    TOSH_CLR_PW0_PIN();
    TOSH_CLR_PW1_PIN();
    TOSH_CLR_PW4_PIN();

    call ADCControl.stop();
    //    return call Clock.setRate(TOS_I0PS, TOS_S0PS);
    call SubControl.stop();

    return call AdcMirTimer.stop();
  }

  /* Read the digital output from the port PE2.
     return value: 
       0: motion detected
       1: motion not detected */
  command uint16_t Radar.readBit() {
    return TOSH_READ_MIR_DIN_PIN();
  }

  command result_t RadarSwitch.pause() {
    gcGo = 0;
    
    return SUCCESS;
  }

  command result_t RadarSwitch.resume() {
    gcGo = 1;

    return SUCCESS;
  }

  command result_t Radar.getData() {
    call UnderlyingADC.getData();

    return SUCCESS;
  }

  task void retrieveData()
    {
      call UnderlyingADC.getData();
    } // task retrieveData

  event result_t AdcMirTimer.fired() {
    dbg(DBG_USR1, "MIRM: AdcMirTimer.fired\n");

    if (lTick < MIRR_STABLIZE)
      { /////// ??? // need to consider snooze in net disabling and here

	KNOCK(FAIL, 2);

	lTick++;
	// dbg(DBG_USR1, "lTick: %ld\n", lTick);

	if (lTick & 0x40)
	  {
	    dbg(DBG_USR1, "lTick: %ld, yellow off\n", lTick);
	    // call Peek.printInt2(0x9876);
	    TOSH_SET_YELLOW_LED_PIN();
	  }
	else
	  {
	    dbg(DBG_USR1, "lTick: %ld, yellow on\n", lTick);
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

	LEAVE;
      } // lTick < MIRR_STABLIZE
    else
      {
	if (!gcSensorOk)
	  {
	    return FAIL;
	  }

	KNOCK(FAIL, 1);

	if (lTick == MIRR_STABLIZE)
	  {
	    lTick++;
	    post retrieveData();

	    if (!lTick2)
	      {
		lTick2 = lTick;
	      }
	  } // if (lTick == MIRR_STABLIZE)
#ifdef nouse
	else
	  {
	    if (lPrematureRead <= 100)
	      {
		lPrematureRead ++;
	      }
	  }
#endif
	if (nDelay > 0)
	  {
	    nDelay--;
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

	LEAVE;
      } // else lTick < MIRR_STABLIZE

    return SUCCESS;
  }

  event result_t Snooze.wakeup()
    {
      /*       TOSH_CLR_YELLOW_LED_PIN();
       TOSH_SET_RED_LED_PIN();
       TOSH_SET_GREEN_LED_PIN();*/

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

  event result_t UnderlyingADC.dataReady(uint16_t data) {
    // return call IntOutput.output(data /*>> 7*/);
    static uint16_t nHighestRecent;

    char cStatus;
    uint16_t nScaledVal = data >> MIRR_READING_SHIFT;

#ifdef USE_SOUNDER
    static char cPrevStatus;
    static int nSounderCnt;
#endif

#ifdef PC_PLATFORM
    dbg(DBG_USR1, "MIRM:dataReady: got data from ADC\n");
    data = 0x99;
#endif

    if (lTick < MIRR_STABLIZE)
      {
	dbg(DBG_LED, "AdcMirToInt:Clock.fire:  green led off\n");
	// TOSH_SET_GREEN_LED_PIN();

	KNOCK(FAIL, 1);

	if (lTick >= MIRR_WARMUP)
	  {
	    lAccumMir += nScaledVal;
	    
	    if (lTick >= MIRR_STABLIZE - 3)
	      {
		cMirMiddle = lAccumMir / (lTick - MIRR_WARMUP + 1);
		if (lTick == MIRR_STABLIZE - 3 && 
		    (cMirMiddle > MIRR_LOWER_OFFSET) &&
		    (cMirMiddle + MIRR_UPPER_OFFSET < 127))
		  {
		    // call Peek.bcastInt2(cMirMiddle);
		    gcSensorOk = 1;
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
	    
	    // call Peek.bcastInt2(data);
	  } // else lTick >= MIRR_WARMUP


	LEAVE;

	return SUCCESS;
      } // if lTick < MIRR_STABLIZE

    KNOCK(FAIL, 1);

    if (nHighestRecent < nScaledVal)
      {
	nHighestRecent = nScaledVal;
      }
    else
      {
	nHighestRecent -= 2;
      }

#ifdef nouse
    // post retrieveData();
    // call Peek.lazyBcastInt2(data);
    if (lPrematureRead)
      {
	call Peek.lazyBcastChar((char)lPrematureRead);
      }
    else
      {
#endif

	if (!gcGo)
	  {
	    data = 0x3d << MIRR_READING_SHIFT;
	  }

#ifdef DUMP_MIR_READING
	call Peek.lazyBcastChar(data>>MIRR_READING_SHIFT);
#endif

#ifdef nouse
      }
#endif

    // if (isFrequent(data))
    // if (isFast(data))
    if (cStatus = isActive(data))
      {
	if (!nDelay)
	  {
	    // There has been a while of 'not active'
	    // TOSH_SET_YELLOW_LED_PIN();

	    nDelay = MIRR_ALARM_DELAY;
	    
	    signal Radar.alarm(nHighestRecent);
	  }

	if (nDelay > MIRR_ALARM_STOP_POINT)
	  {
	    nDelay = MIRR_ALARM_DELAY;
	  }

#ifdef USE_SOUNDER
	if (!cPrevStatus)
	  {
	    TOSH_SET_SOUNDER_CTL_PIN();
	    nSounderCnt = MIRR_ALARM_SOUND_LENGTH;
	  }
#endif

#ifdef USE_LED
	TOSH_CLR_YELLOW_LED_PIN();
#endif
      } // if cStatus = isActive
    else
      {
	if (nDelay == MIRR_ALARM_STOP_POINT)
	  {
	    signal Radar.alarm(0);
	  }

#ifdef USE_SOUNDER_LONG
	TOSH_CLR_SOUNDER_CTL_PIN();
#endif

#ifdef USE_LED
	TOSH_SET_YELLOW_LED_PIN();
#endif
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

    LEAVE;

    return SUCCESS;
  }
}


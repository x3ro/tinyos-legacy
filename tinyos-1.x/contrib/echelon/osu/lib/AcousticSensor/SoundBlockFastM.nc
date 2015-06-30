/*
  S o u n d B l o c k F a s t M . n c
  (c) Copyright 2004 The MITRE Corporation (MITRE)
*/

/*
  CONFIG:
    The sample period is the divisor times 1.875 microseconds.

    Log2Divisor    Period       Rate
    ----------  ----------    ----------
	0         1.875 us     533    KHz
	1         3.75  us     266    KHz
	2         7.5   us     133    KHz
	3        15     us      66.6  KHz
	4        30     us      33.3  KHz
	5        60     us      16.6  KHz <== Default on Mica2
	6       120     us       8.33 KHz
	7       240     us       4.16 KHz

    It would appear that divisors larger than 128 don't work.  This has
    not been investigated.

    Not running the UART may half the sample rate.  Again this has not
    been investigated.
*/

// 03/25/04 BPF Control the mic through StdControl rather than MicControl
// 04/23/04 BPF Keep lower order 8 bits rather than upper 8.

includes UtilMath;

module SoundBlockFastM
{
  provides {
    interface StdControl;
    interface WarmUp;
    interface SoundBlock;

    command result_t Config(uint8_t log2Divisor);
  }

  uses {
    interface ADC;
    interface ADCControl;
    interface Mic;
    interface Timer;
  }
}

implementation
{
  bool recording;
  bool isWarm;
  uint8_t *data;
  uint16_t index, len;

  /*
    Helper function
  */
  event result_t Timer.fired()
  {
    atomic {
      isWarm = TRUE;
      recording = FALSE;
      index = 0;
    }
    //call ADC.getContinuousData();
    signal WarmUp.WarmDone();

    return SUCCESS;
  } // Timer.fired

  async event result_t ADC.dataReady(uint16_t mic)
  {
    atomic {
      if ( recording ) {
	data[index] = (MinU16(MaxU16(mic,384),639)-384);
        index++;
	call ADC.getData();
      }
      if (index == len) {
 	recording = FALSE;
	index = 0;
	//call ADC.getData(); // Release the ADC
        signal SoundBlock.GetDone();
      }	
    }
    return SUCCESS;
  } // ADC.dataReady

  /*
    Init interface
  */
  command result_t Config(uint8_t log2Divisor)
  {
    result_t status;

    atomic {
      if ( recording )
	status = FAIL;
      else
      {
	call ADCControl.setSamplingRate(log2Divisor);
	index = 0;
	status = SUCCESS;
      }
    }
    return SUCCESS;
  } // init

  /*
    Warmup interface
  */
  command result_t WarmUp.Warm()
  {
    result_t status;

    atomic {
      if (recording || isWarm)
	status = FAIL;
      else
	status = SUCCESS;
    }

    call Mic.muxSel(1);
    call Mic.gainAdjust(128);
    call Timer.start(TIMER_ONE_SHOT, 400);

    return status;
  } // Warm

  command result_t WarmUp.Sleep()
  {
    result_t status;

    atomic {
      if (recording || !isWarm)
	status = FAIL;
      else
	status = SUCCESS;
    }
    return status;
  } // Sleep

  command bool WarmUp.IsWarm()
    { return isWarm; };
  
  /*
    SoundBlock interface
  */
  command result_t SoundBlock.Get(uint8_t *dataArg, uint16_t lenArg, uint8_t gain)
  {
    if ( !isWarm )
      return FAIL;

    call Mic.gainAdjust(gain);

    atomic {
      data = dataArg;
      len = lenArg;
      recording = TRUE;
    }
    //call ADC.getContinuousData();
    call ADC.getData();

    return SUCCESS;
  } // Get

  /*
    StdControl
  */
  command result_t StdControl.init()
  { 
    atomic {
      recording = FALSE;
      isWarm = FALSE;
    }
    return SUCCESS;
  }

  command result_t StdControl.start()
  { 
    return SUCCESS; 
  }

  command result_t StdControl.stop()
    { return SUCCESS; }
} // SoundBlockFastM

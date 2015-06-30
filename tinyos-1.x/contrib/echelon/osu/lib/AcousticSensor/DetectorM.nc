/*
  D e c t e c t o r M . n c

  This file (c) Copyright 2004 The MITRE Corporation (MITRE)

  This file is part of the NEST Acoustic Subsystem. It is licensed
  under the conditions described in the file LICENSE in the root
  directory of the NEST Acoustic Subsystem.
*/
// 03/23/04 BPF Make sure sample buffer index is always a 16 bit integer.
// 03/30/04 BPF Expand config to include median index arrays.  Correct
// data type conversion errors.
// 04/22/04 BPF Convert to component interface.

includes UtilMath;
includes Fixed;
includes UtilSort;
includes AcousticTuning;


module DetectorM {
  provides {
      interface StdControl;
      interface Detector;
  }

  uses {
    interface StdControl as SubControl;
    interface WarmUp;
    interface SoundBlock;
    interface MedianIndex as RunMedOfMed;
    interface MedianIndex as RunMedOfDev;
    interface MinMax;
    interface Median;
    interface Timer;
    interface Leds;
    interface ReceiveMsg as ReceiveTuningMsg;

    command result_t SoundBlockConfig(uint8_t log2Devisor);
  }
}

implementation {
  enum {
    initGain = 128,
    sampRateDev = 5
  };

  enum {RAW, ABS_DEV_FIX1};

  bool busy;
  bool configured = FALSE;
  uint8_t *samples = NULL;
  uint8_t circBuffPos = 0;
  uint8_t dataForm, gain;
  uint8_t blockPow;
  uint16_t numSamp;
  uint8_t median_len;
  uint16_t min_thresh;
  uint16_t process_interval;
  // Added by Hui Cao
  uint8_t Decide_thresh=3;
  uint8_t eventCount=0;
  bool decision;
  uint8_t param1=3;
  uint8_t param2=2;

  /*
    Forward declarations
  */
  task void Decide();

  /*
    Detector interface
  */
  // 03/23/04 BPF Change numSampArg to 16 bit integer.
  // 03/30/04 BPF Expand config to include median index arrays.
  command result_t Detector.Config(uint16_t numSampArg, uint8_t *samplesArg,
      uint8_t medianLenArg, uint8_t *MedOfMed_buf, uint8_t *MedOfDev_buf,
      uint8_t *MedOfMed_data_buf, uint8_t *MedOfMed_index_buf,
      uint8_t *MedOfDev_data_buf, uint8_t *MedOfDev_index_buf,
      uint16_t period, uint16_t param_thresh)
  {
    result_t status;

    status = SUCCESS;
    atomic{
	numSamp = numSampArg;
	samples = samplesArg;
	median_len = medianLenArg;
	process_interval = period;
	min_thresh = param_thresh;
    }
    call RunMedOfMed.start(median_len,MedOfMed_buf,MedOfMed_data_buf,MedOfMed_index_buf,&status);
    call RunMedOfDev.start(median_len,MedOfDev_buf,MedOfDev_data_buf,MedOfDev_index_buf,&status);
    call SoundBlockConfig(sampRateDev);
    atomic configured = TRUE;
    return status;
  } // init

  command result_t StdControl.start()
  {
    call SubControl.start();
    call WarmUp.Warm();
    return SUCCESS;
  } // start

  command result_t StdControl.stop()
  {
    call SubControl.stop();
    return SUCCESS;
  } // stop

  command result_t StdControl.init()
  { 
	call SubControl.init();
      return SUCCESS;
  }
  
  command result_t Detector.Start(uint16_t period)
  {
    result_t status;

    status = (call Timer.start(TIMER_REPEAT, period));

    if (status == SUCCESS) {
      atomic {
      gain = initGain;
      busy = TRUE;
      }
      call SoundBlock.Get(samples, numSamp, gain);
       //Added by Hui Cao
      decision=FALSE;
      //Hui Cao
    }
    
    return status;
  } // start

  command void Detector.Stop()
  {
    call Timer.stop();
  } // stop

  /*
    Main activity
  */
  event void WarmUp.WarmDone()
  {
    //call Leds.redToggle();
    if (configured)
	call Detector.Start(process_interval);
  } // Timer.fired

  event result_t Timer.fired()
  {
    atomic{
    if ( busy )
    {
      signal Detector.TimeConflict();
	//call SoundBlock.Get(samples, numSamp, gain);
    }
    else {
      busy = TRUE;
	call Leds.redOn();	//for debugging busy stuck
      call SoundBlock.Get(samples, numSamp, gain);
    }
    }
    return SUCCESS;
  } // fired

  async event void SoundBlock.GetDone()
  {
    atomic { dataForm = RAW; }

    //call MinMax.StartU8(samples, numSamp);
    call Median.Start(samples,numSamp);
  } // SoundBlock.Done

  event void MinMax.DoneU8(uint8_t min, uint8_t max)
  {
    uint8_t range;

    range = max - min + 1;
    
    call Median.Start(samples, numSamp);

  } // MinMax.Done

  event void Median.Done(ufix16_1_t median)
  {
    uint16_t i;

    atomic {
    if (dataForm == RAW) {
      for (i = 0; i < numSamp; i++)
	samples[i] = abs((((int16_t) samples[i]) << 1) - median);
      dataForm = ABS_DEV_FIX1;
      call Median.Start(samples, numSamp);

    } else {
      blockPow = (uint8_t)Min16(median, 255);
      post Decide();
    }
    }
  } // Median.Done

// 03/30/04 BPF Correct data type conversion errors.
  task void Decide()
  {
    result_t status=SUCCESS;
    /*
    ufix16_1_t medPow, dev;
    ufix16_2_t medDev;
    */
    uint16_t medPow, dev, medDev;
    uint16_t thresh;
    //Added by Hui Cao
    uint8_t tmpHitorMiss;
    // Added by Hui cao
    call RunMedOfMed.SetData(circBuffPos, blockPow, &status);
    medPow = call RunMedOfMed.MedianValue(&status);
    //medPow = blockPow;	presumed bug

    dev = abs(((int16_t)blockPow) - (int16_t)(medPow>>1));
    call RunMedOfDev.SetData(circBuffPos, dev, &status);
    medDev = call RunMedOfDev.MedianValue(&status);

    circBuffPos = ((circBuffPos+1) % median_len);
    atomic { busy = FALSE;
		 call Leds.redOff(); }

    // Make sure threshold is not zero
    thresh = (uint16_t)Max16(param1*medDev, min_thresh);

    //Added by Hui Cao
  // Algorithm is designed by Emre
  // This is the higher level logic which provides start and stop message.
    if ((dev*param2 ) > thresh)
    {
      
      tmpHitorMiss=0x01;
      if (decision==FALSE)
        {
         eventCount=eventCount+1;
         if (eventCount >= Decide_thresh)
           {
            signal Detector.okStart();
            decision=TRUE;
            eventCount=0;
           }
        }
       else  //decision==TRUE
           {
           	if (eventCount>0)
           	  eventCount=eventCount-1;
            }
    }
    else
    {
      
      tmpHitorMiss=0x00;
      if (decision==TRUE)
        {
         eventCount=eventCount+1;
         if (eventCount >= Decide_thresh)
           {
            signal Detector.okStop();
            decision=FALSE;
            eventCount=0;
           }
        }
       else  //decision==FALSE
           {
           	if (eventCount>0)
           	  eventCount=eventCount-1;
            }
    }
  } // Decide

  /*
    Shouldn't be needed
  */
  event void MinMax.Done16(int16_t min, int16_t max)
    { /* Nothing */ }

  event TOS_MsgPtr ReceiveTuningMsg.receive(TOS_MsgPtr m) {
    Acoustic_Tuning_Msg *message = (Acoustic_Tuning_Msg *)m->data;
    
	param1 = message->param1;
	param2 = message->param2;
	call Leds.yellowToggle();
	call Leds.greenToggle();
    
    return m;
  }
  
} // DetectorM


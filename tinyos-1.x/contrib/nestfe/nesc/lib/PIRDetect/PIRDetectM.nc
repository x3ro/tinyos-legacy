/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University of California.  
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
// $Id: PIRDetectM.nc,v 1.16 2005/08/06 18:07:25 jwhui Exp $
/**
 * Determine if PIR sensings constitute a detection or noise.  Works
 * in 5 stages:
 * 1) val1 = Highpass/Lowpass filter the PIR ADC reading
 * 2) val2 = Sum up ENERGYWINDOW of val1
 * 3) update adaptive threshold
 * 4) val3 = number of hits of adaptive threshold by CONFIDENCEWINDOW
 *           of val2
 * 5) confidence = if val3 is greater than a confidence threshold
 * Note that there is a "damping period" where no reports are made
 * after a detection report unless a sudden jump in ADC value is found
 * 
 * @author Phoebus Chen, Mike Manzo
 * @modified 6/25/2005 Overhaul of UVA Code
 * @modified 6/2/2005 Initial Port of UVA Detection Code
 */

includes Attrs;
includes Registry;
includes PIRDetectTypes;
includes PIRDetectConst;

module PIRDetectM
{
  provides interface StdControl;

  uses interface Attribute<uint16_t> as PIRConfidenceThresh @registry("PIRConfidenceThresh");
  uses interface Attribute<uint16_t> as PIRAdaptMinThresh @registry("PIRAdaptMinThresh");

  uses interface Attribute<uint16_t> as PIRDetection @registry("PIRDetection");
  uses interface Attribute<uint16_t> as PIRRawData @registry("PIRRawData");

  uses {
    interface Timer as InitTimer;
    interface Timer as SampleTimer;
    interface StdControl as PIRControl;
    interface ADC as PIRADC;
    interface PIR;

    interface Leds;
  }
}



implementation
{
  //Configuration Variables
  uint16_t pirMinThresh = PIRMINTHRESH;
  uint16_t confidenceThresh = CONFIDENCETHRESH;

/* config  current settings for the detection algorithm
 */
  ParamSetting config = {
    PIRSAMPLEPERIOD,
    PIRADAPTTHRESHPERIOD,
    PIRREPDAMPING
  };

/*
 * It takes time for the high pass and low pass filters to reach
 * steady state, that is, the outputs from them become stable.
 * FILTSETTLE define the number of samples to wait and filtSettleCount
 * counts how long the PIR module has waited.
 */   
  uint8_t filtSettleCount = FILTSETTLE;

/*
 * coefHighpassMA and coefHighpassAR define the coefficients for 
 * the MA and AR parts in the high pass filter, respectively.
 */  
  int16_t coefHighpassMA[HIGHPASSMAORDER+1] = {10, -10};
  int16_t coefHighpassAR[HIGHPASSARORDER+1] = {10, -9};
  
/*
 * bufHighpassMA and bufHighpassAR are buffers to store history
 * data used by the MA and AR parts in the high pass filter, respectively.
 * NOTE: buffHighpassMA must NOT be uint16_t for type conversion to
 * work properly in subsequent arithmetic
 */
  int16_t bufHighpassMA[HIGHPASSMAORDER];
  int32_t bufHighpassAR[HIGHPASSARORDER];
  
/*
 * coefLowpassMA and coefLowpassAR define the coefficients for 
 * the MA and AR parts in the low pass filter, respectively.
 */  
//  int16_t coefLowpassMA[LOWPASSMAORDER+1] = {16, 64, 96, 64, 16};
//  int16_t coefLowpassAR[LOWPASSARORDER+1] = {16, -13, 11, -3};
  int16_t coefLowpassMA[LOWPASSMAORDER+1] = {1,0};
  int16_t coefLowpassAR[LOWPASSARORDER+1] = {2,-1};
  
/*
 * bufLowpassMA and bufLowpassAR are buffers to store history
 * data used by the MA and AR parts in the high pass filter, respectively.
 */
  int32_t bufLowpassMA[LOWPASSMAORDER];
  int32_t bufLowpassAR[LOWPASSARORDER];
 
/** PIR Power Buffer
 * avePIRVar - value from high/low pass filter (should be > 0)
 * PIRPower - buffer holding past values of avePIRVar
 * PIREnergy - sum of PIRPower entries
 * PIREnergyCnt - counter for initialization
 * (see maxPIREnergy below as well)
 */
  int32_t avePIRVar = 0;
  uint32_t PIRPower[ENERGYWINDOW];
  uint32_t PIREnergy = 0;
  uint8_t PIREnergyCnt = ENERGYWINDOW*5;

/** Adaptive Threshold Variables
 * threshResetCnt - How often to update the adaptive threshold
 * threshUpdateCnt - counter
 * AdaptThresh - threshold adapting to the background noise.
 * maxPIREnergy - the maximum PIR signal energy after the last
 *                threshold adaption. (initialized by getPIREnergy)
 * threshReady - flag that adaptive threshold is initialized.
 */  
  uint16_t threshResetCnt = 100;
  uint16_t threshUpdateCnt = 0;
  uint16_t AdaptThresh = PIRMINTHRESH;
  uint32_t maxPIREnergy = 0;
  bool threshReady = FALSE;


/** PIR Decision Data Buffer
 * hitHistory - stores the history of PIR energy hitting the threshold value. 
 *              It keeps the past CONFIDENCEWINDOW records
 * posBuffer  - pointer to the current record in HitHistory.
 * numHit     - the number of continuous hits of the threshold value.
 * numSample  - the number of samples after the previous detection
 *              report.
 * lastConfidence - the previous reported confidence value.  (for
 *                  detecting sudden jumps)
 */
  uint16_t hitHistory[CONFIDENCEWINDOW];
  uint8_t posBuffer = 0;
  uint16_t numHit = 0;
  uint16_t numSample = 0;
  uint16_t lastConfidence = 0;
  
  uint16_t dataVal = 0;

  // ========================================================
  

  command result_t StdControl.init() {
    uint8_t i;

    // Initialize PIR high/low filter buffers
    atomic {
      filtSettleCount = FILTSETTLE;
      for (i=0; i<HIGHPASSMAORDER; i++) {
	bufHighpassMA[i] = 0;
      }
      for (i=0; i<HIGHPASSARORDER; i++) {
	bufHighpassAR[i] = 0;
      }
      for (i=0; i<LOWPASSMAORDER; i++) {
	bufLowpassMA[i] = 0;
      }
      for (i=0; i<LOWPASSARORDER; i++) {
	bufLowpassAR[i] = 0;
      }
    }

    // Initialized PIR signal power buffer
    for (i=0; i<ENERGYWINDOW; i++) {
      PIRPower[i]=0;
    }
    PIREnergy = 0;
    atomic avePIRVar = 0;
    PIREnergyCnt = ENERGYWINDOW*5;//time to settle down maxPIREnergy
      
    // Initialized Adaptive Threshold variables
    threshUpdateCnt = 0;
    threshResetCnt = 100;
    AdaptThresh = PIRMINTHRESH;
    maxPIREnergy = 0;
    threshReady = FALSE;

    // Initialize PIR decision buffer
    for (i=0; i<CONFIDENCEWINDOW; i++) {
      hitHistory[i] = 0x0;
    }
    posBuffer = 0;
    numHit = 0;
    numSample = 0;
    lastConfidence = 0;
    confidenceThresh = CONFIDENCETHRESH;
      
    call Leds.init();
    call PIRControl.init();
    return SUCCESS;
  }


  command result_t StdControl.start() {
    //////////Registry Code Start//////////
    uint16_t* regPtr = NULL;
    //    regPtr = call PIRConfidenceThresh.get(); //!!! Fix later!!!
    if (regPtr == NULL) {
      call PIRConfidenceThresh.set(confidenceThresh);
    } else {
      confidenceThresh = *regPtr;
    }
    //    regPtr = call PIRAdaptMinThresh.get();
    if (regPtr == NULL) {
      call PIRAdaptMinThresh.set(pirMinThresh);
    } else {
      pirMinThresh = *regPtr;
    }
    call PIRDetection.set(0);
    call PIRRawData.set(0);
    //////////Registry Code Stop//////////

    threshResetCnt = config.threshResetmSec/config.samplePeriod;
    threshUpdateCnt = 0;
    atomic filtSettleCount = FILTSETTLE;
    
    call PIRControl.start();
    //must wait for proper operation (see PIR interface for details)
    call InitTimer.start(TIMER_ONE_SHOT, PIRINITTIME);
    return SUCCESS;
  }


  command result_t StdControl.stop() {
    call InitTimer.stop();
    call SampleTimer.stop();
    call PIR.PIROff();
    call PIRControl.stop();   
    return SUCCESS;
  }



  /** PIREnergy is the sum of all previous PIRPower + avePIRVar
   *  called by processing()
   * INPUT
   *  @param avePIRVar
   * STATE
   *  @param PIRPower
   *  @param PIREnergyCnt
   * OUTPUT
   *  @param maxPIREnergy  Only initialization, before (PIREnergyCnt == 0)
   *  @param PIREnergy
   *  @return PIREnergyReady  Whether the PIREnergy buffer is filled
   */
  bool getPIREnergy() {
    uint8_t i;
    PIREnergy = 0;
    for (i=0; i<ENERGYWINDOW-1; i++) {
      PIREnergy += PIRPower[i];
      PIRPower[i] = PIRPower[i+1];
    }
    PIRPower[ENERGYWINDOW-1] = avePIRVar;
    PIREnergy += PIRPower[ENERGYWINDOW-1];
    if (PIREnergyCnt > 0) {
      PIREnergyCnt--;
      maxPIREnergy = max(PIREnergy,maxPIREnergy); //initialize maxPIREnergy
    }
    return (PIREnergyCnt == 0);
  }


  /** Updates the Adaptive Threshold called by processing()
   * INPUT
   *  @param PIREnergy
   *  @param pirMinThresh
   *  @param threshResetCnt
   * STATE
   *  @param threshUpdateCnt
   *  @param maxPIREnergy  (initialized by getPIREnergy)
   * OUTPUT
   *  @param AdaptThresh
   *  @return threshReady  whether threshold is initialized
   */ 
  bool updateAdaptThresh() {
    maxPIREnergy = max(PIREnergy,maxPIREnergy);

    //called ONCE; first call after initialization
    if (threshUpdateCnt == 0) {
      AdaptThresh = max(maxPIREnergy,pirMinThresh);
      maxPIREnergy = 0;
    }

    if (threshUpdateCnt == threshResetCnt) {
      if (AdaptThresh < maxPIREnergy) {
	AdaptThresh = 
	  (UPADAPTATIONWEIGHTOLD * AdaptThresh  + 
	   UPADAPTATIONWEIGHTNEW * maxPIREnergy) / 
	  (UPADAPTATIONWEIGHTOLD + UPADAPTATIONWEIGHTNEW);
      } else {
	AdaptThresh = 
	  (DOWNADAPTATIONWEIGHTOLD * AdaptThresh + 
	   DOWNADAPTATIONWEIGHTNEW * maxPIREnergy) / 
	  (DOWNADAPTATIONWEIGHTOLD + DOWNADAPTATIONWEIGHTNEW);
      }
      AdaptThresh = max(AdaptThresh,pirMinThresh);
      threshReady = TRUE;
      maxPIREnergy = 0;
      threshUpdateCnt = 0;
    } // if (threshUpdateCnt == threshResetCnt)
    threshUpdateCnt++;

    dbg(DBG_USR1, "%d - PIRDetectM.updateAdaptThresh: threshUpdateCnt = %u\n",
	TOS_LOCAL_ADDRESS, threshUpdateCnt);
    dbg(DBG_USR1, "%d - PIRDetectM.updateAdaptThresh: AdaptThresh = %u\n",
	TOS_LOCAL_ADDRESS, AdaptThresh);
    return threshReady;
  }


  /** Update Hit History called by processing()
   * INPUT
   *  @param AdaptThresh
   *  @param PIREnergy
   * STATE
   *  @param histHistory[CONFIDENCEWINDOW]
   *  @param posBuffer
   * OUTPUT/STATE
   *  @param numHit
   */ 
  void updateHitHistory() {
    numHit -= hitHistory[posBuffer]; //remove oldest hit (circ buffer)
    if (PIREnergy > AdaptThresh) {
      hitHistory[posBuffer] = 1;
    } else {
      hitHistory[posBuffer] = 0;
    }
    numHit += hitHistory[posBuffer];
    posBuffer = (posBuffer+1)%CONFIDENCEWINDOW;
  }


  /** Detection Processing
   * INPUT
   * @param avePIRVar
   * OUTPUT
   * @param lastConfidence
   * POSTCONDITION
   *  AdaptiveThreshold is updated (through updateAdaptThresh)
   *  HitHistory is updated (through updateHitHistory)
   *  PIRPower is updated (through getPIREnergy)
   */
  task void processing() {
    bool PIREnergyReady;
    uint16_t confidence; // Total confidence is the ratio between the
			 // number of hits and the window size.
    atomic PIREnergyReady = getPIREnergy();
    if (PIREnergyReady && //PIREnergy is ready to update threshold
	updateAdaptThresh()){ //if threshold has settled and is ready
      updateHitHistory(); //"returns" numHit
    }

    confidence = (100 * numHit) / CONFIDENCEWINDOW;
    // Count the number of samples since the last report about detection.
    numSample = (numSample+1)%config.nRepDamping;
    if (abs(confidence - lastConfidence) > SUDDENJUMP) {
      numSample = 0;
    }
    if (numSample == 0) {
      if (confidence >= confidenceThresh) {
	call PIRDetection.set(confidence); //Detection Reported
      } else {
	call PIRDetection.set(0);
      }
      lastConfidence = confidence;
    }
    
    //Debugging
    dbg(DBG_USR1, "%d - PIRDetectM.processing: PIREnergy = %lu\n",
	TOS_LOCAL_ADDRESS, PIREnergy);
    dbg(DBG_USR1, "%d - PIRDetectM.processing: numHits = %u\n",
	TOS_LOCAL_ADDRESS, numHit);
    if (confidence > 5) {
      call Leds.yellowOn();
    } else { 
      call Leds.yellowOff();
    }
  }

  

  /** Update buffers (shift [i-1] -> [i]) & append:
   *   buffHighpassMA <- dataval
   *   buffHighpassAR <- PIRVar
   *   buffLowpassMA <- absPIRVar
   *   buffLowpassAR <- avePIRVar
   */
  void updateBuffers(uint16_t dataval, int32_t PIRVar, int32_t absPIRVar) {
    uint8_t i;
      for (i=HIGHPASSMAORDER-1; i>0; i--) {
        bufHighpassMA[i] = bufHighpassMA[i-1];
      }
      if (HIGHPASSMAORDER > 0) {
        bufHighpassMA[0] = dataval;
      }
      for (i=HIGHPASSARORDER-1; i>0; i--) {
        bufHighpassAR[i] = bufHighpassAR[i-1];
      }
      if (HIGHPASSARORDER > 0) {
        bufHighpassAR[0] = PIRVar;
      }
      for (i=LOWPASSMAORDER-1; i>0; i--) {
        bufLowpassMA[i] = bufLowpassMA[i-1];
      }
      if (LOWPASSMAORDER > 0) {
        bufLowpassMA[0] = absPIRVar;
      }
      for (i=LOWPASSARORDER-1; i>0; i--) {
        bufLowpassAR[i] = bufLowpassAR[i-1];
      }
      if (LOWPASSARORDER > 0) {
        bufLowpassAR[0] = avePIRVar;
      }
  }


  /** Passes PIRADC values through highpass/lowpass filters
   * INPUT
   *  @param dataVal
   * STATE
   *  @param filtSettleCount
   *  @param buffers  updated via updateBuffers()
   * OUTPUT
   *  @param avePIRVar
   */
  task void filtering() {
    uint8_t i;
    int32_t PIRVar = 0;
    int32_t absPIRVar = 0;

    atomic{ 
      call PIRRawData.set(dataVal);
      PIRVar = coefHighpassMA[0] * dataVal;
    }
    for (i=0; i<HIGHPASSMAORDER; i++) {
      PIRVar += (coefHighpassMA[i+1] * bufHighpassMA[i]);
    }
    for (i=0; i<HIGHPASSARORDER; i++) {
      PIRVar -= (coefHighpassAR[i+1] * bufHighpassAR[i]);
    }
    PIRVar /= coefHighpassAR[0];

    absPIRVar = abs(PIRVar);
    avePIRVar = coefLowpassMA[0] * absPIRVar;
    for (i=0; i<LOWPASSMAORDER; i++) {
      avePIRVar += (coefLowpassMA[i+1] * bufLowpassMA[i]);
    }
    for (i=0; i<LOWPASSARORDER; i++) {
      avePIRVar -= (coefLowpassAR[i+1] * bufLowpassAR[i]);
    }
    avePIRVar /= coefLowpassAR[0];
    avePIRVar = abs(avePIRVar); //just to be sure
    if(filtSettleCount > 0) {
      filtSettleCount--;
    } else {
      post processing();
    } //if (filtSettleCount ...)

    atomic updateBuffers(dataVal,PIRVar,absPIRVar);
    dbg(DBG_USR1, "%d - PIRDetectM.filtering: avePIRVar = %lu\n",
	TOS_LOCAL_ADDRESS, avePIRVar);
  }


  async event result_t PIRADC.dataReady(uint16_t val) {
    atomic{
      dataVal = val;
      dbg(DBG_USR1, "%d - PIRDetectM.PIRADC.dataReady: got data from PIR, %d\n", 
	TOS_LOCAL_ADDRESS, (int) dataVal);
    }
    call Leds.greenToggle();

    post filtering();
    return SUCCESS;
  }


  event result_t InitTimer.fired() {
    call PIR.PIROn();
    call SampleTimer.start(TIMER_REPEAT, config.samplePeriod);
    //call SampleTimer.start(TIMER_REPEAT, 102);
    return SUCCESS;
  }


  event result_t SampleTimer.fired() {
    return call PIRADC.getData();
  }


  //////////Registry Code Start//////////
  event void PIRConfidenceThresh.updated(uint16_t val) {
    confidenceThresh = val;
  }

  event void PIRAdaptMinThresh.updated(uint16_t val) {
    pirMinThresh = val;
  }

  event void PIRDetection.updated(uint16_t val) {
  //Do nothing
  }

  event void PIRRawData.updated(uint16_t val) {
  //Do nothing
  }
  //////////Registry Code Stop//////////



////////////////////////////// PIR control code ////////////////////////////// 
// !!! Need to add PIR control code from registry

  event void PIR.readDetectDone(uint8_t val) {
    //    atomic detect_pot = val;
    //    post detect_report_task();
  }
  event void PIR.readQuadDone(uint8_t val) {
    //    atomic quad_pot = val;
    //    post quad_report_task();
  }
  event void PIR.adjustDetectDone(bool result) { }
  event void PIR.adjustQuadDone(bool result) { }
  event void PIR.firedPIR() {
    //    atomic mask = IOSWITCH1_INT_PIR;
    //    post interrupt_report_task();
  }
}

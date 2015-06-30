/**
 * samplePeriod
 *   period (samples/sec) for sampling PIR ADC value.
 *
 * threshAdaptSec
 *   period to adapt the adaptive threshold, in seconds.
 *
 * repDamping 
 *   # of milliseconds a sensor must wait before firing a
 * new report after a previous report. This is when there is no
 * dramatic change or urgent report. When there is dramatic change or
 * urgent report, the sensor reports immediately.
 */

#include "PIRDetectConst.h"

typedef struct {
  uint16_t samplePeriod;
  uint32_t threshResetmSec;
  uint16_t nRepDamping;
} ParamSetting;

/* // Not used yet */
/* typedef struct { */
/*   uint8_t filtSettleCnt; */
/*   uint8_t PIREnergyCnt; */
/* } InitSetting; */

/* // Not used */
/* typedef struct { */
/*   uint16_t HitHistory[CONFIDENCEWINDOW]; */
/*   uint8_t posBuffer; */
/*   uint16_t numHit; */
/*   uint16_t numSample; */
/*   uint16_t oldConfidence; */
/* } DataBuffer; */

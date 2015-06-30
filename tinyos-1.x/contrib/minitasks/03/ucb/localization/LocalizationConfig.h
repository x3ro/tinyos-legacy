#ifndef _TOS_LOCALIZATION_CONFIG_H
#define _TOS_LOCALIZATION_CONFIG_H

#include "Localization.h"

typedef struct {
  uint16_t numberOfBatches;
  uint16_t numberOfRangingEstimates;
  uint16_t rangingPeriodEstimate;
  uint16_t rangingPeriodFudgeFactor;
  uint16_t rangingStdv;
} RangingParameters_t;

typedef struct {
  uint16_t rangingStartDelayBase;
  uint16_t rangingStartDelayMask;
} RangingStartDelay_t;

typedef struct {
  uint16_t ultrasoundFilterLow;
  uint16_t ultrasoundFilterHigh;
} UltrasoundFilterParameters_t;

typedef struct {
  bool isAnchor;
  location_t realLocation;
  location_t localizedLocation;
} LocationInfo_t;

typedef enum {
	POSITION_LOCALIZED = 2,
	POSITION_WORD = 1,
	POSITION_HARDCODED = 0
} PositionType;

/******** Ranging Config (initial) **************/

#define NEGATIVE_LOCALIZATION_UNSIGNED_16 60000u

//!! Config 91 { bool signalRangingDone = FALSE; }

//!! Config 92 { uint16_t rangingBias = 3200; }

//!! Config 93 { uint16_t rangingScale = 33; }

//!! Config 94 { uint8_t rangingCountMin = 5; }

//!! Config 95 { uint16_t managementTimerBase = 4096; }

//!! Config 96 { uint16_t managementTimerMask = 0x7ff; } 

//!! Config 97 { bool positionDebug = FALSE; }

//!! Config 98 { bool rangingDebug = FALSE; }

//!! Config 99 { uint16_t maxAnchorRank = 1300; }

//!! Config 100 { uint16_t myRangingId = 0; }

//!! Config 101 { RangingParameters_t RangingParameters = {numberOfBatches:2, numberOfRangingEstimates:10, rangingPeriodEstimate:512, rangingPeriodFudgeFactor:5000, rangingStdv:20 }; }

//!! Config 102 { UltrasoundFilterParameters_t UltrasoundFilterParameters = { ultrasoundFilterLow:100, ultrasoundFilterHigh:340 }; }

//!! Config 103 { bool isLastRangingNode = FALSE; }

//!! Config 104 { uint16_t localizationPeriod = 4; }

//!! Config 105 { RangingStartDelay_t RangingStartDelay = {rangingStartDelayBase:2048, rangingStartDelayMask:0xfff }; }

//!! Config 106 { LocationInfo_t LocationInfo = { isAnchor:FALSE, realLocation:{pos:{x:65535u, y:65535u }, stdv:{x:65534u, y:65534u}}, localizedLocation:{pos:{x:65535u, y:65535u }, stdv:{x:65534u, y:65534u}}}; }


#endif /* _TOS_LOCALIZATION_CONFIG_H */

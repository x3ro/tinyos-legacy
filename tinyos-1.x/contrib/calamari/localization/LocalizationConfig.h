#ifndef _TOS_LOCALIZATION_CONFIG_H
#define _TOS_LOCALIZATION_CONFIG_H

#include "Localization.h"

typedef struct {
  uint16_t numberOfBatches;
  uint16_t numberOfRangingEstimates;
  uint16_t successiveRangeDelay;
  uint16_t successiveRangeDelayMask;
  uint16_t rangingPeriodFudgeFactor;
  uint16_t rangingStdv;
} RangingParameters_t;

typedef struct {
  uint16_t exchangeTimeout;
  uint16_t exchangeMask;
  uint16_t exchangeRetry;
  uint16_t exchangeRetryTimeout;
  uint16_t anchorExchangeTimeout;
} RangingExchangeParameters_t;

typedef struct {
  uint16_t rangingStartDelayBase;
  uint16_t rangingStartDelayMask;
} RangingStartDelay_t;

typedef struct {
  uint16_t filterLow;
  uint16_t filterHigh;
} RangingFilterParameters_t;

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

enum { RSSI = 1,
       ULTRASOUND = 2 };

/******** Ranging Config (initial) **************/

//!! Config 90 { RangingExchangeParameters_t RangingExchangeParameters = { exchangeTimeout:16000, exchangeMask: 8095, exchangeRetry:3, exchangeRetryTimeout:2047, anchorExchangeTimeout:8095 }; }

//!! Config 91 { uint16_t shortestPathTimeout = 8095; }

//!! Config 92 { uint16_t ultrasoundRangingBias = 40; }

//!! Config 93 { float ultrasoundRangingScale = 31; }

//!! Config 94 { uint8_t rangingCountMin = 4; }

//--!! Config 95 { uint16_t managementTimerBase = 4096; }
//!! Config 95 { uint16_t managementTimerBase = 100; }

//--!! Config 96 { uint16_t managementTimerMask = 0x7ff; } 
//!! Config 96 { uint16_t managementTimerMask = 127; }

//!! Config 97 { bool positionDebug = FALSE; }

//!! Config 98 { bool rangingDebug = FALSE; }

//!! Config 99 { uint16_t maxAnchorRank = 65535u; }

//!! Config 100 { uint16_t myRangingId = 0; }

//!! Config 101 { RangingParameters_t RangingParameters = {numberOfBatches:1, numberOfRangingEstimates:10, successiveRangeDelay:500, successiveRangeDelayMask:127, rangingPeriodFudgeFactor:10, rangingStdv:20 }; }

//!! Config 102 { RangingFilterParameters_t RangingFilterParameters = { filterLow:0, filterHigh:30000 }; }

//!! Config 103 { bool isLastRangingNode = FALSE; }

//!! Config 104 { bool initiateSchedule = TRUE; }

//!! Config 105 { RangingStartDelay_t RangingStartDelay = {rangingStartDelayBase:1024, rangingStartDelayMask:1023 }; }

//!! Config 106 { LocationInfo_t LocationInfo = { isAnchor:FALSE, realLocation:{pos:{x:65535u, y:65535u }, stdv:{x:65534u, y:65534u}}, localizedLocation:{pos:{x:65535u, y:65535u }, stdv:{x:65534u, y:65534u}}}; }

// 107 defined in CorrectionM

//!! Config 108 { uint16_t txRetry = 4;}

//!! Config 109 { uint16_t txDelay = 75;}

//!! Config 110 { uint16_t deltaDistanceThreshold = 65535u;}

//!! Config 111 { uint16_t txAnchorPeriod = 100;}

//!! Config 112 { uint16_t  medianTube = 10;}

//!! Config 113 { float proportionalMedianTube = 0;}

//!! Config 114 { uint8_t diagMsgOn = 0;}

//!! Config 115 { uint16_t txDelayMask = 4095;}

//!! Config 116 { uint16_t calamariRFPower = 255;}

//!! Config 117 { bool exchangeRanging = TRUE;}

//#define NEGATIVE_LOCALIZATION_UNSIGNED_16 60000u
//!! Config 118 {uint16_t negativeLocalizationUnsigned = 65535u; }

//!! Config 119 {uint8_t rangingTech = RSSI; }

//!! Config 120 { uint16_t RSSIRangingBias = 215; }

//!! Config 121 { float RSSIRangingScale = 5; }

//!! Config 122 { uint8_t rangingExchangeBehavior = 0; }

//!! Config 123 { uint8_t managementHopDelay = 6; }

#endif /* _TOS_LOCALIZATION_CONFIG_H */

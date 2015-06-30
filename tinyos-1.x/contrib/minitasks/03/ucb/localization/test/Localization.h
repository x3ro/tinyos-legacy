#ifndef _H_Localization_h
#define _H_Localization_h


#include "common_structs.h"

enum {
  MAX_NUM_ANCHORS = 3,//this should be three!
};

enum{AM_LOCALIZATIONDEBUGMSG=241};

typedef struct {
  uint16_t distance;
  uint16_t stdv;
} distance_t;

typedef struct {
  Pair_uint16_t pos;
  Pair_uint16_t stdv;
//  uint8_t coordinate_system;
} location_t;

typedef struct {
  uint16_t ID;
  location_t location;
  distance_t distance;
} anchor_t;

typedef struct {
  uint16_t anchorID;
  uint16_t hopsFromSourceOfCorrection;
  float correction;
} anchorCorrection_t;

typedef struct {
  anchor_t data[MAX_NUM_ANCHORS];
} anchorArray_t;

typedef struct {
  anchorCorrection_t data[MAX_NUM_ANCHORS];
} anchorCorrectionArray_t;

typedef struct {
	uint16_t myID;
	location_t location;
}LocalizationDebugMsg_t;


#endif // _H_Localization_h




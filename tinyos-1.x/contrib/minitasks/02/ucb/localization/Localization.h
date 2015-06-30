#ifndef _H_Localization_h
#define _H_Localization_h


#include "common_structs.h"

enum {
  MAX_NUM_ANCHORS = 2,//this should be three!
};

typedef struct {
  Triple_int16_t pos;
  Triple_int16_t stdv;
  uint8_t coordinate_system;
} location_t;

typedef struct {
  uint16_t ID;
  location_t location;
  uint16_t shortestPathDistance;
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

#endif // _H_Localization_h


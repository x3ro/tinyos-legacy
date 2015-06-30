#ifndef _H_Localization_h
#define _H_Localization_h


#include "common_structs.h"

enum {
  MAX_NUM_ANCHORS = 3,//this should be three!
  MAX_NUM_REPORTED_ANCHORS = 4,
  MAX_NUM_REPORTED_RANGING_NEIGHBORS = 8
};

enum {
  AM_LOCALIZATIONDEBUGMSG = 241,
  AM_RANGINGREPORTMSG = 210,
  AM_ANCHORREPORTMSG = 211,
  AM_MONITORMSG = 212
};

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
  uint16_t sourceAnchor;
  uint16_t correctedAnchor;
  uint16_t correction;
} correction_t;

typedef struct {
  uint16_t ID;
  location_t location;
  distance_t distance;
} anchor_t;

typedef struct {
  uint16_t addr;
  uint16_t dist;
  uint8_t hopCount;
} anchor_report_t;

// WARNING: addr CHANGED to UINT8 FOR MINIDEMO
typedef struct {
  uint8_t addr;
  uint16_t dist;
} ranging_report_t;


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
} LocalizationDebugMsg_t;

typedef struct {
  uint16_t addr;
  uint8_t numberOfAnchors;
  anchor_report_t anchors[MAX_NUM_REPORTED_ANCHORS];
} AnchorReportMsg_t;

typedef struct {
  uint16_t addr;
  uint8_t numberOfNeighbors;
  ranging_report_t neighbors[MAX_NUM_REPORTED_RANGING_NEIGHBORS];
} RangingReportMsg_t;


#endif // _H_Localization_h




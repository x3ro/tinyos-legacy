/**
 * @author Phoebus Chen, Cory Sharp
 * @modified 7/21/2005 Added enum from DummyEventGen.h
 * @modified 11/7/2005 Added sequence numbers to DetectionEventMsg
 *                     for monitoring quality
 */

//$Id: DetectionEvent.h,v 1.6 2005/11/13 22:01:06 phoebusc Exp $

/* DEFAULT_SAMPLE_PERIOD is in binary milliseconds */
enum {
  DEFAULT_DETECT_STRENGTH = 1,
  DEFAULT_SAMPLE_PERIOD = 1000,
};

/** For future use, to signal different event types (classification)
 *  Later may wish to remove PIR_SIMPLE_THRESH, PIR_FILTER
 */
enum EventTypes {
  UNKNOWN_TYPE = 1,
  BUTTON_PRESS = 2,
  ITS_A_TANK = 3,
  PIR_SIMPLE_THRESH = 100,
  PIR_FILTER = 101,
};

enum {
  AM_DETECTIONEVENTMSG = 40,
};

typedef struct location_t {
  int32_t x;
  int32_t y;
} location_t;

typedef struct detection_event_t {
  uint32_t time;
  location_t location;
  uint16_t strength;
  uint8_t type;
} detection_event_t;

typedef struct DetectionEventMsg {
  detection_event_t detectevent;
  uint16_t count;  // for keeping track of transmission success rate
} DetectionEventMsg;


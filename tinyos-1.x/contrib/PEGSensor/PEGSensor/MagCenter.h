
#ifndef _H_MagCenter_h
#define _H_MagCenter_h

#include "common_structs.h"
#include "ERoute.h"

typedef uint16_t MagValue_t;
typedef uint32_t MagTime_t;
typedef Pair_uint16_t MagPosition_t;

typedef struct
{
  MagValue_t value;
  MagTime_t time;
} MagReading_t;

typedef struct
{
  MagReading_t reading;
  MagPosition_t position;
} MagData_t;

typedef struct
{
  uint32_t mag_sum;
  int32_t x_sum;
  int32_t y_sum;
  //uint16_t src_addr; //available as TOS_Msg.ext.origin
  int8_t num_reporting;
} MagLeaderReport_t;

typedef struct
{
  uint16_t id;
  MagValue_t value;
} MagNodeStatus_t;

typedef struct
{
  MagValue_t myMag;
  uint8_t timeoutFlags;
  uint8_t worseFlags;
  MagNodeStatus_t nodes[4];
} MagStatus_t;

typedef struct
{
  MagPosition_t leader_pos;
  MagPosition_t event_pos;
  MagValue_t mag_strength;
} MagLeaderToPursuer_t;

typedef struct
{
  EREndpoint pursuer_id;
  uint16_t crumb_seq_num;
  MagPosition_t last_known_pos;
  uint8_t flags;
} PursuerToMagLeader_t;

enum
{
  MAGTIME_TIMEOUT = 16384L, // 2^14 jiffies = 0.5 seconds
  MAGTIME_READING_PERIOD = 50,
  SEND_MAG_CENTER_BROADCAST = 0,
  SEND_MAG_CENTER_CROUTE = 1,
  SEND_MAG_CENTER_NEVER = 2,
  PURSUER_LAST_KNOWN_POS_IS_VALID_FLAG = 1,

  PROTOCOL_MAG_LEADER_TO_PURSUER = 80,
  PROTOCOL_PURSUER_TO_MAG_LEADER = 81,
  PROTOCOL_SENDMAG_CENTER_BROADCAST = 82,
  CAPSULE_SEND_MAGCENTER_CROUTE = 83,
  PROTOCOL_MAGCENTER_ALWAYS_INJECT = 84,
  PROTOCOL_MAGCENTER_CLOSEST_INJECT = 85,
};

#endif//_H_MagCenter_h


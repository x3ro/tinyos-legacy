#ifndef TIMESYNC_H_INCLUDED
#define TIMESYNC_H_INCLUDED

#include "TosTime.h"

enum {
  AM_AGILLATIMESYNCMSG       = 0x50,
};


typedef struct AgillaTimeSyncMsg 
{
  tos_time_t time;  // tos_time_t is defined within tos/interfaces/TosTime.h
} AgillaTimeSyncMsg;

#endif

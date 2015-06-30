#ifndef _SR_COMMON__
#define _SR_COMMON__

#include "CompressedSet.h"

enum {
  // Nodes awaken every ROLLCALL_PERIOD...
  ROLLCALL_PERIOD = 30 * 1024,

  // and wait for at most his long
  MAX_ROUND_WAIT = 5 * 1024,

  // but, actually, for MAX_ROUND_WAIT - WAIT_PER_LEVEL * treeLevel...
  WAIT_PER_LEVEL = 5 * 103,

  // before sending their reports, spread out randomly
  // over this interval
  STAGGER_INTERVAL = 103,

  // The buffer which stores the bitmap is at most this long
  // max nodes = (MAX_LIVE_BITMAP_BYTES - 1) * 8
  MAX_LIVE_BITMAP_BYTES = 21,

  // The length of the history (for suppressing stray packets)
  MAX_LIVE_SET_HISTORY = 1,

  MAX_SEND_RETRIES = 2,

  MAX_NODES = ((MAX_LIVE_BITMAP_BYTES - sizeof(Set)) << 3),

  RADIO_POWER = 128
};

#endif

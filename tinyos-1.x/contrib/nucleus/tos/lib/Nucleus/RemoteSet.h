//$Id: RemoteSet.h,v 1.3 2005/08/04 01:27:25 gtolle Exp $

#ifndef __REMOTESET_H__
#define __REMOTESET_H__

#include "Attrs.h"

enum {
  AM_REMOTESETMSG = 13,
  REMOTESET_MAX_LENGTH = 8,
};

typedef struct RemoteSetMsg {
  AttrID id;
  uint8_t isRAM;
  uint8_t pos;
  uint8_t value[0];
} RemoteSetMsg;

#endif


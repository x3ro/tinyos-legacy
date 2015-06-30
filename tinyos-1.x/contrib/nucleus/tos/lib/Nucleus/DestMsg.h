//$Id: DestMsg.h,v 1.3 2005/06/14 18:10:10 gtolle Exp $

#ifndef __DESTMSG_H__
#define __DESTMSG_H__

typedef struct DestMsg {
  uint16_t addr;
  uint8_t ttl;
  uint8_t pad;
  uint8_t data[0];
} DestMsg;

#endif

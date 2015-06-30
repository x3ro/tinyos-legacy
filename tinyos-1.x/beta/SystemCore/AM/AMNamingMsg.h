#ifndef __AM_NAMINGMSG_H__
#define __AM_NAMINGMSG_H__

typedef struct NamingMsg {
  uint8_t ttl;
  uint8_t group;
  uint16_t addr;
  uint8_t data[0];
} NamingMsg;

#endif

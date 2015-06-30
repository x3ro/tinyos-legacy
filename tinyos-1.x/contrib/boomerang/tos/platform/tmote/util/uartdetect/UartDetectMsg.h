#ifndef __UARTDETECTMSG_H__
#define __UARTDETECTMSG_H__

enum {
  AM_UARTDETECTMSG = 101,
};

enum {
  UARTDETECT_REQUEST = 0,
  UARTDETECT_RESPONSE = 1,
  UARTDETECT_KEEPALIVE = 2,
};

enum {
  UARTDETECT_POLL = 1024*3,
};

typedef struct UartDetectMsg {
  uint8_t cmd;
  uint8_t id;
  uint16_t addr;
  uint32_t timeout;
} uartdetectmsg_t;

#endif

#ifndef _CRICKETTORF_H
#define _CRICKETTORF_H

#include <stdio.h>
#include <AM.h>

#define CRICKET_MSG_DATA_SIZE (TOSH_DATA_LENGTH - 5)
#define DATA_SIZE 100

typedef struct CricketMsg {
  uint16_t id;
  uint8_t serno;
  uint8_t start;
  uint8_t size;
  char data[CRICKET_MSG_DATA_SIZE];
} CricketMsg;

enum {
  AM_CRICKETMSG = 0x10,
};

#endif

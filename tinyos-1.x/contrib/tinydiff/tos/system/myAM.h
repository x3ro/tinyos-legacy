/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

#ifndef AM_H_INCLUDED
#define AM_H_INCLUDED

#include "stddef.h" 
#include <inttypes.h>

// Message format


enum {
  TOS_BCAST_ADDR = 0xffff,
  TOS_UART_ADDR = 0x007e,
};

#ifndef DEF_TOS_AM_GROUP
#define DEF_TOS_AM_GROUP 0x7d
#endif

enum {
  TOS_DEFAULT_AM_GROUP = DEF_TOS_AM_GROUP
};

//uint8_t TOS_AM_GROUP = TOS_DEFAULT_AM_GROUP;

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 29
#endif

typedef struct TOS_Msg
{
  /* The following fields are transmitted/received on the radio. */
  // What is addr? it's the destination address
  uint16_t addr;
  uint8_t type;
  uint8_t group;
  uint8_t length;
  uint16_t saddr;
  int8_t data[TOSH_DATA_LENGTH - 2];
  uint16_t crc;

  /* The following fields are not actually transmitted or received 
   * on the radio! They are used for internal accounting only.
   * The reason they are in this structure is that the AM interface
   * requires them to be part of the TOS_Msg that is passed to
   * send/receive operations.
   */
  uint16_t strength;
  uint8_t ack;
  uint16_t time;
} __attribute__ ((packed)) TOS_Msg;

enum {
  MSG_DATA_SIZE = offsetof(struct TOS_Msg, crc) + sizeof(uint16_t), /* 36 by default */
  DATA_LENGTH = TOSH_DATA_LENGTH,
  LENGTH_BYTE_NUMBER = offsetof(struct TOS_Msg, length) + 1
};

typedef TOS_Msg *TOS_MsgPtr;

#endif


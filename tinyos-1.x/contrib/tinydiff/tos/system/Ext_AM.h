#ifndef _EXT_AM_H_
#define _EXT_AM_H_

#include "AM.h"

enum {
  EXT_TOSH_DATA_LENGTH = TOSH_DATA_LENGTH - 2
};

typedef struct Ext_TOS_Msg
{
  /* The following fields are transmitted/received on the radio. */
  uint16_t addr;
  uint8_t type;
  uint8_t group;
  uint8_t length;
  uint16_t saddr;
  int8_t data[EXT_TOSH_DATA_LENGTH];
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
} __attribute__ ((packed)) Ext_TOS_Msg;

typedef Ext_TOS_Msg * Ext_TOS_MsgPtr;

#endif

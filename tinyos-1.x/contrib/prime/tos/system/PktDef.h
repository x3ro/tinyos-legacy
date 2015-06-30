
#ifndef __PACKDEF_H__
#define __PACKDEF_H__

#include "AM.h"

/* /////// enum {
  TRACKING_APP = 1,
  ECMM_APP = 2,
  EMMM_APP = 3,  
  GF_ROUTING = 4,
  };*/

enum {
#ifndef  __ENVIRO_H__
  MSG_MIR = 251,
  MSG_CONTROL = 252,
#endif

  MSG_PEEKER = 254,
};

  typedef struct
  {
    /* The following fields are transmitted/received on the radio. */
    uint16_t addr;
    uint8_t type;
    uint8_t group;
    uint8_t length;

    /* VERT specific */
    uint16_t nSrc;
    char cSeq;

    int8_t data[TOSH_DATA_LENGTH - 3];
    uint16_t crc;

    /* The following fields are not actually transmitted or received
     * on the radio! They are used for internal accounting only.
     * The reason they are in this structure is that the AM interface
     * requires them to be part of the Cell that is passed to
     * send/receive operations.
     */
    uint16_t strength;
    uint8_t ack;
    uint16_t time;
  } Cell;

  typedef Cell * CellPtr;

#endif

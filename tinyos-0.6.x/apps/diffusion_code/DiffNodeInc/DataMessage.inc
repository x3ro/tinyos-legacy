#ifndef _DATAMESSAGE_INC_
#define _DATAMESSAGE_INC_

#include <inttypes.h>
#include "defs.h"

typedef struct
{
	uint8_t type;
	uint8_t x, y;
	uint32_t orgSeqNum;
	uint8_t hopsToSrc;
	uint8_t codeId;
	uint8_t minRange;
	uint8_t maxRange;
	uint16_t data;
	uint16_t sender;
}__attribute__ ((packed)) DataMessage;

#endif

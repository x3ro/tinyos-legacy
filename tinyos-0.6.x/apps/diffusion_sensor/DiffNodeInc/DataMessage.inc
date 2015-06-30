#ifndef _DATAMESSAGE_INC_
#define _DATAMESSAGE_INC_

#include "defs.h"

typedef struct
{
	uint8_t ttl;						// Network-level TTL
										// Should be part of the TOS Message
	uint8_t type;
	uint8_t x, y;
	uint32_t orgSeqNum;
	uint8_t hopsToSrc;
	uint8_t data;
	uint16_t sender;
}__attribute__ ((packed)) DataMessage;

#endif

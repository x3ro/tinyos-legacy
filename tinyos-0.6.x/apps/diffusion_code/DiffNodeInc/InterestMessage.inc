#ifndef INTERESTMESSAGE_INC
#define INTERESTMESSAGE_INC

#include <inttypes.h>
#include "defs.h"

typedef struct
{

	uint8_t type;
	uint8_t x1, y1, x2, y2;
	uint8_t codeId;
	uint8_t minRange;
	uint8_t maxRange;
	uint8_t interval;
	uint8_t expiration;
	uint16_t sender;
	// uint16_t seqNum; // XXX this should be removed!
}__attribute__ ((packed)) InterestMessage;

#endif


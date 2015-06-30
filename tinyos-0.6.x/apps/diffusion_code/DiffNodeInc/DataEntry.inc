#ifndef _DATAENTRY_INC_
#define _DATAENTRY_INC_

#ifndef NULL
#define NULL (void*)0
#endif

#include "defs.h"
#include <inttypes.h>

typedef struct
{
	uint8_t x, y;
	uint8_t codeId;
	uint8_t frag;
	uint32_t orgSeqNum;
	uint8_t hopsToSrc;
	uint8_t prevHop;
} DataEntry;


void DataEntryInit(DataEntry* this, 
			uint8_t x, uint8_t y, uint8_t codeId,
			uint8_t frag, uint32_t orgSeqNum,
			uint8_t hopsToSrc, uint8_t prevHop);



#endif

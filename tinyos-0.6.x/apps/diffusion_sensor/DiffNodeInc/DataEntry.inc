#ifndef _DATAENTRY_INC_
#define _DATAENTRY_INC_

#include "defs.h"

typedef struct
{
	uint8_t x, y;
	uint8_t type;
	uint32_t orgSeqNum;
	uint16_t hopsToSrc;
	uint16_t prevHop;
	uint8_t data;
}
DataEntry;


void DataEntryInit(DataEntry* this, 
		   uint8_t x, uint8_t y, uint8_t type, uint32_t orgSeqNum,
		   uint8_t hopsToSrc, uint8_t prevHop, uint8_t data);



#endif

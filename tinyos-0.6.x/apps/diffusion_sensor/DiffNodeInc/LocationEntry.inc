#ifndef __LOCATIONENTRY_INC_
#define __LOCATIONENTRY_INC_

#include "defs.h"

typedef struct
{
	uint8_t x1, y1, x2, y2;
	uint8_t refCnt;
}
LocationEntry;

void LocationEntryInit(LocationEntry *this, 
		       uint8_t x1, uint8_t y1,
		       uint8_t x2, uint8_t y2);

char LocationEntryDoesContain(LocationEntry* this, uint8_t x, uint8_t y );

char LocationEntryIsFree(LocationEntry *this);
void LocationEntryFree(LocationEntry *this);

#endif




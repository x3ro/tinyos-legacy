#ifndef __LOCATIONENTRY_INC_
#define __LOCATIONENTRY_INC_

#include "defs.h"

#ifndef NULL
#define NULL (void*)0
#endif

typedef struct
{
	unsigned char x1, y1, x2, y2;
	unsigned char refCnt;
}
LocationEntry;

void LocationEntryInit(LocationEntry *this, 
		       unsigned char x1, unsigned char y1,
		       unsigned char x2, unsigned char y2);

char LocationEntryDoesContain( LocationEntry* this, unsigned char x, unsigned char y );

char LocationEntryIsFree(LocationEntry *this);
void LocationEntryFree(LocationEntry *this);

#endif




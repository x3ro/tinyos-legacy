#ifndef __INTERESTENTRY_INC_
#define __INTERESTENTRY_INC_


#include "defs.h"

#ifndef NULL
#define NULL (void*)0
#endif



typedef struct
{
  unsigned char type;

  // number of gradient references to this interest entry.
  unsigned char refCnt;
}
InterestEntry;

void InterestEntryInit(InterestEntry *this, unsigned char type);
void InterestEntryFree(InterestEntry *this);
char InterestEntryIsFree(InterestEntry *this);

#endif

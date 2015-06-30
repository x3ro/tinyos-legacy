#ifndef __INTERESTENTRY_INC_
#define __INTERESTENTRY_INC_

#include "defs.h"

typedef struct
{
  uint8_t type;

  // number of gradient references to this interest entry.
  uint8_t refCnt;
}
InterestEntry;

void InterestEntryInit(InterestEntry *this, uint8_t type);
void InterestEntryFree(InterestEntry *this);
char InterestEntryIsFree(InterestEntry *this);

#endif

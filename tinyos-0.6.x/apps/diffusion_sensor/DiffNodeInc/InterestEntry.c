#include "InterestEntry.inc"

void InterestEntryInit(InterestEntry* this, unsigned char type)
{
  this->type = type;
  this->refCnt = 0;
}

void InterestEntryFree(InterestEntry *this) {
    this->refCnt = 0;
}

char InterestEntryIsFree(InterestEntry *this) {
  return (this->refCnt == 0);
}

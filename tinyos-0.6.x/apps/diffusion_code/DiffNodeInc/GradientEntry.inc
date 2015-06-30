#ifndef __GRADIENTENTRY_INC_
#define __GRADIENTENTRY_INC_

#ifndef NULL
#define NULL (void*)0
#endif

#include "defs.h"
#include "InterestEntry.inc"
#include "LocationEntry.inc"
#include "CodeEntry.inc"

typedef struct
{
  unsigned char type;

  InterestEntry* interestRef;
  LocationEntry* locationRef;
	CodeEntry *codeRef;

  unsigned char expiration;
  unsigned char interval;
  unsigned char curInterval;

  // Since data is broadcast
  // we don't need this.
  //unsigned char destAddr;
}
GradientEntry;


void GradientEntryInit(GradientEntry* gradref, InterestEntry* intref,
LocationEntry* locref, CodeEntry *coderef,
			unsigned char interval, unsigned char expiration);

void GradientEntryFree(GradientEntry* gradref);
char GradientEntryIsFree(GradientEntry* gradref);

#endif




#ifndef __DIFFTABLE_INC_
#define __DIFFTABLE_INC_

#include "defs.h"

#include "InterestEntry.inc"
#include "LocationEntry.inc"
#include "GradientEntry.inc"
#include "DataEntry.inc"

extern InterestEntry interestTable[];
extern LocationEntry locationTable[];
extern GradientEntry gradientTable[];
extern DataEntry cache[];

void diffTableInit(void);

GradientEntry* findGradient2(InterestEntry* curInt, LocationEntry* curLoc );
GradientEntry* findGradient3(uint8_t type, uint8_t x, uint8_t y);
LocationEntry* findLocation(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2);
InterestEntry* findInterest(uint8_t type);
void expireGradients();
InterestEntry* findFreeInterestEntry(void);
LocationEntry* findFreeLocationEntry(void);
GradientEntry* findFreeGradientEntry(void);
GradientEntry* addGradient(InterestEntry* curInt, LocationEntry* curLoc, 
			   uint8_t interval, uint8_t expiration, uint8_t range);
void removeGradient(GradientEntry* curGrad);


#endif

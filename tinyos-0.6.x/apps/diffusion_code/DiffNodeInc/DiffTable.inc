#ifndef __DIFFTABLE_INC_
#define __DIFFTABLE_INC_

#ifndef NULL
#define NULL (void*)0
#endif


#include "defs.h"

#include "InterestEntry.inc"
#include "LocationEntry.inc"
#include "GradientEntry.inc"
#include "DataEntry.inc"
#include "CodeEntry.inc"

#ifndef NULL
#define NULL (void*)0
#endif

extern InterestEntry interestTable[];
extern LocationEntry locationTable[];
extern GradientEntry gradientTable[];
extern DataEntry cache[];

void diffTableInit(void);

GradientEntry* findGradient2( InterestEntry* curInt, LocationEntry* curLoc );
GradientEntry* findGradient3(unsigned char type, unsigned char x, unsigned char y);
LocationEntry* findLocation(unsigned char x1, unsigned char y1, unsigned char x2, unsigned char y2);
InterestEntry* findInterest(unsigned char type);
void expireGradients(void /*unsigned char x, unsigned char y*/);
InterestEntry* findFreeInterestEntry(void);
LocationEntry* findFreeLocationEntry(void);
GradientEntry* findFreeGradientEntry(void);
GradientEntry* addGradient(InterestEntry* curInt, LocationEntry* curLoc, 
			  	CodeEntry *curCode,  
				unsigned char interval, unsigned char expiration);
void removeGradient(GradientEntry* curGrad /*, unsigned char x, unsigned char y*/);



CodeEntry* findCode(uint8_t codeId, uint8_t minRange, uint8_t maxRange);
CodeEntry *findFreeCodeEntry(); 
GradientEntry* findGradientCode(InterestEntry *curInt, LocationEntry *curLoc,
CodeEntry *curCode); 
GradientEntry* findGradient3Code(uint8_t type, uint8_t x, uint8_t y,
uint8_t codeId, uint8_t minRange, uint8_t maxRange);  

#endif











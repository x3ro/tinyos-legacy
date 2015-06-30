#ifndef __GRADIENTENTRY_INC_
#define __GRADIENTENTRY_INC_

#include "defs.h"
#include "InterestEntry.inc"
#include "LocationEntry.inc"

typedef struct
{
unsigned char type;

	// interest-dependent fields
	InterestEntry* interestRef;		// Reference to the interest 
									// to create this gradient
	uint8_t range;					// range of gradient, in hops			
	uint8_t expiration;				// expiration time, in DIFF_RATE*secs
	uint8_t interval;				
	uint8_t curInterval;

	// Filter-dependent fields
	LocationEntry* locationRef;		// Reference to the location

}
GradientEntry;


void GradientEntryInit(GradientEntry* gradref, 
			InterestEntry* intref, LocationEntry* locref,
			uint8_t interval, uint8_t expiration, uint8_t range);

void GradientEntryFree(GradientEntry* gradref);
char GradientEntryIsFree(GradientEntry* gradref);

#endif




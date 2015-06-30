/* Header file for the interest cacheMatching rules implementation.
 * Authors: Moshe Golan, Mohan Mysore
*/ 
#ifndef __MATCHINGRULES_INC_
#define __MATCHINGRULES_INC_

#include "DataStructures.h"

typedef enum  {
  NO_MATCH = 0,
  MATCH = 1
} MATCH_STATUS;

result_t copyAttribs(Attribute *to, uint8_t toMaxSize, 
		     Attribute *from, uint8_t numFrom);
BOOL areAttribsEqual(Attribute a, Attribute b);
SEARCH_STATUS foundAttribInArray(Attribute attrib, 
				   AttributePtr array, uint8_t numAttrs);
BOOL areAttribArraysEquiv(AttributePtr attributes1, uint8_t numAttrs1,
			AttributePtr attributes2, uint8_t numAttrs2);


// ================ Functions Prototypes =======================

MATCH_STATUS attMatch( Attribute  * att1, Attribute  * att2  );
// Post: Returns true if attributes match as defined in the matching rules

MATCH_STATUS attInterestMatch( Attribute  * att1, Attribute  * att2  );
// Post: Returns true if attribute of one intrest match
//       the attributes of another interest with the exepthion that 
//       interval can change.

MATCH_STATUS dataMatch( InterestMessage  * interest, DataMessage * data  );
// Post: Returns true if data matches an interest as defined in the matching rules

#endif



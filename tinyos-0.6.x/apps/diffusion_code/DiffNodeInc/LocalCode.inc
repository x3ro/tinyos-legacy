#ifndef __LOCALCODE_INC_
#define __LOCALCODE_INC_

#include "defs.h"

#ifndef NULL
#define NULL (void*)0
#endif

#include <inttypes.h>

struct Code {
	uint8_t ID;
	uint8_t frag[MAX_FRAGS];
	uint8_t is_full;
};


/* Initialize the Local code table
 * returns codeId or 0 on failure
*/
uint8_t LocalCodeInit(struct Code * codeTable, uint8_t codeId,
							uint8_t minRange, uint8_t maxRange);	


#endif

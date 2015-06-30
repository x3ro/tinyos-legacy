#ifndef __CODEENTRY_INC_
#define __CODEENTRY_INC_

#include <inttypes.h>
#include "defs.h"

#ifndef NULL
#define NULL (void*)0
#endif

typedef struct
{
	uint8_t codeId;
	uint8_t minRange;
	uint8_t maxRange;
	uint8_t refCnt;
}
CodeEntry;

void CodeEntryInit(CodeEntry *this, uint8_t codeId, 
						uint8_t minRange, uint8_t maxRange);

char CodeEntryContains(CodeEntry* this, uint8_t codeId, 
						uint8_t minRange, uint8_t maxRange);

char CodeEntryIsFree(CodeEntry *this);
void CodeEntryFree(CodeEntry *this);


#endif

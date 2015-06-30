#ifndef _DATACACHE_INC_
#define _DATACACHE_INC_

#include "defs.h"
#include "DataEntry.inc"

#ifndef NULL
#define NULL (void*)0
#endif



void DataCacheInit(void);
DataEntry* findExactData(unsigned char x, unsigned char y, uint8_t codeId, 
					uint8_t frag);
DataEntry* findDataWithinRange(uint8_t x, uint8_t y, uint8_t codeId,
					uint8_t minRange, uint8_t maxRange);
DataEntry* findDataSource(uint8_t codeId, 
		uint8_t minRange, uint8_t maxRange);
DataEntry* findFreeDataEntry();

#endif

#ifndef _DATACACHE_INC_
#define _DATACACHE_INC_

#include "defs.h"
#include "DataEntry.inc"

void DataCacheInit(void);
DataEntry *findDataByLocation(uint8_t x, uint8_t y);
DataEntry *findDataByThreshold(uint16_t threshold, uint8_t operator);
DataEntry *findDataByType(uint8_t type);
DataEntry *findFreeDataEntry();

#endif

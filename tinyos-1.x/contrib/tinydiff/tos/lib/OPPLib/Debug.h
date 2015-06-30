// Debuging file header file
#ifndef _OPP_DEBUG_H_
#define _OPP_DEBUG_H_


#include "DataStructures.h"
#include "DataCache.h"
#include "InterestCache.h"

// Print Attribute
void prAtt(uint32_t dbgLevel, BOOL includeHeader, Attribute *  att, uint8_t num);

// Print AttributeArray
void prAttArray(uint32_t dbgLevel, BOOL includeHeader, Attribute *  att, uint8_t AttNum);

// Print Interest Message
void prIntMes(uint32_t dbgLevel, BOOL includeHeader, InterestMessage * m);

// Print Data Message
void prDataMes(uint32_t dbgLevel, BOOL includeHeader, DataMessage * m);

// Print Data Cache
void prDataCache(uint32_t dbgLevel, BOOL includeHeader, DataCache * dc);

// Print Gradient Entry
void prGrad(uint32_t dbgLevel, BOOL includeHeader, InterestGradient * G, int num);

// Print Interest Entry
void prIntEnt(uint32_t dbgLevel, BOOL includeHeader, InterestEntry * ie);

// Print Interest Cache
void prIntCache(uint32_t dbgLevel, BOOL includeHeader, InterestCache * ic);

#endif






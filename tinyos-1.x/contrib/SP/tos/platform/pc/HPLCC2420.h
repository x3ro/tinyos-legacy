#ifndef __HPLCC2420_H
#define __HPLCC2420_H

#include "SPSimDbg.h"

//// TODO Can I get a real assert()? I grepped the other .nc files but didn't
//// find assert!
//#define assert(w) ((!(w)) ? (*((int*) 0) = 1) : 0)
//#define fail(reason) assert(FALSE && reason)

void* alloc(size_t size);
double symbolsToSecondS(double syms);
uint64_t secondsToTicks(double secs);
uint64_t symbolsToTicks(double syms);
double jiffiesToSeconds(double jiffies);
uint64_t jiffiesToTicks(double jiffies);
double secondsToJiffies(double seconds);
double ticksToSeconds(uint64_t ticks);
double ticksToJiffies(uint64_t ticks);
uint32_t getCurrentTimeInJiffies();

#endif // __HPLCC2420_H

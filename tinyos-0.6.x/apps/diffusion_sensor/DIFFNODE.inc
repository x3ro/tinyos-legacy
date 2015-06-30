#ifndef DIFFNODE_INC
#define DIFFNODE_INC

#include "DiffNodeInc/defs.h"
#include "DiffNodeInc/InterestEntry.inc"

void frwdData(TOS_MsgPtr datMsg);
void senseData(void);
uint8_t produceData(InterestEntry* curInt);

#define CLOCK_DIV 16
#define DIFF_RATE CLOCK_DIV/8	// the rate at which diffusion ticks
								// value in seconds

// Message types
#define INTEREST_TYPE 200
#define DATA_TYPE     201
#define ID_TYPE       211
#define RESET_TYPE    212

// Interest types
#define NSTD  1			// special 'nested' type
#define PHOTO 2 
#define TEMP  3

#endif

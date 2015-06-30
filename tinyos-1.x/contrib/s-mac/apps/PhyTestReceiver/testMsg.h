// message format for testing the physical layer -- PhyRadio

#ifndef TEST_MSG
#define TEST_MSG

// include physical layer header defination
#include "PhyRadioMsg.h"

typedef struct {
	PhyHeader hdr;   // include lower-layer header first
	uint8_t seqNo;
} AppHeader;
/* AppHeader should be the same as the sender */

typedef struct {
	AppHeader hdr;
	char data[20];
	int16_t crc;   // crc must be the last field -- required by PhyRadio
} AppPkt;

#endif

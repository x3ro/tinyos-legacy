// message format for testing the physical layer -- PhyRadio

#ifndef TEST_MSG
#define TEST_MSG

// include physical layer header defination
#include "PhyRadioMsg.h"

typedef struct {
	PhyHeader hdr;   // include lower-layer header first
	unsigned char seqNo;
} AppHeader;

#define PAYLOAD_LEN (PHY_MAX_PKT_LEN - sizeof(AppHeader) - 2)

typedef struct {
	AppHeader hdr;
	char data[PAYLOAD_LEN];
	short crc;   // crc must be the last field -- required by PhyRadio
} AppPkt;

#endif

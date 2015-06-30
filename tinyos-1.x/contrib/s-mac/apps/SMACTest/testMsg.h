// This file defines the packet format for the application

#ifndef TEST_MSG
#define TEST_MSG

// Include S-MAC header defination

#include "SMACMsg.h"

typedef struct {
	MACHeader hdr;   // include lower-layer header first
	uint8_t numTxBcast; // number of transmitted broadcast packets
    uint8_t numTxUcast; // number of transmitted unicast packets
} AppHeader;

#define APP_PAYLOAD_LEN (PHY_MAX_PKT_LEN - sizeof(AppHeader) - 2)

typedef struct {
	AppHeader hdr;
	char data[APP_PAYLOAD_LEN];
	int16_t crc;   // crc must be the last field -- required by PhyRadio
} AppPkt;

#endif

#ifndef DIFFNODE_INC
#define DIFFNODE_INC

#ifndef NULL
#define NULL (void*)0
#endif

#include "DiffNodeInc/defs.h"
#include "DiffNodeInc/GradientEntry.inc"

void frwdData(TOS_MsgPtr datMsg);
void checkData(void);
uint8_t produceData(GradientEntry * curGrad, uint8_t GradId);

#define CLOCK_DIV 16
#define DIFF_RATE CLOCK_DIV/8

// Message types
#define INTEREST_TYPE 200
#define DATA_TYPE     201
#define ID_TYPE       211
#define RESET_TYPE    212
#define DIFFNODE_DUMP 55

// ADC types
#define PHOTO	1
#define TEMP	2
#define CODE	3		// Not an ADC type, but a different data type
						// nonetheless


struct dump_msg {
	uint8_t explint_sent_H;			// Number of exploratory interests sent
	uint8_t explint_sent_L;			//
	uint8_t reinfs_sent_H;			// Number of reinforcements sent
	uint8_t reinfs_sent_L;
	uint8_t local_data_sent_H;		// number of local packets sent
	uint8_t local_data_sent_L;		// i.e. not forwarded packets
	uint8_t total_data_sent_H;		// total number of packets sent
	uint8_t total_data_sent_L;			
	uint8_t explint_rcvd_H;			// exploratory interests received
	uint8_t explint_rcvd_L;
	uint8_t reinfs_rcvd_H;			// reinforcements received 
	uint8_t reinfs_rcvd_L;
	uint8_t datapkts_rcvd_H;		// Number of data packets received
	uint8_t datapkts_rcvd_L;
	uint8_t rCodeId;				// Requested code Id
	uint8_t CodeTable[MAX_FRAGS];	// Frag table for specified code Id
	uint8_t rMinRange;				// Min range requested
	uint8_t rMaxRange;				// Max range requested
	uint8_t lMinRange;				// Local min range
	uint8_t lMaxRange;				// Local max range
	uint8_t frags_received;			// total frags received for codeId
	uint8_t num_sources;			// number of different sources
									// of data packets (NOT IMPLEMENTED)
}; // MAX_FRAGS+21
	

#endif





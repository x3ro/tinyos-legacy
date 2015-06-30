/*
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu	
 * @modified 06/30/03
 */

#include "AM.h"


typedef struct FloodRoutingSyncMsg
{
	uint8_t appId;		// the application id, distinguishes different applications
	uint16_t location;	// see RoutingPolicy
	uint32_t timeStamp;	// TIMING extension of routing, Timestamping module will put here
				// local time of sender when sending a routing message

#ifdef SIMULATE_MULTIHOP	// this is used to simulate multiple hops
	uint8_t nodeId;
#endif

	uint8_t data[0];	// actual packets, max length is FLOODROUTING_MAXDATA
} FloodRoutingSyncMsg;

enum
{
	AM_FLOODROUTINGSYNC = 0x83, //TOSMSG AM_HANDLER for routing-sync msg
#ifdef RITS_TIMESTAMP_LENGTH
	//FloodRoutingSync is implementation of the RITS protocol, RITS_TS_LENGTH may define size of
	//timestamps that is used
	TIMESTAMP_LENGTH = RITS_TIMESTAMP_LENGTH,
#else
	TIMESTAMP_LENGTH = 3,
#endif
	FLOODROUTINGSYNC_HEADER = sizeof(FloodRoutingSyncMsg),  //size of a header required for the FLoodRouting
								//size of appId and location bytes
								// remember sizeof( uint8_t data[0] ) == 0 
	FLOODROUTINGSYNC_MAXDATA = //how many bytes are available in TOSMSG for data packets
		TOSH_DATA_LENGTH - FLOODROUTINGSYNC_HEADER,
};


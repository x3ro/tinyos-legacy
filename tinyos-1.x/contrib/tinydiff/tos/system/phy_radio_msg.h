/* This file defines the header fields of phy_radio that will be
 * added before the payload of each packet.
 * The upper layer (MAC) that use phy_radio should include this header
 * as its first field and CRC as its last field in each packet it 
 * declares (see smac_msg.h for example).
 * 
 * Authors: Wei Ye
*/

#ifndef PHY_MSG
#define PHY_MSG

#include <inttypes.h>

// Maximum packet length -- including headers of all layers
// Each application can override the default max length in Makefile
// Maximum allowable value is 250
#ifndef MAX_PKT_LEN
#define MAX_PKT_LEN 100
#endif

// Physical-layer header to be put before data payload
typedef struct {
	unsigned char length; // length of entire packet
} PhyHeader;


// packet information to be recorded by physical layer
typedef struct {
	short strength;
	uint32_t timestamp;
} PhyPktInfo;

// Physical layer packet buffer (for receiving packets)
// Sending buffer should be provided by the top-level application

#define MAX_PHY_PAYLOAD (MAX_PKT_LEN - sizeof(PhyHeader) - 2)

typedef struct {
	PhyHeader hdr;
	char data[MAX_PHY_PAYLOAD];
	short crc;        // last field of a packet
	PhyPktInfo info;  // not part of a packet
} PhyPktBuf;

#endif  // PHY_MSG

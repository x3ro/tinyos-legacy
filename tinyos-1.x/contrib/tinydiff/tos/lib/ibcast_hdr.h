#ifndef __IBCAST_HDR_H__
#define __IBCAST_HDR_H__

#define SQN_GBAND	10
// Be liberal on the TTL: upon request from JR folks; reduce if required
#define MAX_TTL	6
#define IBCAST_GROUP 0x6d

// BCAST message structure
struct bcastmsg {
	uint16_t source;
	uint16_t seq;
	uint8_t ttl;
	uint8_t uid;
	uint8_t type;
} __attribute__((packed));



struct bcastcache {
	uint16_t source;
	uint16_t seq;
	uint8_t uid;
};

#endif

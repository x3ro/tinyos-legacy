#ifndef INTERESTMESSAGE_INC
#define INTERESTMESSAGE_INC

#include "defs.h"

typedef struct
{
	uint8_t ttl;					// network-level TTL. Should be in the
									// TOS message, not the data portion of
									// it
	uint8_t type;
	uint8_t x1, y1, x2, y2;
	uint8_t range;					// Range, or scope of interest, in hops
									// Used to set the original TTL
									// field of the data message
	uint8_t interval;
	uint8_t expiration;
	uint16_t sender;
}__attribute__ ((packed)) InterestMessage;

#endif


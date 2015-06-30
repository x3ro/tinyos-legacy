enum { AM_BEACON=10 };

  /* In the initial Tsync implementation, one aspect of the
     following structures is not fully implemented:  
     mote id's are only one byte (but coerced to 2 bytes 
     for these structures).  */

// Structure of the Beacon Message
typedef struct beaconMsg 
{
  uint16_t lowId;  // Id of Time originator
  uint16_t sndId;  // Id of Message Sender
  uint32_t sndClock; // timestamp of sender
  uint32_t GPSClock; // GPS clock of sender (if available)
  uint8_t nCount;  // size of sender's neighborhood
  uint8_t hops;    // # hops traveled from Time originator
} beaconMsg;

typedef beaconMsg * beaconMsgPtr;

#define NUM_NEIGHBORS 6
#define BOUND_DIAMETER 10 

// Structure of Neighbor Descriptor
typedef struct neighbor
{
  uint16_t id;	    // Id of neighbor
  uint16_t lowId;   // neighbor's opinion of root mote id
  uint8_t  hops;    // number of hops to root mote
  uint8_t  bCnt;    // bit mask of last 8 measured readings
                    // bCnt==0 => this is not a neighbor
} neighbor;

typedef neighbor * neighborPtr;


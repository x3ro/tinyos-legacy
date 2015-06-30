typedef struct BeaconPacketStruct {
  uint16_t source; // can be removed if we incorporat saddr in the TOS_Msg
  uint16_t seq;
  uint8_t incarnation; // to take care of mote reboots
  uint8_t numRecords;
  char data[0];
  // followed by pairs of [neighborId(2 bytes) - metric(2 bytes)]
} __attribute__ ((packed)) BeaconPacket;

#define SEQ_GT(a,b)     ((int16_t)((a) - (b)) > 0)
#define INC_BOUNDED(a,b) (((a) + 1) < (b) ? ((a) + 1) : (b))
#define SEQ_DIFF(a,b)	((int16_t)((a) - (b)))
#define SEQ_ABS_DIFF(a,b) (uint16_t)(SEQ_GT((a),(b)) ? SEQ_DIFF((a),(b)) : SEQ_DIFF((b),(a)))
#define MAX(a,b)	((a) > (b) ? (a) : (b))
#define MIN(a,b)	((a) < (b) ? (a) : (b))

enum {
  NB_AM_GROUP = 0x7d,  // can be changed if necessary later
  NB_MAX_PKT_SIZE = 27 // can be changed later if necessary... but 
		       // leaving it 27 for safety
};

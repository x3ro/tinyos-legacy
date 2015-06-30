// AM msg type
enum { AM_TIMESYNCMSG =37
};
// constant defined for sub_type field in TimeSyncMsg structure
enum {
    TIMESYNC_REQUEST=0,
	TIME_REQUEST = 1,
	TIME_RESPONSE =2
};

struct TimeSyncMsg {
    uint16_t source_addr;
    uint8_t  sub_type; // bits 7 for auto correction enable 
    uint8_t  source_status;  
    uint32_t timeH;
    uint32_t timeL;      
    uint8_t level; // time sync depth
    uint8_t phase;
};

// constants for source_status field of the TimeSync Structure
// A simple of efficient way is to set time master as status 0
// and other motes' source_status = hop_cnt 
enum {
	MASTER = 1, 
        SLAVE_SYNCED=2,
        SLAVE_UNSYNCED=0
}; 

/*
	// lower 3 bits indicate the server levels
	//  now master and slave is supported 
	//  don't know how to integrate with multihop routing protocol yet.
	STA_SERVER_MASK = 0x7, // lower 3 bit including master bit
	STA_SERVER_L1 = 0x01,
	STA_SERVER_L2 = 0x02,
	    //....
	STA_MASTER_MASK = 0x01, // bit 1 -- master if set
	STA_SLAVE_MASK = 0x10, //  bit 5
	STA_SYNC_MASK = 0x20,  // bit 6 -- synced if set
	STA_SKEW_MASK = 0x80  // bit 7 -- skew estimation enabled if set
} ;
*/


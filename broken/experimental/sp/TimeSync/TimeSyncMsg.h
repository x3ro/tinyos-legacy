// AM msg type
enum { AM_TIMESYNCMSG =37
};
// constant defined for type field in TimeSyncMsg structure
enum {
    TIMESYNC_REQUEST=0,
    TIMESYNC_ECHO_REQ=1,
    TIME_SYNC_ECHO_RSP=2,
	TIME_REQUEST = 3,
	TIME_RESPONSE =4
};

enum {
    UNIT_TICKS = 0,
    UNIT_RTC =1 
};

struct TimeSyncMsg {
    short source_addr;
    unsigned char type;
    // type 2 and 1 are for round trip time (RTT) estimation 
    // if there are other ways of extimate RTT, these 2 will be redundant
    unsigned char unit; // indicate the unit of time 
    unsigned long  timeH; // this can be either ticks at an agreed scale level
                          // or seconds since a chosen time
    uint16_t timeL;       // this can be milliseconds for absolute time
    int16_t  adjustment;
};

// constants for status field of the TimeSync Structure
enum {
    SERVER_L0 =  0x0, // master time server
    SERVER_L1 =  0x1, // level 1 time server 
    SERVER_L2 =  0x2, // level 2 time server 
    SERVER_L3 =  0x3  // level 3 time server 
} ;


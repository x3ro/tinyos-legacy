
// define default time sync interval
enum { 
    TX_DELAY =2806, // fixed transmit delay.
                    // This is a hadware dependent value. 
                    // the value defined here is for Mica with RFM TR1000 radio
    // define the amount of time to be adjusted at each clock interrupt
    TIME_OFFSET = 32,  // in unit of binary miocroseconds
    // if local time diffs from Master time over TIME_MAX_ERR, 
    // the local time should be reset instead of adjumented
    TIME_MAX_ERR = 0xFFFF,
    // define time sync interval 
    TIME_SYNC_INTERVAL = 0x3C00000  // 60 s. 
};



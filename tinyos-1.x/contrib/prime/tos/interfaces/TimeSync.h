
// define default time sync interval
enum { 
    // define the amount of time to be adjusted at each clock interrupt
    TIME_OFFSET = 32,  // in unit of binary milliseconds
    // if local time diffs from Master time over TIME_MAX_ERR, 
    // the local time should be reset instead of adjumented
    TIME_MAX_ERR = 32,  // ms
    // define time sync interval 
    TIME_SYNC_INTERVAL = 61440  // binary ms   
};



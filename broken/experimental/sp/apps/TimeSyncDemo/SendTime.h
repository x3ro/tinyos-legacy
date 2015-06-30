enum {
   SEND_TIME = 17,
   AM_TESTTIME =18,
   AM_TIMERESP =19};

struct TestTime {
   uint16_t source_addr;
};

struct TimeResp {
   uint16_t source_addr;
   uint32_t timeH; 
   uint32_t timeL;
//   uint16_t us; 
};

struct SendTime {
   uint16_t source_addr;
   uint32_t timeH;
   uint32_t timeL;
   uint32_t time;// time from master's time sync message
   uint32_t receiver_settime;
   uint16_t receiver_timestamp;
   uint16_t currentTime;
};


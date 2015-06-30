#ifndef REPORT_EVENT_H
#define REPORT_EVENT_H
enum {
  AM_EVENTREPORT = 158,  
};


enum {
  EVENT_INITIALIZED = 0,
  EVENT_SUBSCRIPTION_RCVD = 1,
  EVENT_NOTIFICATION_SENT = 2,
  EVENT_NOTIFICATION_RCVD = 3,
  EVENT_NO_MATCH = 4,
    // ...
};

typedef struct eventreport
{
  uint16_t sourceID;// TOS_LOCAL_ADDR
  uint16_t seqNum;  // increased for every message sent to PC
  uint8_t eventID;  // see enum above
  uint32_t delta;   // relative time (in 32khz jiffies) when event occured in the past,
                    // e.g. a delta of 100 means the event happened 3,051 ms ago.
                    // the timestamp is calculated and inserted just before the first byte 
                    // is transmitted via UART. given that the PC knows the
                    // propagation delay it can determine when the event happened, by
                    // subtracting delta and propagation delay from its local time, upon
                    // arrival of the first byte.
  uint16_t subscriberID; 
  uint16_t subscriptionID;   
} eventreport_t;
#endif

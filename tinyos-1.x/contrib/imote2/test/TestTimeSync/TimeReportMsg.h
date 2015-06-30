#ifndef TIMEREPORTMSG_H
#define TIMEREPORTMSG_H


typedef struct TimeReportMsg{
    uint16_t    rootID;
    uint16_t    nodeID;
    uint16_t    msgID;
    uint32_t    globalClock;
    uint32_t    localClock;
    float       skew;
    uint8_t     is_synced;
    uint8_t     seqNum;
    uint8_t     numEntries;
    uint8_t     dummy;
    uint16_t    syncPeriod;
    uint8_t     globalClockHigh;
    uint8_t     localClockHigh;
} __attribute((packed)) TimeReportMsg;


#endif

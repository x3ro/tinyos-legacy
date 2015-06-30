#ifndef H_Ditto_h
#define H_Ditto_h

enum {
  AM_PLAYRECORDDATAMSG = 31,
  AM_PLAYRECORDREQUESTMSG = 32,
};

#define FLOOR_CONST(n,d) (((n)/(d))*(d))

enum {
  NUM_SAMPLES = FLOOR_CONST(7800,16), //save space for the stack
  SAMPLING_RATE = 8192,

  SHARE_SAMPLES_PER_MSG = 32,
  SHARE_FLAG_NO_VERSION = 0x01,
  SHARE_FLAG_REPORT_UART = 0x02,
  SHARE_FLAG_COMPLETE_VERSION = 0x04,
};

typedef struct PlayRecordDataMsg {
  uint16_t addrSender;
  uint16_t sampleBegin;
  uint16_t versionToken;
  uint8_t version;
  uint8_t flags;
  uint8_t samples[0];
} PlayRecordDataMsg_t;

typedef struct PlayRecordRequestMsg {
  uint16_t addrRequester;
  uint16_t sampleBegin;
  uint16_t sampleEnd;
  uint16_t versionToken;
  uint8_t version;
  uint8_t flags;
} PlayRecordRequestMsg_t;

#endif//H_Ditto_h

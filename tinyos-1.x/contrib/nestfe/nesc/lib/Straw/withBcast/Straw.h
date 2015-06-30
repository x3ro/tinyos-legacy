#include "AM.h"

enum {
  AM_STRAWCMDMSG = 246,
  AM_STRAWREPLYMSG = 247,
  AM_STRAWUARTMSG = 248,
};
enum {
  STRAW_IDLE_STATE = 0,

  STRAW_SUB_IDLE = 0,
  STRAW_SUB_FIRST = 1,
  STRAW_SUB_PROC = 2,
  STRAW_SUB_FNSHD = 3,

  STRAW_BFFR_EMPTY = 0,
  STRAW_BFFR_READING = 1,
  STRAW_BFFR_READDONE = 2,
  STRAW_BFFR_SENDING = 3,
};
enum {
  STRAW_TYPE_SHIFT = 10,
};
enum {
  STRAW_NETWORK_INFO = 1,
  STRAW_TRANSFER_DATA = 6,
  STRAW_RANDOM_READ = 7,

  DIVERGE_HEADER_LENGTH = 2,
  STRAWCMDMSG_LENGTH = TOSH_DATA_LENGTH - DIVERGE_HEADER_LENGTH,
  
  STRAWCMDMSG_HEADER_LENGTH = 2,
  STRAWCMDMSG_ARG_LENGTH = STRAWCMDMSG_LENGTH - STRAWCMDMSG_HEADER_LENGTH,
  MAX_RANDOM_READ_SEQNO_SIZE = STRAWCMDMSG_ARG_LENGTH / 2,
};
enum {
  STRAW_NETWORK_INFO_REPLY = 1,
  STRAW_DATA_REPLY = 8,

  CONVERGE_HEADER_LENGTH = 6,
  STRAWREPLYMSG_LENGTH = TOSH_DATA_LENGTH - CONVERGE_HEADER_LENGTH,
  
  STRAWREPLYMSG_HEADER_LENGTH = 0,
  STRAWREPLYMSG_ARG_LENGTH = STRAWREPLYMSG_LENGTH - STRAWREPLYMSG_HEADER_LENGTH,
  MAX_DATA_REPLY_DATA_SIZE = STRAWREPLYMSG_ARG_LENGTH - 2,
};

typedef struct {
  uint16_t type;
} __attribute__ ((packed)) CmnDummy;

typedef struct {
  uint16_t type;
  uint16_t uartOnlyDelay;
  uint16_t uartDelay;
  uint16_t radioDelay;
  uint8_t toUART;
} __attribute__ ((packed)) NetworkInfo;

typedef struct {
  uint16_t type;
  uint32_t start;
  uint32_t size;
  uint8_t toUART;
} __attribute__ ((packed)) TransferData;

typedef struct {
  uint16_t seqNo[MAX_RANDOM_READ_SEQNO_SIZE];
} __attribute__ ((packed)) RandomRead;

typedef struct StrawCmdMsg {
  uint16_t dest;
  union {
    CmnDummy cd;
    NetworkInfo ni;
    TransferData td;
    RandomRead rr;
  } arg;
} __attribute__ ((packed)) StrawCmdMsg;



typedef struct {
  uint16_t type;
} __attribute__ ((packed)) CmnDummyReply;

typedef struct {
  uint16_t type;
  uint16_t parent;
  uint8_t depth;
  uint8_t occupancy;
  uint8_t quality;
} __attribute__ ((packed)) NetworkInfoReply;

typedef struct {
  uint16_t seqNo;
  uint8_t data[MAX_DATA_REPLY_DATA_SIZE];
} __attribute__ ((packed)) DataReply;

typedef struct StrawReplyMsg {
  union {
    CmnDummyReply cdr;
    NetworkInfoReply nir;
    DataReply dr;
  } arg;
} StrawReplyMsg;

typedef struct StrawUARTMsg {
  StrawReplyMsg dummy;
}  StrawUARTMsg;


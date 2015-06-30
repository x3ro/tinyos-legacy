
typedef struct MyPCCmdMsg {
uint16_t seqNo;
uint16_t source;
uint16_t dest;
uint16_t cmdcode;
uint16_t number;
uint16_t duration;
} MyPCCmdMsg;

enum {
AM_MYPCCMDMSG = 0xce,
};


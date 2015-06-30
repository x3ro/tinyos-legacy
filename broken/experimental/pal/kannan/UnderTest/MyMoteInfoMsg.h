enum {
AM_MYMOTEINFOMSG = 0xbe,
};

enum {
NUM_INFO_PER_MSG = 4, // This gives the max number of Info Packets we can stuff in a TOS_Msg packet
MAX_NUM_MSGS = 20, // I got this number from "TelosRssi.nc" under contrib
BYTES_PER_RECORD = 6, // This is the size of each record (in bytes)
};

typedef struct MyMoteInfoMsg {
uint16_t seqNo[NUM_INFO_PER_MSG];
uint16_t strength[NUM_INFO_PER_MSG];
uint16_t lqi[NUM_INFO_PER_MSG];
} MyMoteInfoMsg;



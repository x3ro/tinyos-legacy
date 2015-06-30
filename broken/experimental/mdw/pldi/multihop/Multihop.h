
int INITIAL_TIMER_RATE = 1000;
uint8_t EMPTY = 0xff;
uint8_t INITIAL_HOPCOUNT = 64;
double PARENT_LINK_QUALITY_ALPHA = 0.8;

typedef struct MultihopMsg {
  uint8_t type;
  uint16_t sourceaddr;
  uint16_t originaddr;
  uint16_t parentaddr;
  uint8_t seqno;
  uint8_t hopcount;
  uint8_t parent_link_quality;
  uint32_t user_data;
  uint32_t debug_code;
} MultihopMsg;

enum {
  MULTIHOP_TYPE_USERDATA = 0,
  MULTIHOP_TYPE_ROOTBEACON = 1,
}; 

enum {
  AM_MULTIHOPMSG = 175
};

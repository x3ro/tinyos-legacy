

int INITIAL_TIMER_RATE = 1000;
int FOCUS_TIMER_RATE = 200;
int FOCUS_NOTME_TIMER_RATE = 3000;
uint8_t EMPTY = 0xff;
uint8_t INITIAL_HOPCOUNT = 64;
double PARENT_LINK_QUALITY_ALPHA = 0.8;
uint16_t BASE_ADDRESS = 0x007e;

typedef struct SurgeMsg {
  uint8_t type;
  uint16_t sourceaddr;
  uint16_t originaddr;
  uint16_t parentaddr;
  uint8_t seqno;
  uint8_t hopcount;
  union {
    // For SURGE_TYPE_SENSORREADING
    struct {
      uint16_t reading;
      uint8_t parent_link_quality;
    } reading_args;
    // FOR SURGE_TYPE_SETRATE
    uint32_t newrate;
    // FOR SURE_TYPE_FOCUS
    uint16_t focusaddr;
  } args;
  uint32_t debug_code;
} __attribute__ ((packed)) SurgeMsg;

enum {
  SURGE_TYPE_SENSORREADING = 0,
  SURGE_TYPE_ROOTBEACON = 1,
  SURGE_TYPE_SETRATE = 2,
  SURGE_TYPE_SLEEP = 3,
  SURGE_TYPE_WAKEUP = 4,
  SURGE_TYPE_FOCUS = 5,
  SURGE_TYPE_UNFOCUS = 6
}; 

enum {
  AM_SURGEMSG = 17
};



int INITIAL_TIMER_RATE = 1000;
int FOCUS_TIMER_RATE = 200;
int FOCUS_NOTME_TIMER_RATE = 3000;
uint8_t EMPTY = 0xff;
uint8_t INITIAL_HOPCOUNT = 64;
uint16_t BASE_ADDRESS = 0x007e;
 
char debugbuf[256];

void UARTPutChar(char c) {
  
  if (c == '\n')
    UARTPutChar('\r');
  loop_until_bit_is_set(USR, UDRE);
  outb(UDR,c);
}

void writedebug() {
  int i = 0;
  outp(12,UBRR);
  while (debugbuf[i] != '\n') 
    UARTPutChar(debugbuf[i++]);
  UARTPutChar('\n');
  
}

#ifdef NDEBUG
#define Surgedbg(__x,__args...)
#else
#define Surgedbg(__x,__args...) { \
	char bStatus;			\
	bStatus=bit_is_set(SREG,7);	\
	cli();				\
	sprintf(debugbuf,__args);	\
	writedebug();			\
	if (bStatus) sei();		\
	}
#endif

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
      uint8_t nbrs[4];
      uint8_t q[4];
    } reading_args;
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

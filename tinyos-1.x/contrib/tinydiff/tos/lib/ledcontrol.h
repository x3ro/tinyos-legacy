#define DEFAULT_TTL 6

typedef struct ledControlStruct {
  uint16_t source;
  uint16_t reqId;
  uint8_t ttl;
  uint8_t ledState;
} __attribute__((packed)) LedControlMsg;


// minimum resend time should be bigger than 0 otherwise timer won't fired
// VC_QUEUE_SIZE MUST be greater than number of application you are using
enum {
  // WARNING
  VC_MINIMUM_RESEND_TIME = 125,
  VC_QUEUESIZE = 11,
  VC_BITMAP_SIZE = 256
};
typedef struct VirtualCommHeader {
  uint8_t source;
  int8_t seqnum;
} VirtualCommHeader;



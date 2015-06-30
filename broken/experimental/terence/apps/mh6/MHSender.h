
#define MHSENDER_DATA_QUEUE_SIZE 20
#define MHSENDER_FORWARD_QUEUE_SIZE 20
#define MHSENDER_RETRANSMIT_TRIAL 2
#define MHSENDER_PACKET_HISTORY_SIZE 5

typedef struct MHSenderHeader {
  uint8_t mhsenderType;
  uint8_t dataSeqnum;
  uint8_t realSource;
} MHSenderHeader;


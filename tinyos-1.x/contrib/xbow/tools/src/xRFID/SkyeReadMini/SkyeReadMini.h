#ifndef SKYREAD_MINI_H
#define SKYREAD_MINI_H

#define TOS_PACKET_LENGTH 29

enum {
  MSG_PAYLOAD = 23,
  TID_REQUEST_SIZE = 6,
  TREAD_REQUEST_SIZE = 26,
  TWRITE_REQUEST_SIZE = 34,
  FMW_REQUEST_SIZE = 8
};

enum {
  CR = 0x0d,
  LF = 0x0a
};



#define PAYLOAD_DATA_INDEX 6
typedef struct Payload
{
  uint8_t  num;    // num of packets
  uint8_t  pidx;   // packet index 
  uint16_t RID;    // receive id?
  uint16_t SG;     // signal strength
  uint8_t  data[MSG_PAYLOAD];
} Payload;


typedef struct TagCommand
{
  uint8_t flag[2];
  uint8_t request[2];
  uint8_t type[2];
  uint8_t TID[16];
  uint8_t start[2];
  uint8_t length[2];
  uint8_t data[8];
} TagCommand;


// from byte level UART sender (FramerM.nc)
enum{
  PROTO_ACK              = 64,
  PROTO_PACKET_ACK       = 65,
  PROTO_PACKET_NOACK     = 66,
  PROTO_UNKNOWN          = 255
};


#endif

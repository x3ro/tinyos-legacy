/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Michael Li
 *
 * Date last modified:  9/30/04
 *
 */

#ifndef SEND_TO_RADIO
#define SEND_TO_RADIO 0
#endif

// send data to UART or RF
#if SEND_TO_RADIO
  #define TOS_SEND_ADDR  TOS_BCAST_ADDR
  #define POWER_DOWN_RADIO // turns off radio after sending packets.
#else
  #define TOS_SEND_ADDR  TOS_UART_ADDR
  #undef  POWER_DOWN_RADIO
#endif


enum {
  AMTYPE_MINI   = 0x51,     // value shows that the packet we are sending is of the type RFID
  MSG_PAYLOAD   =   23,
  PACKETIZER_OVERHEAD = 6   // MSG_PAYLOAD + PACKETIZER_OVERHEAD = TOS_MSG_LENGTH
};


typedef struct Payload
{
  uint8_t  num;    // num of packets
  uint8_t  pidx;   // packet index
  uint16_t RID;    // receive id?
  uint16_t SG;     // signal strength
  uint8_t  data[MSG_PAYLOAD];   // Skyetek Mini data
} Payload;

#ifndef RELIABLESERIAL_H
#define RELIABLESERIAL_H

enum { ACK_TIMEOUT = 250,
       AM_ACK_MSG = 22,
       AM_RELIABLE_MSG = 23 };

typedef nx_struct reliable_msg {
  nx_uint8_t cookie;
  nx_uint8_t data[];
} reliable_msg_t;

typedef nx_struct ack_msg {
  nx_uint8_t cookie;
} ack_msg_t;

#endif

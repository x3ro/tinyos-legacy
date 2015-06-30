//$Id: DripSend.h,v 1.2 2005/06/14 18:19:35 gtolle Exp $

enum {
  AM_DRIPSEND = 75,
};

typedef struct AddressMsg {
  uint16_t source;
  uint16_t dest;
  uint8_t  data[0];
} AddressMsg;


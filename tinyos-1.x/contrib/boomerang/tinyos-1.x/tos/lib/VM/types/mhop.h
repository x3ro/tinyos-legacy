#include "MateConstants.h"

typedef struct MateRouteMsg {
  uint16_t sourceaddr;
  uint16_t originaddr;
  int16_t seqno;
  uint8_t hopcount;
  uint8_t data[]; 
} __attribute__ ((packed)) MateRouteMsg;




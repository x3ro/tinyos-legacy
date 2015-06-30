#ifndef _HEADER_H_
#define _HEADER_H_

#include "../../../tos/include/MSG.h"
#include "../DiffNodeInc/DataMessage.inc"
#include "../DiffNodeInc/InterestMessage.inc"

#ifndef DEFAULT_LOCAL_GROUP
#define DEFAULT_LOCAL_GROUP 0x7d
#endif

#define LOCAL_GROUP DEFAULT_LOCAL_GROUP

#define INTEREST_MSG 200
#define DATA_MSG     201

#define POWER_MSG    210

#define POWER_CMD 0
#define POW_VALUE 1

#define SETNBOUNCE      0
#define WRITESETNBOUNCE 1
#define READNSEND       2


#define ID_MSG       211
struct id {
  uint16_t id;
};

#define ID_RESET     212



inline uint16_t htom16(uint16_t val) {
  return val;
  // return ( (val & 0xFF) << 8 | ((val >> 8) & 0xFF));
}

inline uint32_t htom32(uint32_t val) {
  /*
  return ( ((val & 0xFF) << 24) 
	   |(((val >> 8 ) & 0xFF) << 16)
	   |(((val >> 16) & 0xFF) << 8)
	   |((val >> 24) & 0xFF) );
  */
    return val;
}

inline uint16_t mtoh16(uint16_t val) {
  return htom16(val);
}

inline uint32_t mtoh32(uint32_t val) {
  return htom32(val);
}

#endif






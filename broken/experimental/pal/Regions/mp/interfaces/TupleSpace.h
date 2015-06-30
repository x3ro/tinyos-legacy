
#ifndef _TUPLESPACE_H
#define _TUPLESPACE_H

typedef uint8_t ts_key_t;

enum {
  TUPLESPACE_BUFLEN = 4,
  TUPLESPACE_MAX_KEY = 32,
  TS_LOCATION_KEY = 31,
  TUPLESPACE_ANYADDR = 0xffff, 
  TUPLESPACE_ANYADDR_CLEAR = 0xfffe, 
};

#endif

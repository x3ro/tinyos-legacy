// Interface to motlle VM

typedef void *mvalue;
typedef uint16_t uvalue;
typedef int16_t ivalue;

#include "motlle-interface.h"

enum {
  W_TIME = 1,
  W_DBG = 2,
  W_DATA = 4
};

enum {
  DBG_SYS = 1,
  DBG_RUN = 2,
  DBG_CODE = 4
};

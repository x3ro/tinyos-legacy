

#include "../Common/common.h"

enum {
  BUFFER_SIZE = 10
};

struct OscopeMsg
{
    uint16_t sourceMoteID;
    uint16_t lastSampleNumber;
    uint16_t channel;
    uint16_t data[BUFFER_SIZE];
};

struct OscopeResetMsg
{
    /* Empty payload! */
};



  
  
enum {
  AM_OSCOPEMSG = 10,
  AM_OSCOPERESETMSG = 32
};

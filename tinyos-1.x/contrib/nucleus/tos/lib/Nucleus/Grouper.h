//$Id: Grouper.h,v 1.4 2005/07/19 20:06:20 gtolle Exp $

enum {
    AM_GROUPERCMDMSG = 20,
    SERIAL_ID_LEN = 8,
    GROUPER_JOIN = 1,
    GROUPER_LEAVE = 2,
};

typedef struct GrouperCmdMsg {
  uint8_t serialID[SERIAL_ID_LEN]; 
  uint16_t groupID;
  uint16_t timeout;
  uint8_t op;
} GrouperCmdMsg;

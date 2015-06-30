struct WakeupMsg
{
  uint16_t sender;		/* Id of Ipaq's mote */
};

struct FieldMsg
{
  uint16_t sender;		/* Id of Ipaq's mote */
  uint16_t cmdId;		/* Unique sequence number */
  uint8_t cmd;
};

struct FieldReplyMsg
{
  uint16_t sender;
  uint16_t cmdId;
  uint8_t response;
};

enum {
  /* A special cmdId for responses to wakeup messages */
  WAKEUP_CMDID = 0
};

enum { 
  AM_WAKEUPMSG = 120,
  AM_FIELDMSG = 121,
  AM_FIELDREPLYMSG = 122
};

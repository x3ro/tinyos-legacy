enum {
  AM_TOSBASECMDMSG = 0,
};

typedef struct TOSBaseCmdMsg {
  bool addrChanged:1;
  bool groupChanged:1;
  bool rfPowerChanged:1;
  bool lplModeChanged:1;
  bool llAckChanged:1;

  uint16_t addr;
  uint8_t  group;
  uint8_t  rfPower;
  uint8_t  lplMode;
  bool     llAck;
} TOSBaseCmdMsg;


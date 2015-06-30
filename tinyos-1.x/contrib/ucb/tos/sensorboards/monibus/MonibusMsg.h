// $Id: MonibusMsg.h,v 1.1 2005/06/15 09:51:26 neturner Exp $

enum {
  MONIBUS_DATA_LENGTH = 20
};

struct MonibusMsg
{
    uint16_t sourceMoteID;
    uint8_t data[MONIBUS_DATA_LENGTH];
};

enum {
  AM_MONIBUSMSG = 10,
};

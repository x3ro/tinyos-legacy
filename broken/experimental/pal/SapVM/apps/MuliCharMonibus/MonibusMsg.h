// $Id: MonibusMsg.h,v 1.1 2005/05/16 09:43:41 neturner Exp $

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

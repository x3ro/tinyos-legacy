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

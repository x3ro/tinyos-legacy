// $Id: MonibusSensorMsg.h,v 1.2 2005/07/04 09:28:54 neturner Exp $

struct MonibusSensorMsg
{
    uint16_t sourceMoteID;
    uint16_t PAR;
    uint16_t TSR;
    uint16_t voltage12;
};

enum {
  AM_MONIBUSSENSORMSG = 11,
};

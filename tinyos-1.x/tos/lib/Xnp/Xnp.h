// $Id: Xnp.h,v 1.3 2003/10/07 21:46:27 idgay Exp $

#include <avr/eeprom.h> 

enum {
  AM_XnpMsg_ID = 47,
  EEPROM_ID = 47
};

void xnp_reboot() {
  int (*ptr)() = 0;
  ptr();
}

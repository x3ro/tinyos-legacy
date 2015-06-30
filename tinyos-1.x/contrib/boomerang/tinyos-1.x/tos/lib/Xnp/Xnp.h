// $Id: Xnp.h,v 1.1.1.1 2007/11/05 19:10:05 jpolastre Exp $

#include <avr/eeprom.h> 

enum {
  AM_XnpMsg_ID = 47,
  EEPROM_ID = 47
};

void xnp_reboot() {
  int (*ptr)() = 0;
  ptr();
}

#ifndef AT45COMPAT_H
#define AT45COMPAT_H

/* Make the 1.x interfaces appear like the 2.x AT45DB HAL */

#include "PageEEPROM.h"

typedef eeprompage_t at45page_t;
typedef eeprompageoffset_t at45pageoffset_t;

enum {
  AT45_MAX_PAGES = TOS_EEPROM_MAX_PAGES,
  AT45_PAGE_SIZE = TOS_EEPROM_PAGE_SIZE,
  AT45_PAGE_SIZE_LOG2 = TOS_EEPROM_PAGE_SIZE_LOG2,
  AT45_ERASE = TOS_EEPROM_ERASE,
  AT45_DONT_ERASE = TOS_EEPROM_DONT_ERASE,
  AT45_PREVIOUSLY_ERASED = TOS_EEPROM_PREVIOUSLY_ERASED
};

#endif

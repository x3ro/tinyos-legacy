#ifndef TOS_PAGEEEPROM_H
#define TOS_PAGEEEPROM_H

// EEPROM characteristics
enum {
  TOS_EEPROM_MAX_PAGES = 2048,
  TOS_EEPROM_PAGE_SIZE = 264,
};

enum {
  TOS_EEPROM_ERASE,
  TOS_EEPROM_DONT_ERASE,
  TOS_EEPROM_PREVIOUSLY_ERASED
};

typedef uint16_t eeprompage_t;
typedef uint16_t eeprompageoffset_t; /* 0 to TOS_EEPROM_PAGE_SIZE - 1 */

#endif

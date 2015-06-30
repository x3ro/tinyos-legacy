#include "tos.h"
#include "OCEEPROM.h"

/* Bit flags in EEPROM control register */
#define _EERIE 0x08
#define _EEMWE 0x04
#define _EEWE  0x02
#define _EERE  0x01

static char OCEEPROM_inUse=0;

void TOS_COMMAND(OCEEPROM_READ)(int addr, int size, char* buf) {
  int i, curAddr;
  if(! OCEEPROM_inUse ) {
    OCEEPROM_inUse=1;
    
    // wait for write to complete [not really necessary]
    while ( inp(EECR) & _EEWE );

    for(i=0; i < size; i++ ) {
      curAddr=addr+i;
      
      // load address
      outp( curAddr & 0xFF, EEARL);
      outp( (curAddr >> 8) & 0xFF , EEARH);

      // read data
      outp( _EERE, EECR);
      buf[i]=inp(EEDR);

    }

    OCEEPROM_inUse=0;
  }
}


void TOS_COMMAND(OCEEPROM_WRITE)(int addr, int size, char* buf) {
  int i, curAddr;
  if(! OCEEPROM_inUse ) {
    OCEEPROM_inUse=1;

    for(i=0; i<size; i++) {
      curAddr=addr+i;
      // wait for write to complete 
      while ( inp(EECR) & _EEWE );

      // disable interrupts
      cli();

      // load address 
      outp( curAddr & 0xFF, EEARL);
      outp( (curAddr >> 8) & 0xFF , EEARH);

      // load data to be written
      outp( buf[i], EEDR );

      // set master write enable
      outp( _EEMWE, EECR );
      // set write enable
      outp( _EEWE, EECR );

      // enable interrupts
      sei();
    }
    
    OCEEPROM_inUse=0;
  }
}



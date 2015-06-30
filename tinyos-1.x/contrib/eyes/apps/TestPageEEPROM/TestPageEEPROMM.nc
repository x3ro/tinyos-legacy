/**
 * Testing the PageEEPROMM component for the ifx platform - M25P05 flash chip.
 * 
 * 1. Bulk (total) erase of flash
 * 2. Write some data into a page (see global vars)
 * 3. Read the same data and compare with previously written data
 * 4. repeat 1.-3. for page 0, i.e. internal msp430 flash
 *
 * expected result: LEDs 0,1: ON; LED 2,3: OFF
 * (any other result means failure) 
 **/
module TestPageEEPROMM {
  provides {
    interface StdControl;
  }
  uses {
    interface PageEEPROM;
    interface FlashM25P05;
    interface LedsNumbered;
  }
}
implementation {
  #include "hardware.h"
  
  uint8_t data[150];
  eeprompage_t page = 0;
  eeprompageoffset_t offset = 0;
  eeprompageoffset_t n = 100; 

  task void startTest();
  
  command result_t StdControl.init() {
    call LedsNumbered.init();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
  
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call FlashM25P05.eraseAll();
    return SUCCESS;
  } 
  
  event result_t FlashM25P05.eraseAllDone(){
    call PageEEPROM.read(0, 0, &data, 1);
    return SUCCESS;
  }
   
  task void startTest(){
    result_t result;
    uint8_t i;
    
    for (i=0; i<150; i++) data[i]=i;  
    result = call PageEEPROM.write(page, offset, &data, n);
    if (result == SUCCESS)
      call LedsNumbered.led0On();
    else
      call LedsNumbered.led3On();
  }  
  
  event result_t PageEEPROM.writeDone(result_t result){
    uint8_t i;
    for (i=0; i<150; i++) data[i]=0xAB;  
    call LedsNumbered.led1On();
    result = call PageEEPROM.read(page, offset, &data, n);
    return SUCCESS;
  }
  
  event result_t PageEEPROM.readDone(result_t result){
    call LedsNumbered.led3On();
    return SUCCESS;
  
  /*
    uint8_t i;
    for (i=0; i<n; i++)
      if (data[i] != i)
        call LedsNumbered.led2On();
    call LedsNumbered.led3On();
    //call PageEEPROM.erase(0, TOS_EEPROM_ERASE);
    //call PageEEPROM.erase(1, TOS_EEPROM_ERASE);
    return SUCCESS;
    */
  }
    
  event result_t FlashM25P05.eraseSectorDone(uint8_t sector){return SUCCESS;} 
   
  event result_t PageEEPROM.eraseDone(result_t result){
    uint8_t i;
    page = 1;
    offset = 7;
    n = 100; 
    for (i=0; i<150; i++) data[i]=i;  
    result = call PageEEPROM.write(page, offset, &data, n);
    if (result == SUCCESS)
      call LedsNumbered.led0On();
    else
      call LedsNumbered.led3On();
   return SUCCESS;
  }
  
  event result_t PageEEPROM.syncDone(result_t result){return SUCCESS;}
  event result_t PageEEPROM.flushDone(result_t result){return SUCCESS;}  
  event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc){return SUCCESS;}
  
}



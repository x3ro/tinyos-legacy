/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: bootloader.c,v 1.1 2004/04/27 22:29:09 gtolle Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Terence Tong
 * For Johnathan Hui's Deluge Project
 */
/*////////////////////////////////////////////////////////*/


#include <avr/io.h>
#include "inttypes.h"
#include <hardware.h>
#include <avr/wdt.h>
#include "avr/eeprom.h"
#include "avr/pgmspace.h"
#include "bootloader.h"
#include "avr/boot.h"
#include "string.h"

void initialise();
void transferBinary(uint32_t startPage, uint32_t length);
void halt();

__asm__(".org 0x1f800, 0xff" "\n\t");
char _start(uint16_t startPage, uint32_t length) {

  int i = 0;

  initialise();
  transferBinary(startPage, length);

  wdt_enable(1);

  halt();

  return 0;
}

//////////////////////////////////////////////////////////
// DEBUG FUNCTIONS
//////////////////////////////////////////////////////////

void int2Leds(uint16_t value ) {

  if (value & 1) TOSH_CLR_RED_LED_PIN();
  else TOSH_SET_RED_LED_PIN();
  if (value & 2) TOSH_CLR_YELLOW_LED_PIN();
  else TOSH_SET_YELLOW_LED_PIN();
  if (value & 4) TOSH_CLR_GREEN_LED_PIN();
  else TOSH_SET_GREEN_LED_PIN();

  
}

void halt() {
  while(1) {}
}

void UARTInit() {
  // UART will run at:
  // 115kbps, N-8-1
  
  // Set 57.6 KBps
  outp(0,UBRR0H); 
  outp(15, UBRR0L);
  
  // Set UART double speed
  outp((1<<U2X),UCSR0A);
  
  // Set frame format: 8 data-bits, 1 stop-bit
  outp(((1 << UCSZ1) | (1 << UCSZ0)) , UCSR0C);
  
  // Enable reciever and transmitter and their interrupts
  outp(((1 << RXCIE) | (1 << TXCIE) | (1 << RXEN) | (1 << TXEN)) ,UCSR0B);
}

void slack() {
  int i = 0;
  for (i = 0; i < 10000; i++) {
  }
}

// WARNING, We don't check PutDone Here, make sure you wait sometime before you issue next one
void UARTPut(uint8_t data) {
  outp(data, UDR0); 
  sbi(UCSR0A, TXC);
  slack();
}
uint8_t redLedToggle(uint8_t status) {
  if (status == 1) {
    TOSH_SET_RED_LED_PIN();
    return 0;
  } else {
    TOSH_CLR_RED_LED_PIN();
    return 1;
  }

}

///////////////////////////////////////

void eepromStopRead() {
  TOSH_MAKE_FLASH_SELECT_OUTPUT();
  TOSH_SET_FLASH_SELECT_PIN();
}

void initFlash() {
  TOSH_CLR_FLASH_CLK_PIN();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
  TOSH_SET_FLASH_OUT_PIN();
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_CLR_FLASH_IN_PIN();
  TOSH_MAKE_FLASH_IN_INPUT();
}

void makeLeds() {
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
}

void offLeds() {
  TOSH_SET_RED_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_SET_GREEN_LED_PIN();
}


void resetIO() {
  outp(0x00, DDRA);
  outp(0x00, DDRD);
  outp(0x00, DDRC);
  outp(0x00, DDRB);
  outp(0x00, PORTA);
  outp(0x00, PORTD);
  outp(0x00, PORTC);
  outp(0x00, PORTB);
}
void initialise() {
  // disable interrupt
  cli();
  // UART Stuff
  UARTInit();
  UARTPut(0);
  UARTPut(1);
  UARTPut(2);
  UARTPut(3);
  UARTPut(4);

  // disable watchdog timer
  wdt_disable();
  // get io ports into defined state
  resetIO();
  offLeds();
  makeLeds();
  eepromStopRead();
  initFlash();
}




/////////////////////////////

static inline void noop() {
  asm volatile("nop" "\n\t");
  asm volatile("nop" "\n\t");
}

int SPIOutput(uint8_t spiOut) {
  if (spiOut & 0x80) {	
    TOSH_SET_FLASH_OUT_PIN();  
  } else {			
    TOSH_CLR_FLASH_OUT_PIN();	
  } 			
  spiOut <<=1;
  return spiOut;
}

int SPIInput(uint8_t spiIn) {
  spiIn <<= 1;			
  if (TOSH_READ_FLASH_IN_PIN()) {	
    spiIn |= 1;		
  } else {			
    noop();			
  }
  return spiIn;
}


uint8_t SPIByte(uint8_t cOut) {
  uint8_t i;
  uint8_t spiOut = cOut;
  uint8_t spiIn = 0;
  for (i = 0; i < 8; i++) {
    spiOut = SPIOutput(spiOut);
    TOSH_SET_FLASH_CLK_PIN();
    spiIn = SPIInput(spiIn);
    TOSH_CLR_FLASH_CLK_PIN();
  }
  return spiIn;
}

void SPIClockCycle() {
  TOSH_SET_FLASH_CLK_PIN();
  noop();
  TOSH_CLR_FLASH_CLK_PIN();
}





// setup external flash for autoinc readout
char eepromStartRead(uint16_t pageAddress) {
  uint8_t cmdBuf[4];
  int i;
  uint16_t byteAddress = 0;
  cmdBuf[0] = EE_AUTOREAD; // opcode;	// EE Flash opcode
  cmdBuf[1] = (pageAddress >> 7) & 0x0F;	// pageAddress[10:7] in lower nibble
  cmdBuf[2] = (pageAddress << 1) + (byteAddress >> 8); // pageAddress[6:0]+ byteAddress[8]
  cmdBuf[3] = (uint8_t) byteAddress;		// byteAddress[7:0]
  // select the flash
  TOSH_MAKE_FLASH_SELECT_OUTPUT();
  TOSH_CLR_FLASH_SELECT_PIN();

  for(i = 0; i < 4; i++)
    SPIByte(cmdBuf[i]); // writeout the command
  for(i = 0; i < 4; i++)
    SPIByte(0xAA);	// write out 4 fill bytes
  // EEFlash requires 1 additional (65th) clock to setup data on SOut pin
  SPIClockCycle();
  return(0);
}

// returnInstr is a 16 byte buffer
uint8_t eepromReadByte() {
  return SPIByte(0);
}

/////////////////////////////////////

void writeBuffer2Flash(uint8_t *buffer, uint32_t pageBaseByteAddress, uint32_t length) {
  int i = 0;
  uint16_t *wordBuffer = (uint16_t *) buffer;

  //  if ((pageBaseByteAddress / 256) % 256 == 0) 
  for (i = 0; i < length; i ++) {
    UARTPut(buffer[i]);
  }
  
  boot_page_erase(pageBaseByteAddress);
  while(boot_rww_busy()) { boot_rww_enable(); }
  for (i = 0; i < length / sizeof(uint16_t); i++) {
    boot_page_fill(pageBaseByteAddress + i * 2, wordBuffer[i]);
  }
  boot_page_write(pageBaseByteAddress);
  while(boot_rww_busy()) { boot_rww_enable(); }
}

void transferBinary(uint32_t startPage, uint32_t length) {
  uint32_t byteCounter = 0;
  uint8_t buffer[INTERNAL_PAGE_SIZE];
  uint32_t pageAddress;
  uint8_t ledStatus = 0;
  for (byteCounter = 0; byteCounter < length; byteCounter ++) {

    if (byteCounter % EXTERNAL_PAGE_SIZE == 0) {
      eepromStopRead();
      eepromStartRead(startPage + byteCounter / EXTERNAL_PAGE_SIZE);
    }
    if (byteCounter != 0 && byteCounter % INTERNAL_PAGE_SIZE == 0) {
      ledStatus = redLedToggle(ledStatus);
      pageAddress = (byteCounter / INTERNAL_PAGE_SIZE) - ((uint32_t) 1);
      writeBuffer2Flash(buffer, pageAddress * INTERNAL_PAGE_SIZE, INTERNAL_PAGE_SIZE);
    }
    buffer[byteCounter % INTERNAL_PAGE_SIZE] = eepromReadByte(); 
  }
  
  if (byteCounter % INTERNAL_PAGE_SIZE == 0) {
    pageAddress = byteCounter / INTERNAL_PAGE_SIZE - ((uint32_t) 1);
    writeBuffer2Flash(buffer, pageAddress * INTERNAL_PAGE_SIZE, INTERNAL_PAGE_SIZE);
  } else {
    pageAddress = (byteCounter / INTERNAL_PAGE_SIZE);
    writeBuffer2Flash(buffer, pageAddress * INTERNAL_PAGE_SIZE, byteCounter % INTERNAL_PAGE_SIZE);
  }
  eepromStopRead();  
  TOSH_CLR_RED_LED_PIN();
}



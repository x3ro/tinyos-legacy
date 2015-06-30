#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"

void wait(uint16_t t) {
  for ( ; t > 0; t-- );
}

// LEDs
TOSH_ASSIGN_PIN(RED_LED, 5, 4);
TOSH_ASSIGN_PIN(GREEN_LED, 5, 5);
TOSH_ASSIGN_PIN(YELLOW_LED, 5, 6);

// UART pins
TOSH_ASSIGN_PIN(SOMI0, 3, 2);
TOSH_ASSIGN_PIN(SIMO0, 3, 1);
TOSH_ASSIGN_PIN(UCLK0, 3, 3);
TOSH_ASSIGN_PIN(UTXD0, 3, 4);
TOSH_ASSIGN_PIN(URXD0, 3, 5);

// User Interupt Pin
TOSH_ASSIGN_PIN(USERINT, 2, 7);

// FLASH
TOSH_ASSIGN_PIN(FLASH_PWR, 4, 3);
TOSH_ASSIGN_PIN(FLASH_CS, 4, 4);
TOSH_ASSIGN_PIN(FLASH_HOLD, 4, 7);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  // reset all of the ports to be input and using i/o functionality
  P1SEL = 0;
  P2SEL = 0;
  P3SEL = 0;
  P4SEL = 0;
  P5SEL = 0;
  P6SEL = 0;

  P1DIR = 0xe0;
  P1OUT = 0x00;
 
  P2DIR = 0x7b;
  P2OUT = 0x10;

  P3DIR = 0xf1;
  P3OUT = 0x00;

  P4DIR = 0xfd;
  P4OUT = 0xdd;

  P5DIR = 0xff;
  P5OUT = 0xff;

  // XXX: ADC pins 0, 1, 2, 3, 6, and 7 set to input for trio mote
  // XXX: 00110000
  P6DIR = 0x30;
  P6OUT = 0x00;

  P1IE = 0;
  P2IE = 0;
}

#endif // _H_hardware_h


// $Id: hardware.h,v 1.1 2006/01/13 20:15:04 chien-liang Exp $

// Copyright (c) 2004 by the University College Cork, Ireland
// All rights reserved.

// Author:
//  Andre Barroso  (UCC/CS)

#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#ifndef TOSH_HARDWARE_DSYS25
#define TOSH_HARDWARE_DSYS25
#endif // tosh hardware

#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include <avrhardware.h>
#include "nRF2401Const.h"

// avrlibc may define ADC as a 16-bit register read.  This collides with the nesc
// ADC interface name
uint16_t inline getADC() {
  return inw(ADC);
}
#undef ADC

#define TOSH_CYCLE_TIME_NS 250   //aproximate. I assume clock is 4 Mhz

// each nop is 1 clock cycle
// 1 clock cycle on dsys25 == 250ns
void inline TOSH_wait_250ns() {
      asm volatile  ("nop" ::);
}

void inline TOSH_uwait(int u_sec) {
    while (u_sec > 0) {
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      u_sec--;
    }
}

//Copy of origional
//TOSH_ASSIGN_PIN(YELLOW_LED, D, 2);
//TOSH_ASSIGN_PIN(GREEN_LED, D, 4); //Not really used now
//TOSH_ASSIGN_PIN(RED_LED, D, 1);


TOSH_ASSIGN_PIN(RED_LED, D, 0);
TOSH_ASSIGN_PIN(GREEN_LED, D, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, D, 5); //Not used //This is really the RED LED i.e. power LED



//Copy of origional
//TOSH_ASSIGN_PIN(I2C_BUS1_SCL, D, 0);
//TOSH_ASSIGN_PIN(I2C_BUS1_SDA, D, 1);


TOSH_ASSIGN_PIN(I2C_BUS1_SCL, D, 1);
TOSH_ASSIGN_PIN(I2C_BUS1_SDA, D, 0);



// interrupt assignments - DSys25
TOSH_ASSIGN_PIN(INT0, D, 4);
TOSH_ASSIGN_PIN(INT1, D, 5);
TOSH_ASSIGN_PIN(INT2, D, 6);
TOSH_ASSIGN_PIN(INT3, D, 7);

//Radio control assignments - DSys25
TOSH_ASSIGN_PIN(RF_PWR_UP, E, 2);  // Power Up
TOSH_ASSIGN_PIN(RF_CE, E, 3);      // Chip Enable Activates RX or TX mode
TOSH_ASSIGN_PIN(RF_DOUT2, E, 4);   // RX Data Channel 2
TOSH_ASSIGN_PIN(RF_CLK2, E, 5);    // Clock Output/Input for RX Data Channel 2
TOSH_ASSIGN_PIN(RF_DR2, E, 6);     // RX Data Ready at Data Channel 2 (ShockBurst only)
TOSH_ASSIGN_PIN(RF_DR1, E, 7);     // RX Data Ready at Data Channel 1 (ShockBurst only)
// spibus assignments
TOSH_ASSIGN_PIN(RF_CS, B, 0);      // Chip Select Activates Configuration Mode
TOSH_ASSIGN_PIN(RF_CLK1, B, 1);    // ClockInput (TX) & Output/Input (RX) for Data Channel 1 - 3-wire interface
TOSH_ASSIGN_PIN(RF_DATA, B, 2);    // RX Data Channel 1/ TX Data Input/ 3-wire interface


// DSYS25
void TOSH_SET_PIN_DIRECTIONS(void)
{

 outp(0x00, DDRA);
 outp(0x00, DDRB);
 outp(0x00, DDRD);
 outp(0x02, DDRE);
 outp(0x02, PORTE);

 TOSH_MAKE_RED_LED_OUTPUT();
 TOSH_MAKE_YELLOW_LED_OUTPUT();
 TOSH_MAKE_GREEN_LED_OUTPUT();

 TOSH_MAKE_RF_CE_INPUT();
 TOSH_MAKE_RF_DOUT2_OUTPUT();
 TOSH_MAKE_RF_DR2_OUTPUT();
 TOSH_MAKE_RF_DR1_OUTPUT();
 TOSH_MAKE_RF_CS_INPUT();

}


enum {
  TOSH_ADC_PORTMAPSIZE = 12
};

enum
{
  //  TOSH_ACTUAL_CC_RSSI_PORT = 0,
  TOSH_ACTUAL_VOLTAGE_PORT = 7,
  TOSH_ACTUAL_BANDGAP_PORT = 30,  // 1.23 Fixed bandgap reference
  TOSH_ACTUAL_GND_PORT     = 31   // GND
};

enum
{
  //  TOS_ADC_CC_RSSI_PORT = 0,
  TOS_ADC_VOLTAGE_PORT = 7,
  TOS_ADC_BANDGAP_PORT = 10,
  TOS_ADC_GND_PORT     = 11
};


#endif //TOSH_HARDWARE_H





/*                                                                      tab:4
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors: Jason Hill, Philip Levis, Nelson Lee, David Gay
 *
 * Modified for btnode2_2 hardware by Mads Bondo Dydensborg
 * <madsdyd@diku.dk>, 2002-2003
 *
 * Modified for btnode3_2 hardware by Jan Beutel
 * <j.beutel@ieee.org>, 2004
 *
 * $Id: hardware.h,v 1.3 2006/02/01 13:28:11 hjernemadsen Exp $
 * 
 * $Log: hardware.h,v $
 * Revision 1.3  2006/02/01 13:28:11  hjernemadsen
 * Make btnode3_1 and btnode3_2 compile again.
 *
 * Revision 1.2  2005/02/17 13:00:40  beutel
 * added attilas tos tree for btnode 3_20
 *
 * Revision 1.1  2004/10/07 16:15:11  beutel
 * first try to incorporate the BTnode3 platform into TinyOS
 *
 * 
 */


#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

// Makes io.h include io128.h instead...
#define __AVR_ATmega128__ 1

#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include <avrhardware.h>
#include <CC1000Const.h>

// avrlibc may define ADC as a 16-bit register read.  This collides with the nesc
//ADC interface name
uint16_t inline getADC() {
  return inw(ADC);
}
#undef ADC

void inline TOSH_uwait(int u_sec) {
    while (u_sec > 0) {
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
      u_sec--;
   }
}

//
// !!! FOR THE MOMENT BEING, this is all BTnode rev3.10 specific !!!
//

// LED assignments
// to be defined later
/*
TOSH_ASSIGN_PIN(YELLOW_LED, C, 2);
TOSH_ASSIGN_PIN(GREEN_LED , C, 3);
TOSH_ASSIGN_PIN(RED_LED   , C, 1);
TOSH_ASSIGN_PIN(EXTRA_LED , C, 0);
*/

//TOSH_ASSIGN_PIN(SERIAL_ID, A, 4);
//TOSH_ASSIGN_PIN(BAT_MON, F, 3);
//TOSH_ASSIGN_PIN(THERM_PWR, A, 7);

// ChipCon control assignments
TOSH_ASSIGN_PIN(CC_CHP_OUT, E, 7);    // chipcon CHP_OUT
TOSH_ASSIGN_PIN(CC_PDATA  , D, 7);    // chipcon PDATA 
TOSH_ASSIGN_PIN(CC_PCLK   , D, 6);	  // chipcon PCLK
TOSH_ASSIGN_PIN(CC_PALE   , D, 5);	  // chipcon PALE

TOSH_ASSIGN_PIN(LATCH_SELECT, B, 5);

// spibus assignments 
TOSH_ASSIGN_PIN(MOSI,  B, 2);
TOSH_ASSIGN_PIN(MISO,  B, 3);
TOSH_ASSIGN_PIN(SPI_OC1C, B, 7);
TOSH_ASSIGN_PIN(SPI_SCK,  B, 1);



#ifdef THIS_USED_TO_BE_SET_IN_MICA
/* This I do not understand - has to do with a potentiometer, I think */
TOSH_ASSIGN_PIN(UD, A, 1);
TOSH_ASSIGN_PIN(INC, A, 2);
TOSH_ASSIGN_PIN(POT_SELECT, D, 5);
TOSH_ASSIGN_PIN(POT_POWER, E, 7);
TOSH_ASSIGN_PIN(BOOST_ENABLE, E, 4);

TOSH_ASSIGN_PIN(FLASH_SELECT,  B, 0);
TOSH_ASSIGN_PIN(FLASH_CLK,  A, 3);
TOSH_ASSIGN_PIN(FLASH_OUT,  A, 7);
TOSH_ASSIGN_PIN(FLASH_IN,  A, 6);

TOSH_ASSIGN_PIN(INT1, D, 1);
TOSH_ASSIGN_PIN(INT2, D, 2);
TOSH_ASSIGN_PIN(INT3, D, 3);

TOSH_ASSIGN_PIN(RFM_RXD,  B, 2);
TOSH_ASSIGN_PIN(RFM_TXD,  B, 3);
TOSH_ASSIGN_PIN(RFM_CTL0, D, 7);
TOSH_ASSIGN_PIN(RFM_CTL1, D, 6);

TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW0, C, 0);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW1, C, 1);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW2, C, 2);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW3, C, 3);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW4, C, 4);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW5, C, 5);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW6, C, 6);
TOSH_ASSIGN_OUTPUT_ONLY_PIN(PW7, C, 7);

TOSH_ASSIGN_PIN(OLD_I2C_BUS1_SCL, A, 4);
TOSH_ASSIGN_PIN(OLD_I2C_BUS1_SDA, A, 5);

TOSH_ASSIGN_PIN(LITTLE_GUY_RESET, E, 6);

TOSH_ASSIGN_PIN(ONE_WIRE, E, 5);

#endif


/* The uart. Uart0 is connected to the bluetooth module
   via pe0 and pe1. Uart1 is external, via pd2 and pd3. */
TOSH_ASSIGN_PIN(UART_RXD0, E, 0);
TOSH_ASSIGN_PIN(UART_TXD0, E, 1);

TOSH_ASSIGN_PIN(UART_RXD1, D, 2);
TOSH_ASSIGN_PIN(UART_TXD1, D, 3);



/* set leds and power functions */

unsigned char latch_status;

/* set function,  not irq safe */
void set_latch(int pos, int bit)
{
	unsigned char mask = 1;
	mask <<= pos;
	latch_status = (latch_status & ~mask) | (bit ? mask : 0);
	outb(PORTC, latch_status);
//	TOSH_SET_LATCH_SELECT_PIN();
	TOSH_wait(); // wait a short while until the latch is updated
//	TOSH_CLR_LATCH_SELECT_PIN();
}
	
static inline void TOSH_SET_YELLOW_LED_PIN() {set_latch(2,1);}
static inline void TOSH_CLR_YELLOW_LED_PIN() {set_latch(2,0);}
#define TOSH_MAKE_YELLOW_LED_OUTPUT()
static inline void TOSH_SET_GREEN_LED_PIN() {set_latch(3,1);}
static inline void TOSH_CLR_GREEN_LED_PIN() {set_latch(3,0);}
#define TOSH_MAKE_GREEN_LED_OUTPUT()
static inline void TOSH_SET_RED_LED_PIN() {set_latch(1,1);}
static inline void TOSH_CLR_RED_LED_PIN() {set_latch(1,0);}
#define TOSH_MAKE_RED_LED_OUTPUT()
static inline void TOSH_SET_EXTRA_LED_PIN() {set_latch(0,1);}
static inline void TOSH_CLR_EXTRA_LED_PIN() {set_latch(0,0);}
#define TOSH_MAKE_EXTRA_LED_OUTPUT()

// CC1000 power control
static inline void TOSH_SET_CC_PWR_PIN() {set_latch(5,1);}
static inline void TOSH_CLR_CC_PWR_PIN() {set_latch(5,0);}

void TOSH_SET_PIN_DIRECTIONS(void)
{
  outp(0x00, DDRA);
  outp(0x00, DDRB);
  outp(0x00, DDRD);
  outp(0x02, DDRE);
  outp(0x02, PORTE);
/* 
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_MAKE_EXTRA_LED_OUTPUT();
*/
  /* I think we will stop here 

  TOSH_MAKE_POT_SELECT_OUTPUT();
  TOSH_MAKE_POT_POWER_OUTPUT();
    
  TOSH_MAKE_PW7_OUTPUT();
  TOSH_MAKE_PW6_OUTPUT();
  TOSH_MAKE_PW5_OUTPUT();
  TOSH_MAKE_PW4_OUTPUT();
  TOSH_MAKE_PW3_OUTPUT();
  TOSH_MAKE_PW2_OUTPUT();
  TOSH_MAKE_PW1_OUTPUT();
  TOSH_MAKE_PW0_OUTPUT();
    
  TOSH_MAKE_RFM_CTL0_OUTPUT();
  TOSH_MAKE_RFM_CTL1_OUTPUT();
  TOSH_MAKE_RFM_TXD_OUTPUT();
  TOSH_SET_POT_POWER_PIN();

  TOSH_MAKE_FLASH_SELECT_OUTPUT();
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
  TOSH_SET_FLASH_SELECT_PIN();
    
  */
/*
  TOSH_SET_RED_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_SET_GREEN_LED_PIN();
  TOSH_SET_EXTRA_LED_PIN();
*/
  /*
  TOSH_MAKE_BOOST_ENABLE_OUTPUT();
  TOSH_SET_BOOST_ENABLE_PIN();

  TOSH_MAKE_ONE_WIRE_INPUT();
  TOSH_SET_ONE_WIRE_PIN();
  */

  TOSH_MAKE_LATCH_SELECT_OUTPUT();
  TOSH_SET_LATCH_SELECT_PIN();
  TOSH_SET_CC_PWR_PIN();
}


// define the voltage port here because it's not associated with any sensorboards 

enum {
  TOSH_ADC_PORTMAPSIZE = 12
};

enum 
{ 
  TOSH_ACTUAL_CC_RSSI_PORT = 0,
  TOSH_ACTUAL_VOLTAGE_PORT = 7,
  TOSH_ACTUAL_BANDGAP_PORT = 30,  // 1.23 Fixed bandgap reference
  TOSH_ACTUAL_GND_PORT     = 31   // GND
}; 
enum 
{ 
  TOS_ADC_CC_RSSI_PORT = 0,
  TOS_ADC_VOLTAGE_PORT = 7,
  TOS_ADC_BANDGAP_PORT = 10,
  TOS_ADC_GND_PORT     = 11
}; 

#endif //TOSH_HARDWARE_H

/*
 *
 * $Id: hardware.h,v 1.4 2004/09/23 06:40:28 vlahan Exp $
 *
 */


#ifndef TOSH_HARDWARE_EYESNEDAP_H
#define TOSH_HARDWARE_EYESNEDAP_H

#include "msp430hardware.h"
#include "MSP430ADC12.h"

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, 2, 4);
TOSH_ASSIGN_PIN(GREEN_LED, 2, 5);
TOSH_ASSIGN_PIN(YELLOW_LED, 2, 5);

// USART assignments
TOSH_ASSIGN_PIN(SIMO0, 3, 1); 
TOSH_ASSIGN_PIN(SOMI0, 3, 2); 
TOSH_ASSIGN_PIN(UCLK0, 3, 3); 
TOSH_ASSIGN_PIN(UTXD0, 3, 4); 
TOSH_ASSIGN_PIN(URXD0, 3, 5); 

// USART1 assignments
TOSH_ASSIGN_PIN(UTXD1, 3, 6);  
TOSH_ASSIGN_PIN(URXD1, 3, 7);
TOSH_ASSIGN_PIN(UCLK1, 5, 3);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(SIMO1, 5, 1);

TOSH_ASSIGN_PIN(RS232_ENABLE, 2, 3);
TOSH_ASSIGN_PIN(RS232_FORCEON, 5, 0);
TOSH_ASSIGN_PIN(RS232_FORCEOFF, 5, 5);

// Potentiometer
TOSH_ASSIGN_PIN(POT_CS, 4, 2);
TOSH_ASSIGN_PIN(POT_UD, 4, 4);
TOSH_ASSIGN_PIN(POT_INC, 4, 3);

// Flash 
TOSH_ASSIGN_PIN(FLASH_CS, 3, 0);

// Sensor assignments
TOSH_ASSIGN_PIN(RSSI, 6, 0);


void TOSH_SET_PIN_DIRECTIONS(void)
{
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  
  TOSH_SET_RED_LED_PIN();
  TOSH_SET_GREEN_LED_PIN();

  TOSH_MAKE_RS232_ENABLE_OUTPUT();
  TOSH_SET_RS232_ENABLE_PIN();

  TOSH_MAKE_RS232_FORCEON_OUTPUT();
  TOSH_MAKE_RS232_FORCEOFF_OUTPUT();
  TOSH_SET_RS232_FORCEOFF_PIN();

  TOSH_SEL_RSSI_MODFUNC();
  TOSH_MAKE_RSSI_INPUT();
  
  TOSH_MAKE_POT_CS_OUTPUT();
  
  TOSH_SEL_FLASH_CS_IOFUNC();
  TOSH_SET_FLASH_CS_PIN();
  TOSH_MAKE_FLASH_CS_OUTPUT(); 
}

enum
{
  TOS_ADC_RSSI_PORT,                         // RSSI
  TOS_ADC_EXTERNAL_REFERENCE_PORT,           // VeREF+ (input channel 8)
  TOS_ADC_REFERENCE_VOLTAGE_RATIO_PORT,      // VREF-/VeREF- (input channel 9)
  TOS_ADC_INTERNAL_TEMP_PORT,                // Temperature diode (input channel 10)
  TOS_ADC_INTERNAL_VOLTAGE_PORT              // (AVcc-AVss)/2 (input channel 11-15)
};

enum 
{
  TOSH_ADC_PORTMAPSIZE = 5        // this should be the number of members in the above enum
};

enum
{
  TOSH_ACTUAL_ADC_RSSI_PORT = ASSOCIATE_ADC_CHANNEL(INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_1_5), 
};

#define RSSI_ADC12_STANDARD_SETTINGS   SET_ADC12_STANDARD_SETTINGS(INPUT_CHANNEL_A0, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   REFVOLT_LEVEL_1_5)
                                                                   
#define RSSI_ADC12_ADVANCED_SETTINGS   SET_ADC12_ADVANCED_SETTINGS(INPUT_CHANNEL_A0, \
                                                                   REFERENCE_VREFplus_AVss, \
                                                                   SAMPLE_HOLD_4_CYCLES, \
                                                                   CLOCK_SOURCE_SMCLK, \
                                                                   CLOCK_DIV_1, \
                                                                   HOLDSOURCE_TIMERB_OUT0,\
                                                                   REFVOLT_LEVEL_1_5)

#endif //TOSH_HARDWARE_EYESNEDAP_H






#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#ifndef TOSH_HARDWARE_MICA2
#define TOSH_HARDWARE_MICA2
#endif // tosh hardware

#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include <avrhardware.h>
#include "CC1000Const.h"

// avrlibc may define ADC as a 16-bit register read.  This collides with the nesc
// ADC interface name
uint16_t inline getADC() {
  return inw(ADC);
}
#undef ADC

#define TOSH_CYCLE_TIME_NS 136

// each nop is 1 clock cycle
// 1 clock cycle on mica2 == 136ns
void inline TOSH_wait_250ns() {
      asm volatile  ("nop" ::);
      asm volatile  ("nop" ::);
}

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

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, A, 2);
TOSH_ASSIGN_PIN(GREEN_LED, A, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, A, 0);

TOSH_ASSIGN_PIN(SERIAL_ID, A, 4);
//TOSH_ASSIGN_PIN(BAT_MON, A, 5);
TOSH_ASSIGN_PIN(MAG_SR, A, 5);
TOSH_ASSIGN_PIN(THERM_PWR, A, 7);

// ChipCon control assignments
TOSH_ASSIGN_PIN(CC_CHP_OUT, A, 6); // chipcon CHP_OUT
TOSH_ASSIGN_PIN(CC_PDATA, D, 7);  // chipcon PDATA 
TOSH_ASSIGN_PIN(CC_PCLK, D, 6);	  // chipcon PCLK
TOSH_ASSIGN_PIN(CC_PALE, D, 4);	  // chipcon PALE

/*
//cricket control assignments
TOSH_ASSIGN_PIN(CC_PALE, G, 0);	  // chipcon PALE
TOSH_ASSIGN_PIN(US_OUT_EN, G, 2);  // ultrasonic tx enable
TOSH_ASSIGN_PIN(US_OUT, B, 7);  // ultrasonic tx 
TOSH_ASSIGN_PIN(US_IN_EN, B, 4);  // ultrasonic rx enable
TOSH_ASSIGN_PIN(US_DETECT, D, 4);  // ultrasonic rx
TOSH_ASSIGN_PIN(POT_SCK, B, 6);  // ultrasonic tx enable
TOSH_ASSIGN_PIN(POT_CS, B, 5);  // ultrasonic tx enable
TOSH_ASSIGN_PIN(RF_DETECT, G, 1);  // ultrasonic tx enable
TOSH_ALIAS_PIN(RS232_EN, BAT_MON);
*/

// xscale pin ASSIGNMENTS

TOSH_ASSIGN_PIN(PWM0,  B, 4);
TOSH_ASSIGN_PIN(PWM1A,  B, 5);
TOSH_ASSIGN_PIN(PWM1B,  B, 6);
TOSH_ASSIGN_PIN(PWM1C,  B, 7);

// Flash assignments
TOSH_ASSIGN_PIN(FLASH_SELECT, A, 3);
TOSH_ASSIGN_PIN(FLASH_CLK,  D, 5);
TOSH_ASSIGN_PIN(FLASH_OUT,  D, 3);
TOSH_ASSIGN_PIN(FLASH_IN,  D, 2);

// interrupt assignments
TOSH_ASSIGN_PIN(INT0, E, 4);
TOSH_ASSIGN_PIN(INT1, E, 5);
TOSH_ASSIGN_PIN(INT2, E, 6);
TOSH_ASSIGN_PIN(INT3, E, 7);

// spibus assignments 
TOSH_ASSIGN_PIN(MOSI,  B, 2);
TOSH_ASSIGN_PIN(MISO,  B, 3);
TOSH_ASSIGN_PIN(SPI_OC1C, B, 7);
TOSH_ASSIGN_PIN(SPI_SCK,  B, 1);

// power control assignments
TOSH_ASSIGN_PIN(PW0, C, 0);
TOSH_ASSIGN_PIN(PW1, C, 1);
TOSH_ASSIGN_PIN(PW2, C, 2);
TOSH_ASSIGN_PIN(PW3, C, 3);
TOSH_ASSIGN_PIN(PW4, C, 4);
TOSH_ASSIGN_PIN(PW5, C, 5);
TOSH_ASSIGN_PIN(PW6, C, 6);
TOSH_ASSIGN_PIN(PW7, C, 7);

// i2c bus assignments
TOSH_ASSIGN_PIN(I2C_BUS1_SCL, D, 0);
TOSH_ASSIGN_PIN(I2C_BUS1_SDA, D, 1);
TOSH_ASSIGN_PIN(ALE, G, 2);
TOSH_ASSIGN_PIN(WR, G, 0);
TOSH_ASSIGN_PIN(RD, G, 1);

// uart assignments
TOSH_ASSIGN_PIN(UART_RXD0, E, 0);
TOSH_ASSIGN_PIN(UART_TXD0, E, 1);
TOSH_ASSIGN_PIN(UART_XCK0, E, 2);

TOSH_ASSIGN_PIN(UART_RXD1, D, 2);
TOSH_ASSIGN_PIN(UART_TXD1, D, 3);
TOSH_ASSIGN_PIN(UART_XCK1, D, 5);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  /*  outp(0x00, DDRA);
  outp(0x00, DDRB);
  outp(0x00, DDRD);
  outp(0x02, DDRE);
  outp(0x02, PORTE);
  */

  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();

  TOSH_MAKE_CC_CHP_OUT_INPUT();	// modified for mica2 series
    
  TOSH_MAKE_PW7_OUTPUT();
  TOSH_MAKE_PW6_OUTPUT();
  TOSH_MAKE_PW5_OUTPUT();
  TOSH_MAKE_PW4_OUTPUT();
  TOSH_MAKE_PW3_OUTPUT(); 
  TOSH_MAKE_PW2_OUTPUT();
  TOSH_MAKE_PW1_OUTPUT();
  TOSH_MAKE_PW0_OUTPUT();

  TOSH_MAKE_CC_PALE_OUTPUT();    
  TOSH_MAKE_CC_PDATA_OUTPUT();
  TOSH_MAKE_CC_PCLK_OUTPUT();
  TOSH_MAKE_MISO_INPUT();
  TOSH_MAKE_SPI_OC1C_INPUT();

  TOSH_MAKE_SERIAL_ID_INPUT();
  TOSH_CLR_SERIAL_ID_PIN();  // Prevent sourcing current

  TOSH_MAKE_FLASH_SELECT_OUTPUT();
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
  TOSH_SET_FLASH_SELECT_PIN();
    
  TOSH_SET_RED_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_SET_GREEN_LED_PIN();


// xscale pin directions
TOSH_MAKE_PWM0_OUTPUT();
TOSH_MAKE_PWM1A_OUTPUT();
TOSH_MAKE_PWM1B_OUTPUT();
TOSH_MAKE_PWM1C_OUTPUT();
TOSH_MAKE_INT0_INPUT();
TOSH_MAKE_INT1_INPUT();
TOSH_MAKE_INT2_INPUT();
TOSH_MAKE_INT3_INPUT();
TOSH_MAKE_UART_XCK0_INPUT();
TOSH_MAKE_MAG_SR_OUTPUT();

TOSH_SET_PWM0_PIN();
TOSH_SET_PWM1C_PIN();
TOSH_SET_PW0_PIN();
TOSH_SET_PW1_PIN();
TOSH_SET_INT2_PIN();

TOSH_MAKE_WR_INPUT();
TOSH_MAKE_RD_INPUT();
TOSH_MAKE_ALE_OUTPUT();

TOSH_CLR_WR_PIN();
TOSH_CLR_ALE_PIN();


/*
// cricket pin definitions
  TOSH_MAKE_US_OUT_EN_OUTPUT(); 
  TOSH_MAKE_US_OUT_OUTPUT();
  TOSH_MAKE_US_IN_EN_OUTPUT();
  TOSH_MAKE_POT_SCK_OUTPUT();
  TOSH_MAKE_POT_CS_OUTPUT();
  TOSH_MAKE_US_DETECT_INPUT();
  TOSH_MAKE_RF_DETECT_INPUT();
*/

}

enum {
  TOSH_ADC_PORTMAPSIZE = 12
};

enum 
{
  TOSH_ACTUAL_CC_RSSI_PORT = 0,
//  TOSH_ACTUAL_THERM_PORT = 1,  // CRICKET ADDITION
  TOSH_ACTUAL_VOLTAGE_PORT = 7,
  TOSH_ACTUAL_BANDGAP_PORT = 30,  // 1.23 Fixed bandgap reference
  TOSH_ACTUAL_GND_PORT     = 31   // GND 
};

enum 
{
  TOS_ADC_CC_RSSI_PORT = 0,
//  TOS_ADC_THERM_PORT = 1,  // CRICKET ADDITION
  TOS_ADC_VOLTAGE_PORT = 7,
  TOS_ADC_BANDGAP_PORT = 10,
  TOS_ADC_GND_PORT     = 11
};

#endif //TOSH_HARDWARE_H





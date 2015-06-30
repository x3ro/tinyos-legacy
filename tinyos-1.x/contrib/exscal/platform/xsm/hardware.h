
#ifndef TOSH_HARDWARE_H
#define TOSH_HARDWARE_H

#ifndef TOSH_HARDWARE_MICA2
#define TOSH_HARDWARE_MICA2
#endif // tosh hardware

#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include <avrhardware.h>
#include <CC1000Const.h>

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
 TOSH_ASSIGN_PIN(MAG_SR, A, 5);
TOSH_ASSIGN_PIN(THERM_PWR, A, 7);

// ChipCon control assignments
TOSH_ASSIGN_PIN(CC_CHP_OUT, A, 6); // chipcon CHP_OUT
TOSH_ASSIGN_PIN(CC_PDATA, D, 7);  // chipcon PDATA 
TOSH_ASSIGN_PIN(CC_PCLK, D, 6);	  // chipcon PCLK
TOSH_ASSIGN_PIN(CC_PALE, D, 4);	  // chipcon PALE  

// xscale pin ASSIGNMENTS  
TOSH_ASSIGN_PIN(PWM0,  B, 4); 
TOSH_ASSIGN_PIN(PWM1A,  B, 5); 
TOSH_ASSIGN_PIN(PWM1B,  B, 6); 
TOSH_ASSIGN_PIN(PWM1C,  B, 7); 
TOSH_ASSIGN_PIN(AC_P,  E, 2); 
TOSH_ASSIGN_PIN(AC_N,  E, 3); 

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

// uart0 assignments
TOSH_ASSIGN_PIN(UART_RXD0, E, 0);
TOSH_ASSIGN_PIN(UART_TXD0, E, 1);
TOSH_ASSIGN_PIN(UART_XCK0, E, 2);

// uart1 assignments
TOSH_ASSIGN_PIN(UART_RXD1, D, 2);
TOSH_ASSIGN_PIN(UART_TXD1, D, 3);
TOSH_ASSIGN_PIN(UART_XCK1, D, 5);

void TOSH_SET_PIN_DIRECTIONS(void)
{
 
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();

      
  TOSH_MAKE_PW7_OUTPUT();
  TOSH_MAKE_PW6_OUTPUT();
  TOSH_MAKE_PW5_OUTPUT();
  TOSH_MAKE_PW4_OUTPUT();
  TOSH_MAKE_PW3_OUTPUT(); 
  TOSH_MAKE_PW2_OUTPUT();
  TOSH_MAKE_PW1_OUTPUT();   // not used
  TOSH_MAKE_PW0_OUTPUT();

 //cc1000 control lines
TOSH_MAKE_CC_CHP_OUT_INPUT();	// modified for mica2 series   TOSH_MAKE_CC_PALE_OUTPUT();    
TOSH_MAKE_CC_PDATA_OUTPUT();
TOSH_MAKE_CC_PCLK_OUTPUT();
TOSH_MAKE_MISO_INPUT();
TOSH_MAKE_SPI_OC1C_INPUT();

TOSH_MAKE_SERIAL_ID_INPUT();
TOSH_MAKE_THERM_PWR_OUTPUT();     
TOSH_MAKE_ALE_OUTPUT();      //mux I2C, 10K pullup     TOSH_MAKE_PWM1B_OUTPUT();     //beeper  pulse

//serial flash   
TOSH_MAKE_FLASH_SELECT_OUTPUT();
TOSH_MAKE_FLASH_OUT_OUTPUT();
TOSH_MAKE_FLASH_CLK_OUTPUT();
TOSH_SET_FLASH_SELECT_PIN();
    
// xscale pin directions  //leds   TOSH_SET_RED_LED_PIN();
TOSH_SET_YELLOW_LED_PIN();
TOSH_SET_GREEN_LED_PIN();
TOSH_MAKE_INT0_INPUT();  
TOSH_MAKE_INT1_INPUT();   
TOSH_MAKE_INT2_INPUT();   
TOSH_MAKE_INT3_INPUT();   
TOSH_MAKE_UART_XCK0_INPUT();   
TOSH_MAKE_MAG_SR_OUTPUT();    
TOSH_MAKE_PWM0_INPUT();    

//quad detect pins  
TOSH_MAKE_PWM1A_INPUT();   
TOSH_MAKE_AC_N_INPUT();   
TOSH_MAKE_AC_P_INPUT();    
TOSH_CLR_PW0_PIN(); 

//photo power off   
TOSH_SET_PW2_PIN();            
//sounder power off   
TOSH_SET_PW3_PIN();  
//mic power off   
TOSH_CLR_PW4_PIN();
//accel power off
TOSH_SET_PW5_PIN(); 
//mag power off   
TOSH_SET_PW6_PIN();
//PIR power off
TOSH_SET_MAG_SR_PIN();         //if low then 300uA of current!   TOSH_CLR_THERM_PWR_PIN();      //thermistor power off   TOSH_SET_ALE_PIN();            //I2C select,10K pullup  

// define and set grenade timer pins last
TOSH_MAKE_WR_OUTPUT();         //grenade timer, 100k pulldown   TOSH_MAKE_RD_OUTPUT();         //grenade timer, 10K pullup     TOSH_CLR_WR_PIN();             //grenade timer, 100k pulldown   TOSH_SET_RD_PIN();             //grenade timer, 10K pullup  
}

enum {
  TOSH_ADC_PORTMAPSIZE = 12
};

enum 
{
  TOSH_ACTUAL_CC_RSSI_PORT = 0,   TOSH_ACTUAL_VOLTAGE_PORT = 7,
  TOSH_ACTUAL_BANDGAP_PORT = 30,  // 1.23 Fixed bandgap reference
  TOSH_ACTUAL_GND_PORT     = 31   // GND 
};

enum 
{
  TOS_ADC_CC_RSSI_PORT = 0,   TOS_ADC_VOLTAGE_PORT = 7,
  TOS_ADC_BANDGAP_PORT = 10,
  TOS_ADC_GND_PORT     = 11
};

#endif //TOSH_HARDWARE_H

 
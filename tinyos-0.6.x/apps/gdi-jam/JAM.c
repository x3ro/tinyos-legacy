/*									tab:4
 * JAM.c - display sensor value on the LEDs
 *
 */

#include "tos.h"
#include "JAM.h"

//Frame Declaration
#define TOS_FRAME_TYPE JAM_frame
TOS_FRAME_BEGIN(JAM_frame) {
}
TOS_FRAME_END(JAM_frame);

/* JAM_INIT: 
   Clear all the LEDs and initialize state
*/
volatile int val = 0;

char TOS_COMMAND(JAM_INIT)(){
  return 1;
}

/* JAM_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(JAM_START)(){
  volatile int *ptr = &val;
  TOS_CALL_COMMAND(JAM_CLOCK_INIT)(tick4ps); 


//  outp(0x00, DDRA);
//  outp(0x00, DDRB);
//  outp(0x00, DDRD);
//  outp(0x00, DDRE);
//  outp(0xff, PORTA);
//  outp(0xff, PORTB);
//  outp(0xff, PORTC);
//  outp(0xff, PORTD);
//
//  MAKE_RED_LED_OUTPUT();
//  MAKE_GREEN_LED_OUTPUT();
//  MAKE_YELLOW_LED_OUTPUT();
//
//  CLR_FLASH_IN_PIN();
//
//  MAKE_RFM_CTL0_OUTPUT();
//  MAKE_RFM_CTL1_OUTPUT();
//  CLR_RFM_CTL0_PIN();
//  CLR_RFM_CTL1_PIN();
//
//  MAKE_POT_SELECT_OUTPUT();
//  SET_POT_SELECT_PIN();
///// CLR_
//
//  MAKE_RFM_TXD_OUTPUT();
//  CLR_RFM_TXD_PIN();
//
//  MAKE_POT_POWER_OUTPUT();
//  SET_POT_POWER_PIN();
//
//  MAKE_ONE_WIRE_OUTPUT();
//  CLR_ONE_WIRE_PIN();
//
//  MAKE_BOOST_ENABLE_OUTPUT();
//  CLR_BOOST_ENABLE_PIN();

  //set the RFM pins.
  SET_RFM_CTL0_PIN();
  CLR_RFM_CTL1_PIN();
  SET_RFM_TXD_PIN();
  set_pot(50);

  while(1)
    *ptr++;

  return 1;
}

/* Clock Event Handler:
   Increment counter and display
 */
void TOS_EVENT(JAM_CLOCK_EVENT)(){
  TOS_CALL_COMMAND(JAM_LEDy_toggle)();
  TOS_CALL_COMMAND(JAM_LEDr_toggle)();
  TOS_CALL_COMMAND(JAM_LEDg_toggle)();
}




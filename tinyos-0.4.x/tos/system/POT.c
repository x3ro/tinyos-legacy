/* Potentiometer control component

 Author: Vladimir Bychkovskiy
 
 Functionality: Set and get poteniometer value (transmit power)

 USAGE:

  POT_INIT(char power)
      - reset the potentiometer device and set the initial value(see below)

  POT_SET(char power)
      - set new potentiometer value (see below)
      
  POT_GET()
      - get current setting of the potentiometer

  POT_INC()
  POT_DEC()
      - increment (decrement) current setting by 1

  Potentiometer setting vs. transmit power
   Valid range: 0 (low power) - 99 (high power)
   
   Note: transmit power is NOT linear w.r.t. potentiometer setting,
   see mote schematics & RFM chip manual for more information
 */


#include "tos.h"
#include "POT.h"

#define TOS_FRAME_TYPE POT_frame
TOS_FRAME_BEGIN(POT_frame) {
  char pot_setting;
}
TOS_FRAME_END(POT_frame);

void decrease_r() {
    SET_UD_PIN();
    CLR_POT_SELECT_PIN();
    SET_INC_PIN();
    CLR_INC_PIN();
    SET_POT_SELECT_PIN();
}

void increase_r() {
    CLR_UD_PIN();
    CLR_POT_SELECT_PIN();
    SET_INC_PIN();
    CLR_INC_PIN();
    SET_POT_SELECT_PIN();
}

void set_pot(char value) {
    unsigned char i;
    for (i=0; i < 200; i++) {
        decrease_r();
    }
    for (i=0; i < value; i++) {
        increase_r();
    }
    SET_UD_PIN();
    SET_INC_PIN();
}


char TOS_COMMAND(POT_INIT)(char val) {
  set_pot(val);
  VAR(pot_setting) = val;
  return 1;
}

void TOS_COMMAND(POT_SET)(char val) {
  set_pot(val);
  VAR(pot_setting) = val;
}

void TOS_COMMAND(POT_INC)(void) {
  increase_r();
  SET_UD_PIN();
  SET_INC_PIN();
  VAR(pot_setting)++;
}

void TOS_COMMAND(POT_DEC)(void) {
  decrease_r();
  SET_UD_PIN();
  SET_INC_PIN();
  VAR(pot_setting)--;
}

char TOS_COMMAND(POT_GET)(void) {
  return VAR(pot_setting);
}

























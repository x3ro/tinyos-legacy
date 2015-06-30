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

void decrease_r() {
  if (THIS_NODE.pot_setting > 0) {
    THIS_NODE.pot_setting--;
  }
}

void increase_r() {
  if (THIS_NODE.pot_setting < 200) {
    THIS_NODE.pot_setting++;
  }
}

void set_pot(char value) {
  if (value >= 0 && value <= 200) {
    THIS_NODE.pot_setting = value;
  }
}


char TOS_COMMAND(POT_INIT)(char val) {
  set_pot(val);
  return 1;
}

void TOS_COMMAND(POT_SET)(char val) {
  set_pot(val);
}

void TOS_COMMAND(POT_INC)(void) {
  increase_r();
}

void TOS_COMMAND(POT_DEC)(void) {
  decrease_r();
}

char TOS_COMMAND(POT_GET)(void) {
  return THIS_NODE.pot_setting;
}

























/* Transmission Power remote control component */

#include "tos.h"
#include "POWER_RC.h"

// index of command and data portions in the data packet (should be chaned into a structure)
#define POT_CMD_IDX 0
#define POT_VAL_IDX 1

// different command that can be given to this component
#define GET_POT_SETTING 2
#define WRITE_POT_SETTING 1
#define SET_POT 0

// address in on-chip eeprom where the power setting is stored
#define POT_SETTING_ADDR 0

char TOS_COMMAND(POWER_RC_INIT)()
{
  uint8_t tmp;
  
  // Initialize potentiameter.
  // Read value from EEPROM
  TOS_CALL_COMMAND(POWER_RC_OCEEPROM_READ)(POT_SETTING_ADDR, 1, &tmp);
  // Set potentiometer
  TOS_CALL_COMMAND(POWER_RC_POT_INIT)(tmp);

  return 1;
}


TOS_MsgPtr TOS_MSG_EVENT(POWER_RC_RX_POT_MSG)(TOS_MsgPtr datMsg)
{
  
  switch(datMsg->data[POT_CMD_IDX]) {
  case GET_POT_SETTING:
    TOS_CALL_COMMAND(POWER_RC_OCEEPROM_READ)(POT_SETTING_ADDR, 1, &(datMsg->data[POT_VAL_IDX]) );
    break;

  case WRITE_POT_SETTING:
    TOS_CALL_COMMAND(POWER_RC_OCEEPROM_WRITE)(POT_SETTING_ADDR, 1, &(datMsg->data[POT_VAL_IDX]) );
    // fall through

  case SET_POT:
    TOS_CALL_COMMAND(POWER_RC_POT_SET)(datMsg->data[POT_VAL_IDX]);
    break;
  }

  // Modify address to avoid confusing neighbors with the bouced response
  // the case of broadcast ( modified per request of Rohit and MHR )
  datMsg->addr=-2;

  TOS_CALL_COMMAND(POWER_RC_TX_MSG)(datMsg);
  return datMsg;
}





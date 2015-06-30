/* @(#)onoff.h
 */

enum { 
  AM_ONOFF_MSG = 249
};

typedef struct OnOff_Msg {
  bool action;
  uint8_t command_id;
} OnOff_Msg;

#ifndef __CHIRP___
#define __CHIRP___
#include "super.h"
//ACCEPTS
char TOS_COMMAND(CHIRP_INIT)(void);
char TOS_COMMAND(CHIRP_START)(void);
//HANDLES
void TOS_EVENT(CHIRP_CLOCK_EVENT)(void);
char TOS_EVENT(CHIRP_DATA_EVENT)(int data);
TOS_MsgPtr TOS_EVENT(CHIRP_MSG)(TOS_MsgPtr data);
char TOS_EVENT(CHIRP_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg);
//SIGNALS
//USES
char TOS_COMMAND(CHIRP_CLOCK_INIT)(char interval, char scale);
char TOS_COMMAND(CHIRP_GET_DATA)(void);
char TOS_COMMAND(CHIRP_LEDg_off)(void);
char TOS_COMMAND(CHIRP_LEDg_on)(void);
char TOS_COMMAND(CHIRP_LEDr_off)(void);
char TOS_COMMAND(CHIRP_LEDr_on)(void);
char TOS_COMMAND(CHIRP_LEDy_off)(void);
char TOS_COMMAND(CHIRP_LEDy_on)(void);
char TOS_COMMAND(CHIRP_SUB_INIT)(void);
char TOS_COMMAND(CHIRP_SUB_PWR)(char pwr);
char TOS_COMMAND(CHIRP_SUB_SEND_MSG)(short addr,char type, TOS_MsgPtr data);
//INTERNAL
#endif //__CHIRP___//

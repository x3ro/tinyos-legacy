#ifndef __DIAG___
#define __DIAG___
#include "super.h"
//ACCEPTS
char TOS_COMMAND(DIAG_INIT)(void);
char TOS_COMMAND(DIAG_SEND_MSG)(void);
char TOS_COMMAND(DIAG_START)(void);
//HANDLES
void TOS_EVENT(DIAG_CLOCK_EVENT)(void);
char TOS_EVENT(DIAG_MSG_SEND_DONE)(TOS_MsgPtr data);
TOS_MsgPtr TOS_EVENT(DIAG_RX_PACKET)(TOS_MsgPtr data);
//SIGNALS
//USES
char TOS_COMMAND(DIAG_CLOCK_INIT)(char interval, char scale);
char TOS_COMMAND(DIAG_FLASH_RX)();
char TOS_COMMAND(DIAG_FLASH_TX)();
char TOS_COMMAND(DIAG_GET_DATA)(char port);
char TOS_COMMAND(DIAG_LEDg_off)();
char TOS_COMMAND(DIAG_LEDg_on)();
char TOS_COMMAND(DIAG_LEDr_off)();
char TOS_COMMAND(DIAG_LEDr_on)();
char TOS_COMMAND(DIAG_LEDy_off)();
char TOS_COMMAND(DIAG_LEDy_on)();
char TOS_COMMAND(DIAG_RX_FLASH)();
char TOS_COMMAND(DIAG_SUB_INIT)();
char TOS_COMMAND(DIAG_SUB_SEND_MSG)(short addr,char type, TOS_MsgPtr data);
char TOS_COMMAND(DIAG_TX_FLASH)();
//INTERNAL
#endif //__DIAG___//

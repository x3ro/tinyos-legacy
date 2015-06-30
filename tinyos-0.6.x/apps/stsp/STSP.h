#ifndef __STSP___
#define __STSP___
#include "super.h"
//ACCEPTS
char TOS_COMMAND(STSP_INIT)();
char TOS_COMMAND(STSP_START)();
//HANDLES
void TOS_EVENT(STSP_CLOCK_OVERFLOW)();
TOS_MsgPtr TOS_EVENT(STSP_MSG)(TOS_MsgPtr data);
char TOS_EVENT(STSP_SEND_DONE)(TOS_MsgPtr data);
//SIGNALS
//USES
char TOS_COMMAND(STSP_CLOCK_INIT)(char scale, char interval);
char TOS_COMMAND(STSP_GREEN_TOGGLE)();
char TOS_COMMAND(STSP_RED_TOGGLE)();
char TOS_COMMAND(STSP_SUB_INIT)();
char TOS_COMMAND(STSP_SUB_SEND)(short addr,char type, TOS_MsgPtr data);
char TOS_COMMAND(STSP_YELLOW_TOGGLE)();
//INTERNAL
#endif //__STSP___//

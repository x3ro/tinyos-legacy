#ifndef __NARPRO_PING___
#define __NARPRO_PING___
#include "super.h"
//ACCEPTS
char TOS_COMMAND(NARPRO_PING_INIT)();
char TOS_COMMAND(NARPRO_PING_POWER)(char mode);
char TOS_COMMAND(NARPRO_PING_SEND)(short moteID, char sequence);
char TOS_COMMAND(NARPRO_PING_START)();
//HANDLES
TOS_MsgPtr TOS_EVENT(NARPRO_PING_MSG)(TOS_MsgPtr data);
char TOS_EVENT(NARPRO_PING_SEND_DONE)(TOS_MsgPtr data);
//SIGNALS
char TOS_EVENT(NARPRO_PING_RECEIVE)(short moteID, char sequence);
char TOS_EVENT(NARPRO_PING_RESPONSE)(short moteID, char sequence);
//USES
char TOS_COMMAND(NARPRO_PING_SUB_INIT)();
char TOS_COMMAND(NARPRO_PING_SUB_POWER)(char mode);
char TOS_COMMAND(NARPRO_PING_SUB_SEND_MSG)(short addr,char type, TOS_MsgPtr data);
char TOS_COMMAND(NARPRO_PING_SUB_START)();
//INTERNAL
#endif //__NARPRO_PING___//

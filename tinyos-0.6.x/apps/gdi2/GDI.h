#ifndef __GDI___
#define __GDI___
#include "super.h"
//ACCEPTS
char TOS_COMMAND(GDI_INIT)(void);
char TOS_COMMAND(GDI_START)(void);
//HANDLES
void TOS_EVENT(GDI_CLOCK_EVENT)();
char TOS_EVENT(GDI_SNOOZE_WAKEUP)();
//SIGNALS
//USES
char TOS_COMMAND(GDI_CLOCK_INIT)(char interval, char scale);
char TOS_COMMAND(GDI_SUB_SNOOZE)(unsigned short time);
//INTERNAL
#endif //__GDI___//

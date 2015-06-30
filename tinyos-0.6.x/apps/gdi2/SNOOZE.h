#ifndef __SNOOZE___
#define __SNOOZE___
#include "super.h"
//ACCEPTS
char TOS_COMMAND(SNOOZE_AWHILE)(unsigned short timeout);
char TOS_COMMAND(SNOOZE_INIT)(void);
//HANDLES
//SIGNALS
char TOS_EVENT(SNOOZE_WAKEUP)(void);
//USES
//INTERNAL
#endif //__SNOOZE___//

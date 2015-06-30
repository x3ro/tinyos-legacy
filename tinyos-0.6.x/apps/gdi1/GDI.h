#ifndef __GDI___
#define __GDI___
#include "super.h"
//ACCEPTS
char TOS_COMMAND(GDI_INIT)(void);
char TOS_COMMAND(GDI_START)(void);
//HANDLES
char TOS_EVENT(GDI_PHOTO_DATA_READY)(short data);
//SIGNALS
//USES
char TOS_COMMAND(GDI_SUB_PHOTO_GET_DATA)();
//INTERNAL
#endif //__GDI___//

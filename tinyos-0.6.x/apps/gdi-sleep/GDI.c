/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * GDI - 
 * 
 */

#include "tos.h"
#include "GDI.h"

#define TOS_FRAME_TYPE GDI_obj_frame
TOS_FRAME_BEGIN(GDI_obj_frame) {
}
TOS_FRAME_END(GDI_obj_frame);

//
// Task: sleep again
//
TOS_TASK(snooze_again)
{
    TOS_CALL_COMMAND(GDI_RED_LED_ON)();
    TOS_CALL_COMMAND(GDI_RED_LED_OFF)();
    TOS_CALL_COMMAND(GDI_SUB_SNOOZE)(32 * 4);
}

//
// Event: snooze wakeup
//
char TOS_EVENT(GDI_SNOOZE_WAKEUP)()
{
    TOS_POST_TASK(snooze_again);
    return(0);
}

//
// init
//
char TOS_COMMAND(GDI_INIT)()
{
    return(1);
}

//
// start
//
char TOS_COMMAND(GDI_START)()
{
    TOS_CALL_COMMAND(GDI_CLOCK_INIT)(tick1ps); 
    TOS_POST_TASK(snooze_again);
    return(1);
}

void TOS_EVENT(GDI_CLOCK_EVENT)(){
}

/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * GDI - 
 * 
 */

#include "tos.h"
#include "GDI.h"

#define TOS_FRAME_TYPE GDI_obj_frame
TOS_FRAME_BEGIN(GDI_obj_frame) {
    int count;
    int bar;
}
TOS_FRAME_END(GDI_obj_frame);

// Task: photo data
TOS_TASK(take_photo_reading)
{
    TOS_CALL_COMMAND(GDI_SUB_PHOTO_GET_DATA)();
}

// Event: photo data ready
char TOS_EVENT(GDI_PHOTO_DATA_READY)(short data) 
{
    VAR(count)++;
    TOS_CALL_COMMAND(GDI_RED_LED_ON)();
    TOS_CALL_COMMAND(GDI_GREEN_LED_ON)();
    TOS_CALL_COMMAND(GDI_YELLOW_LED_ON)();
    TOS_POST_TASK(take_photo_reading);
    return(1);
}

// init
char TOS_COMMAND(GDI_INIT)()
{
    VAR(count)=0;
    return(1);
}

// start
char TOS_COMMAND(GDI_START)()
{
    TOS_POST_TASK(take_photo_reading);
    return(1);
}

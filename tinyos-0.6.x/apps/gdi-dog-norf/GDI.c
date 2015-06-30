/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * GDI - 
 * 
 */

#include "tos.h"
#include "GDI.h"

typedef struct {
    short photo_data;
    short temp_data;
    short volts_data;
} gdimsg_t;

#define TOS_FRAME_TYPE GDI_obj_frame
TOS_FRAME_BEGIN(GDI_obj_frame) {
    TOS_Msg msg_buf;
    TOS_MsgPtr msg;
    short photo_data;
    short temp_data;
    short volts_data;
}
TOS_FRAME_END(GDI_obj_frame);

//
// Task: photo data
//
TOS_TASK(take_photo_reading)
{
    TOS_CALL_COMMAND(GDI_SUB_IPHOTO_GET_DATA)();
}

//
// Task: temp data
//
TOS_TASK(take_temp_reading)
{
    TOS_CALL_COMMAND(GDI_SUB_ITEMP_GET_DATA)();
}

//
// Task: volts data
//
TOS_TASK(take_volts_reading)
{
    TOS_CALL_COMMAND(GDI_SUB_IVOLTS_GET_DATA)();
}

//
// Task: sleep
//
TOS_TASK(snooze_again)
{
    TOS_CALL_COMMAND(GDI_SUB_SNOOZE)(0x7);
}

//
// Event: clock
//
void TOS_EVENT(GDI_CLOCK_EVENT)()
{
}

//
// Event: volts data ready
//
char TOS_EVENT(GDI_IVOLTS_DATA_READY)(short data) 
{
    VAR(volts_data) = data;
    TOS_POST_TASK(snooze_again);
    return(0);
}

//
// Event: temp data ready
//
char TOS_EVENT(GDI_ITEMP_DATA_READY)(short data) 
{
    VAR(temp_data) = data;
    TOS_POST_TASK(take_volts_reading);
    return(0);
}

//
// Event: photo data ready
//
char TOS_EVENT(GDI_IPHOTO_DATA_READY)(short data) 
{
    VAR(photo_data) = data;
    TOS_POST_TASK(take_temp_reading);
    return(0);
}

//
// init
//
char TOS_COMMAND(GDI_INIT)()
{
    VAR(msg) = &VAR(msg_buf);
    return(1);
}

//
// start
//
char TOS_COMMAND(GDI_START)()
{
    TOS_CALL_COMMAND(GDI_RED_LED_ON)();
    TOS_CALL_COMMAND(GDI_GREEN_LED_ON)();
    TOS_CALL_COMMAND(GDI_YELLOW_LED_ON)();

    TOS_CALL_COMMAND(GDI_SUB_SET_POT_POWER)(95);
    TOS_CALL_COMMAND(GDI_CLOCK_INIT)(tick1ps); 
    TOS_POST_TASK(take_photo_reading);
    return(1);
}

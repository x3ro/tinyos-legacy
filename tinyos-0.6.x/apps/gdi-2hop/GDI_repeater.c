/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * GDI - 
 * 
 */

#include "tos.h"
#include "GDI_repeater.h"
#include "eeprom.h"

#define TRANSMITPOWER (1)

#define TOS_FRAME_TYPE GDI_repeater_obj_frame
TOS_FRAME_BEGIN(GDI_repeater_obj_frame) {
    TOS_Msg msg_buf;
    TOS_MsgPtr msg;
    TOS_MsgPtr msg_tmp;
    char wb_state;
    char repeater_msg_send_pending;
    short photo_data;
    short temp_data;
    short thermopile_data;
    short thermistor_data;
    short humidity_data;
    short volts_data;
    short clock;
    int wakeups;
    int lastw;
    int tog;
}
TOS_FRAME_END(GDI_repeater_obj_frame);

TOS_MsgPtr TOS_MSG_EVENT(GDI_BASE_MSG)(TOS_MsgPtr msg)
{
	TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
	return (msg);
}

TOS_MsgPtr TOS_MSG_EVENT(GDI_REPEATER_MSG)(TOS_MsgPtr msg)
{
	TOS_CALL_COMMAND(RED_LED_TOGGLE)();
    VAR(msg_tmp) = msg;
    if (VAR(repeater_msg_send_pending) == 0)
    {
	    VAR(repeater_msg_send_pending) = 1;
	    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(TOS_BCAST_ADDR,
		AM_MSG(GDI_BASE_MSG),
		VAR(msg_tmp));
    }
    return(msg);
}

//
// Event: message handler
//
TOS_MsgPtr TOS_MSG_EVENT(GDI_UPDATE_MSG)(TOS_MsgPtr msg)
{
	TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
    VAR(msg_tmp) = msg;
    if (VAR(repeater_msg_send_pending) == 0)
    {
	    VAR(repeater_msg_send_pending) = 1;
	    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(TOS_BCAST_ADDR,
		AM_MSG(GDI_BASE_MSG),
		VAR(msg_tmp));
    }
    return(msg);
}


//
// Event: send done
//
char TOS_EVENT(GDI_SEND_DONE)(TOS_MsgPtr msg)
{
    if (VAR(repeater_msg_send_pending) == 1)
	VAR(repeater_msg_send_pending) = 0;

    return(1);
}

//
// init
//
char TOS_COMMAND(GDI_INIT)()
{
    VAR(msg) = &VAR(msg_buf);
    VAR(repeater_msg_send_pending) = 0;
    VAR(wakeups) = 0;
    VAR(lastw) = 0;
    VAR(tog) = 0;
    VAR(wb_state) = 0;
    VAR(clock) = 0;
    return(1);
}

//
// start
//
char TOS_COMMAND(GDI_START)()
{
    TOS_CALL_COMMAND(GDI_SUB_SET_POT_POWER)(TRANSMITPOWER);
    TOS_CALL_COMMAND(GDI_CLOCK_INIT)(tick1ps); 
    return(1);
}

void TOS_EVENT(GDI_CLOCK_EVENT)(){

}

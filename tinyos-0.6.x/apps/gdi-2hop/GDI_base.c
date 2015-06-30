/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * GDI - 
 * 
 * includes routing
 * note that even numbered nodes are one level deep in the tree
 * odd nodes are two levels deep and send to (TOS_LOCAL_ADDRESS - 1)
 * as their parent
 *
 * Authors:    Joe Polastre, Rob Szewczyk, Alan Mainwaring
 *
 * Last Modified: July 5th, 2002
 *
 */

#include "tos.h"
#include "GDI_base.h"
#include "eeprom.h"

#define TRANSMITPOWER (10)

#define BASE_STATION    1


#define TOS_FRAME_TYPE GDI_base_obj_frame
TOS_FRAME_BEGIN(GDI_base_obj_frame) {
    TOS_Msg msg_buf;
    TOS_MsgPtr msg;
    TOS_Msg msg_time_buf;
    TOS_MsgPtr msg_time;
    unsigned long int time;
}
TOS_FRAME_END(GDI_base_obj_frame);


//
// Event: message handler
//
TOS_MsgPtr TOS_MSG_EVENT(GDI_UPDATE_MSG)(TOS_MsgPtr msg)
{
    TOS_CALL_COMMAND(RED_LED_TOGGLE)();

    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(TOS_UART_ADDR,
       AM_MSG(GDI_UPDATE_MSG),
       msg);
    return(msg);
}

TOS_MsgPtr TOS_MSG_EVENT(GDI_TIMESYNC_SEND_MSG)(TOS_MsgPtr msg)
{
    // respond to our child with the current time
    short* data = (short*)msg->data;
    unsigned long int* data2 = (unsigned long int*)VAR(msg_time)->data;
    data2[0] = VAR(time);

    TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();

    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(data[0],
       AM_MSG(GDI_TIMESYNC_RECV_MSG),
       VAR(msg_time));
	    
    return(msg);
}

TOS_MsgPtr TOS_MSG_EVENT(GDI_TIMESYNC_RECV_MSG)(TOS_MsgPtr msg)
{
    return msg;
}

//
// Event: send done
//
char TOS_EVENT(GDI_SEND_DONE)(TOS_MsgPtr msg)
{
	return 1;
}

//
// init
//
char TOS_COMMAND(GDI_INIT)()
{
    VAR(msg) = &VAR(msg_buf);
    VAR(msg_time) = &VAR(msg_time_buf);
    VAR(time) = 0;              // initialize time and then sync
    return(1);
}

//
// start
//
char TOS_COMMAND(GDI_START)()
{
    TOS_CALL_COMMAND(GDI_SUB_SET_POT_POWER)(TRANSMITPOWER);
    TOS_CALL_COMMAND(GDI_CLOCK_INIT)(tick16ps); 
    return(1);
}

void TOS_EVENT(GDI_CLOCK_EVENT)(){
	TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
	VAR(time)++;
	// every day reset the clock
	if (VAR(time) > 1382400)
		VAR(time) = 1;
}

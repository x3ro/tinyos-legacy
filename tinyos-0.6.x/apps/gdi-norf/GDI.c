/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * GDI - 
 * 
 */

#include "tos.h"
#include "GDI.h"

typedef struct {
    int seqno;
    int wakeups;
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
    int wakeups;
    int lastw;
    int seqno;
    int tog;
}
TOS_FRAME_END(GDI_obj_frame);

//
// Event: message handler
//
//TOS_MsgPtr TOS_MSG_EVENT(GDI_UPDATE)(TOS_MsgPtr msg)
//{
//    return(msg);
//}

//
// Task: broadcast readings
//
//TOS_TASK(send_readings)
//{
//    gdimsg_t *m = (gdimsg_t *) VAR(msg);
//    m->seqno = VAR(seqno)++;
//    m->wakeups = VAR(wakeups);
//    m->photo_data = VAR(photo_data);
//    m->temp_data = VAR(temp_data);
//    m->volts_data = VAR(volts_data);
//
//    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(TOS_BCAST_ADDR,
//				       AM_MSG(GDI_UPDATE),
//				       VAR(msg));
//}

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
// Task: sleep again
//
TOS_TASK(snooze_again)
{
//    unsigned short time = (unsigned short) 
//	TOS_CALL_COMMAND(GDI_SUB_LFSR_NEXT_RAND)();

//    time %= 8;	// 0 to 7 second sleep times
//    time++;	// really want 1 to 8 seconds
//    time *= 32;	// scale for snoozing

    TOS_CALL_COMMAND(GDI_SUB_SNOOZE)(32 * 1);
}

//
// Task: wakeup reset
//
TOS_TASK(wakeup_reset)
{
//    TOS_CALL_COMMAND(GDI_XINIT)();
//    (void) toggle_leds();

    (void) set_all_leds();
    mydelay(32000);

    TOS_POST_TASK(take_photo_reading);
}

//
// Event: volts data ready
//
char TOS_EVENT(GDI_IVOLTS_DATA_READY)(short data) 
{
    VAR(volts_data) = data;
//  TOS_POST_TASK(send_readings);
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
// Event: snooze wakeup
//
char TOS_EVENT(GDI_SNOOZE_WAKEUP)()
{
    TOS_POST_TASK(wakeup_reset);
    VAR(wakeups)++;
    return(0);
}

//
// Event: send done
//
char TOS_EVENT(GDI_SEND_DONE)(TOS_MsgPtr msg)
{
    TOS_POST_TASK(snooze_again);
    return(0);
}

//
// init
//
char TOS_COMMAND(GDI_INIT)()
{
    VAR(msg) = &VAR(msg_buf);
    VAR(wakeups) = 0;
    VAR(lastw) = 0;
    VAR(seqno) = 0;
    VAR(tog) = 0;
    return(1);
}

//
// start
//
char TOS_COMMAND(GDI_START)()
{
    TOS_CALL_COMMAND(GDI_SUB_SET_POT_POWER)(95);
    TOS_CALL_COMMAND(GDI_CLOCK_INIT)(tick1ps); 
    TOS_POST_TASK(take_photo_reading);
    return(1);
}

void TOS_EVENT(GDI_CLOCK_EVENT)(){
//    if((VAR(wakeups) != VAR(lastw))) {
//	VAR(lastw) = VAR(wakeups);
//
//	TOS_POST_TASK(take_photo_reading);
//	toggle_leds();
//    }
}

void toggle_leds() {
    if(VAR(tog)==0) {
	TOS_CALL_COMMAND(GDI_RED_LED_ON)();
	TOS_CALL_COMMAND(GDI_GREEN_LED_ON)();
	TOS_CALL_COMMAND(GDI_YELLOW_LED_ON)();
	VAR(tog)=1;
    } else {
	TOS_CALL_COMMAND(GDI_RED_LED_OFF)();
	TOS_CALL_COMMAND(GDI_GREEN_LED_OFF)();
	TOS_CALL_COMMAND(GDI_YELLOW_LED_OFF)();
	VAR(tog)=0;
    }
}

void set_all_leds() {
    TOS_CALL_COMMAND(GDI_RED_LED_ON)();
    TOS_CALL_COMMAND(GDI_GREEN_LED_ON)();
    TOS_CALL_COMMAND(GDI_YELLOW_LED_ON)();
}

volatile int gval;
 barf() { gval++; };
 mydelay(int i) { while(--i >= 0) barf(); }

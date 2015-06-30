/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * GDI - 
 * 
 */

#include "tos.h"
#include "GDI.h"

#define TOS_FRAME_TYPE GDI_obj_frame
TOS_FRAME_BEGIN(GDI_obj_frame) {
    volatile int wakeups;
    volatile int lastw;
    int tog;
}
TOS_FRAME_END(GDI_obj_frame);

TOS_TASK(do_it_again){
    TOS_CALL_COMMAND(GDI_SUB_SNOOZE)(32*2);
}

char TOS_EVENT(GDI_SNOOZE_WAKEUP)(){
    TOS_POST_TASK(do_it_again);
    toggle_leds();
    mydelay(1024);
    VAR(wakeups)++;
    return(0);
}

void TOS_EVENT(GDI_CLOCK_EVENT)(){
//    if((VAR(wakeups) - VAR(lastw)) != 0) {
//	toggle_leds();

//	VAR(lastw) = VAR(wakeups);
//	TOS_POST_TASK(do_it_again);
//    }
}

char TOS_COMMAND(GDI_INIT)(){
    VAR(wakeups) = 0;
    VAR(lastw) = 0;
    VAR(tog) = 0;
    return(1);
}

char TOS_COMMAND(GDI_START)(){
    TOS_CALL_COMMAND(GDI_CLOCK_INIT)(tick1ps); 
    TOS_POST_TASK(do_it_again);
    return(1);
}

toggle_leds() {
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


int xx;

barf()
{
    xx++;
}

mydelay(int i)
{
    while(--i >= 0) barf();
}

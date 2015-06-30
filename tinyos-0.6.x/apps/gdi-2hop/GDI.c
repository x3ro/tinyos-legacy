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
 * Last Modified: July 9th, 2002
 *
 * $Id: GDI.c,v 1.2 2002/07/13 19:53:13 jpolastre Exp $
 *
 *
 */

#include "tos.h"
#include "GDI.h"
#include "eeprom.h"

#define TRANSMITPOWER (10)

#define BASE_STATION    1

// wake up every 30 seconds
#define SLEEP_INTERVAL  30

// 1 second delay
#define PARENT_DELAY    16

// 2 second delay before sensing
#define SENSING_DELAY   32

// sensor codes for MICAWB_PHOTO
#define PHOTO           1
#define THERMOPILE      2
#define THERMISTOR      3
#define HUMIDITY        4
#define TEMP            5

typedef struct {
    unsigned char sender_id;
    unsigned short photo_data;
    unsigned short temp_data;
    unsigned short thermopile_data;
    unsigned short thermistor_data;
    unsigned short humidity_data;
    unsigned char volts_data;
    unsigned long int seqno;
} gdimsg_t;

#define TOS_FRAME_TYPE GDI_obj_frame
TOS_FRAME_BEGIN(GDI_obj_frame) {
    TOS_Msg msg_buf;
    TOS_Msg msg_time_buf;
    TOS_MsgPtr msg;
    TOS_MsgPtr msg_time;
    TOS_MsgPtr tmpmsg;
    char wb_state;
    char timesync_msg_send_pending;
    char relay_msg_pending;
    short photo_data;
    short temp_data;
    short thermopile_data;
    short thermistor_data;
    short humidity_data;
    short volts_data;
    short snooze_time;
    char wait_time;
    char wb_wait;
    char time_reqs;
    int wakeups;
    int lastw;
    int tog;
    unsigned long int time;
}
TOS_FRAME_END(GDI_obj_frame);

// figure out how much time we should sleep for until the next wakeup
short calc_next_wakeup() {
    short delta_t;
    short current_delta;
    if (TOS_LOCAL_ADDRESS % 2 == 0)
	    delta_t = ((TOS_LOCAL_ADDRESS / 2) % SLEEP_INTERVAL) * 16;
    else
	    delta_t = ((TOS_LOCAL_ADDRESS / 2) % SLEEP_INTERVAL) * 16;
    current_delta = (VAR(time) % (SLEEP_INTERVAL*16));
    if (current_delta > delta_t)
	    return (((SLEEP_INTERVAL*16) - current_delta) + delta_t);
    else
	    return (delta_t - current_delta);
}


void eeprom_save_time(unsigned long int time)
{
    unsigned long int current_time = time;
    unsigned char *ptr = (unsigned char*) &current_time;
    eeprom_wb(4, ptr[0]);
    eeprom_wb(5, ptr[1]);
    eeprom_wb(6, ptr[2]);
    eeprom_wb(7, ptr[3]);
}

unsigned long int eeprom_get_time()
{
    unsigned long int time;
    unsigned char *ptr = (unsigned char*) &time;

    ptr[0] = eeprom_rb(4);
    ptr[1] = eeprom_rb(5);
    ptr[2] = eeprom_rb(6);
    ptr[3] = eeprom_rb(7);
    
    return time;
}

unsigned long int eeprom_next_seqno()
{
    unsigned long int rval = 0;
    unsigned long int seqno = 0;
    unsigned char *ptr = 
	(unsigned char *) &seqno;

    ptr[0] = eeprom_rb(0);
    ptr[1] = eeprom_rb(1);
    ptr[2] = eeprom_rb(2);
    ptr[3] = eeprom_rb(3);

    rval = seqno++;

    eeprom_wb(0, ptr[0]);
    eeprom_wb(1, ptr[1]);
    eeprom_wb(2, ptr[2]);
    eeprom_wb(3, ptr[3]);

    return(rval);
}



//
// Task: photo data
//
TOS_TASK(turn_wb_on)
{
	VAR(wb_state) = 1;
	TOS_CALL_COMMAND(YELLOW_LED_ON)();
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_SET_SWITCH_ALL)(0xEC);
}

//
// Task: photo data
//
TOS_TASK(turn_wb_off)
{
	VAR(wb_state) = 0;
    TOS_CALL_COMMAND(YELLOW_LED_OFF)();
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_SET_SWITCH_ALL)(0x00);
}

//
// Task: photo data
//
TOS_TASK(take_photo_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(PHOTO);
}

//
// Task: temp data
//
TOS_TASK(take_temp_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(TEMP);
}

//
// Task: thermopile data
//
TOS_TASK(take_thermopile_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(THERMOPILE);
}

//
// Task: thermistor data
//
TOS_TASK(take_thermistor_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(THERMISTOR);
}

//
// Task: humidity data
//
TOS_TASK(take_humidity_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(HUMIDITY);
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
// VAR(snooze_time) contains the length of time to snooze
// in 1/16ths of a second
//
TOS_TASK(snooze_again)
{
    VAR(time) = VAR(time) + VAR(snooze_time);
    eeprom_save_time(VAR(time));
    TOS_CALL_COMMAND(GDI_SUB_SNOOZE)(VAR(snooze_time)*2);
}


//
// Event: message handler
//
TOS_MsgPtr TOS_MSG_EVENT(GDI_UPDATE_MSG)(TOS_MsgPtr msg)
{
    if (TOS_LOCAL_ADDRESS % 2 == 0)
    {
	    VAR(tmpmsg) = msg;
	    VAR(relay_msg_pending) = 1;
	    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(BASE_STATION,
	       AM_MSG(GDI_UPDATE_MSG),
	       VAR(tmpmsg));
    }
    return(msg);
}

TOS_MsgPtr TOS_MSG_EVENT(GDI_TIMESYNC_SEND_MSG)(TOS_MsgPtr msg)
{
    // respond to our child with the current time
    short* data = (short*)msg->data;
    unsigned long int* data2 = (unsigned long int*)VAR(msg_time)->data;
    data2[0] = VAR(time);
    if (VAR(timesync_msg_send_pending) == 0)
    {
	    VAR(timesync_msg_send_pending) = 1;
	    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(data[0],
	       AM_MSG(GDI_TIMESYNC_RECV_MSG),
	       VAR(msg_time));
    }
	    
    return(msg);
}

TOS_MsgPtr TOS_MSG_EVENT(GDI_TIMESYNC_RECV_MSG)(TOS_MsgPtr msg)
{
    // update our time
    unsigned long int* data = (unsigned long int*)msg->data;
    VAR(time) = data[0];
    // calculate how much time you should sleep until next proc period
    VAR(snooze_time) = calc_next_wakeup();
    TOS_POST_TASK(snooze_again);
    return(msg);
}

//
// Task: broadcast readings
//
TOS_TASK(send_readings)
{

    TOS_CALL_COMMAND(RED_LED_ON)();

    gdimsg_t *m = (gdimsg_t *) VAR(msg)->data;

    m->sender_id = (unsigned char) TOS_LOCAL_ADDRESS;
    m->photo_data = (unsigned short)VAR(photo_data);
    m->temp_data = (unsigned short)VAR(temp_data);
    m->thermopile_data = (unsigned short)VAR(thermopile_data);
    m->thermistor_data = (unsigned short)VAR(thermistor_data);
    m->humidity_data = (unsigned short)VAR(humidity_data);
    m->volts_data = (unsigned char) (VAR(volts_data) >> 2);
    m->seqno = eeprom_next_seqno();

    TOS_CALL_COMMAND(GDI_SUB_SET_POT_POWER)(TRANSMITPOWER);

    if ((TOS_LOCAL_ADDRESS % 2) == 0)
	    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(BASE_STATION,
				       AM_MSG(GDI_UPDATE_MSG),
				       VAR(msg));
    else
	    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)((TOS_LOCAL_ADDRESS - 1),
				       AM_MSG(GDI_UPDATE_MSG),
				       VAR(msg));

}

//
// Task: wakeup reset
//
TOS_TASK(wakeup_reset)
{
    VAR(time) = eeprom_get_time();

    VAR(msg) = &VAR(msg_buf);
    VAR(msg_time) = &VAR(msg_time_buf);
    TOS_CALL_COMMAND(GDI_COMM_RESET)();

    TOS_CALL_COMMAND(IVOLTS_INIT)();
    TOS_CALL_COMMAND(PHOTO_INIT)();

    VAR(wait_time) = 0;
    VAR(wb_wait) = 0;

    //TOS_POST_TASK(turn_wb_on);
}

//
// Event: volts data ready
//
char TOS_EVENT(GDI_IVOLTS_DATA_READY)(short data) 
{
    VAR(volts_data) = data;
    TOS_POST_TASK(take_photo_reading);
    return(0);
}

//
// Event: micawb reading is done
//
char TOS_EVENT(GDI_MICAWB_PHOTO_GET_READING_DONE)(char sensor, short value)
{
	if (sensor == PHOTO)
	{
		VAR(photo_data) = value;
		TOS_POST_TASK(take_temp_reading);
	}
	else if (sensor == TEMP)
	{
		VAR(temp_data) = value;
		TOS_POST_TASK(take_thermopile_reading);
	}
	else if (sensor == THERMOPILE)
	{
		VAR(thermopile_data) = value;
		TOS_POST_TASK(take_thermistor_reading);
	}
	else if (sensor == THERMISTOR)
	{
		VAR(thermistor_data) = value;
		TOS_POST_TASK(take_humidity_reading);
	}
	else if (sensor == HUMIDITY)
	{
		VAR(humidity_data) = value;
		TOS_POST_TASK(turn_wb_off);
		//TOS_POST_TASK(send_readings);
	}
	return 1;
}

//
// After setting the switch...
//
char TOS_EVENT(GDI_MICAWB_PHOTO_SET_SWITCH_ALL_DONE)(char success)
{
  if (VAR(wb_state) == 1) {}
//	  TOS_POST_TASK(take_volts_reading);
  else
	  TOS_POST_TASK(send_readings);
  return 1;
}

//
// Event: snooze wakeup
//
char TOS_EVENT(GDI_SNOOZE_WAKEUP)()
{
    TOS_POST_TASK(wakeup_reset);
    VAR(wakeups)++;
    VAR(wait_time) = 0;
    return(0);
}

//
// Event: send done
//
char TOS_EVENT(GDI_SEND_DONE)(TOS_MsgPtr msg)
{
    // don't go to sleep if it was a time sync message
    if (VAR(timesync_msg_send_pending) == 1)
    {
            TOS_CALL_COMMAND(RED_LED_TOGGLE)();

	    VAR(timesync_msg_send_pending) = 0;
	    return (1);
    }

    // don't go to sleep if we were relaying
    if (VAR(relay_msg_pending) == 1)
    {
	    VAR(relay_msg_pending) = 0;
	    return (1);
    }
    
    // if we were sensing, snooze again
    VAR(snooze_time) = calc_next_wakeup();
    TOS_POST_TASK(snooze_again);
    return(0);
}

//
// init
//
char TOS_COMMAND(GDI_INIT)()
{
    VAR(msg) = &VAR(msg_buf);
    VAR(msg_time) = &VAR(msg_time_buf);
    //VAR(time) = 0;              // initialize time and then sync
    VAR(wakeups) = 0;           // keep track of how many wakeups
    VAR(lastw) = 0;
    VAR(tog) = 0;
    VAR(wait_time) = 0;
    VAR(wb_wait) = 0;
    VAR(time_reqs) = 0;
    VAR(relay_msg_pending) = 0;
    VAR(timesync_msg_send_pending) = 0;
    VAR(wb_state) = 0;          // is the weather board on or off?
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
    if((VAR(wakeups) != VAR(lastw))) {
	VAR(lastw) = VAR(wakeups);
    }
    // if we're not synchronized, sync.

       TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();

/* **********
    if (VAR(time) == 0)
    {
       short dest;
       short* data = (short*)VAR(msg_time)->data;

       data[0] = TOS_LOCAL_ADDRESS;
       VAR(time_reqs)++;
       // if we're even, we can just grab the time from the root
       if (VAR(time_reqs) % 10 == 0)
       {
         if ((TOS_LOCAL_ADDRESS % 2) == 0)
         {
	       dest = BASE_STATION;
	 }
         // schedule getting the time every x clock events
         else
         {
               dest = TOS_LOCAL_ADDRESS - 1;
         }

         TOS_CALL_COMMAND(GDI_SUB_SET_POT_POWER)(TRANSMITPOWER);

	 if (VAR(timesync_msg_send_pending) == 0)
	 {
		 VAR(timesync_msg_send_pending) = 1;
		 TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(dest,
				       AM_MSG(GDI_TIMESYNC_SEND_MSG),
				       VAR(msg_time));
		 return;
	 }
       }
    }
    else
    ***************** */
    {

       VAR(time)++;
       if (VAR(wait_time) <= PARENT_DELAY)
	       VAR(wait_time)++;
       // parents wait until the delay is up
       if ((VAR(wait_time) > PARENT_DELAY) && (TOS_LOCAL_ADDRESS % 2 == 0))
       {
	       TOS_POST_TASK(turn_wb_on);
       }
       // children start processing immediately
       else if (TOS_LOCAL_ADDRESS % 2 == 1)
       {
	       VAR(wait_time) = PARENT_DELAY + 1;
	       TOS_POST_TASK(turn_wb_on);
       }

       // if the wb is on, delay until its time to take readings
       if ((VAR(wb_state) == 1) && (VAR(wb_wait) <= SENSING_DELAY))
	       VAR(wb_wait)++;
       if ((VAR(wb_wait) > SENSING_DELAY) && (VAR(wb_state) == 1))
       {
	       TOS_POST_TASK(take_volts_reading);
       }
/*
       // every day update your clock
       if (VAR(time) > 1382400)
       {
	       // forces a time sync operation to occur
	       VAR(time) = 0;
       }
*/
    }
}

void toggle_red_led() {
    if(VAR(tog)==0) {
	TOS_CALL_COMMAND(GDI_RED_LED_ON)();
	VAR(tog)=1;
    } else {
	TOS_CALL_COMMAND(GDI_RED_LED_OFF)();
	VAR(tog)=0;
    }
}

void toggle_green_led() {
    if(VAR(tog)==0) {
	TOS_CALL_COMMAND(GDI_GREEN_LED_ON)();
	VAR(tog)=1;
    } else {
	TOS_CALL_COMMAND(GDI_GREEN_LED_OFF)();
	VAR(tog)=0;
    }
}

void toggle_yellow_led() {
    if(VAR(tog)==0) {
	TOS_CALL_COMMAND(GDI_YELLOW_LED_ON)();
	VAR(tog)=1;
    } else {
	TOS_CALL_COMMAND(GDI_YELLOW_LED_OFF)();
	VAR(tog)=0;
    }
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

void set_red_led() {
    TOS_CALL_COMMAND(GDI_RED_LED_ON)();
}

void set_green_led() {
    TOS_CALL_COMMAND(GDI_GREEN_LED_ON)();
}

void set_yellow_led() {
    TOS_CALL_COMMAND(GDI_YELLOW_LED_ON)();
}

volatile int gval;
 barf() { gval++; };
 mydelay(int i) { while(--i >= 0) barf(); }

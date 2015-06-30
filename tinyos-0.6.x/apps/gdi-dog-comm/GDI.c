/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * GDI - 
 * 
 */

#include "tos.h"
#include "GDI.h"
#include "eeprom.h"

typedef struct {
    unsigned char sender_id;
    unsigned char photo_data;
    unsigned char temp_data;
    unsigned char volts_data;
    unsigned long int seqno;
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
// Event: message handler
//
TOS_MsgPtr TOS_MSG_EVENT(GDI_UPDATE_MSG)(TOS_MsgPtr msg)
{
    return(msg);
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
// Task: broadcast readings
//
TOS_TASK(send_readings)
{
    gdimsg_t *m = (gdimsg_t *) VAR(msg)->data;

    m->sender_id = (unsigned char) TOS_LOCAL_ADDRESS;
    m->photo_data = (unsigned char) (VAR(photo_data) >> 2);
    m->temp_data =  (unsigned char) (VAR(temp_data) >> 2);
    m->volts_data = (unsigned char) (VAR(volts_data) >> 2);
    m->seqno = eeprom_next_seqno();

    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(TOS_BCAST_ADDR,AM_MSG(GDI_UPDATE_MSG),VAR(msg));
}

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
    TOS_POST_TASK(send_readings);
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

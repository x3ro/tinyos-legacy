/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
 *
 * GDI - 
 * 
 */

#include "tos.h"
#include "GDI.h"
#include "eeprom.h"

#define TRANSMITPOWER (1)

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
	unsigned short intersema_temp_raw;
	unsigned short intersema_pressure_raw;
	unsigned short intersema_pressure;
	short intersema_temp;
	short cd[4];
} gdimsg_t;

#define TOS_FRAME_TYPE GDI_obj_frame
TOS_FRAME_BEGIN(GDI_obj_frame) {
    TOS_Msg msg_buf;
    TOS_MsgPtr msg;
    char wb_state;
    char clockticks;
    short photo_data;
    short temp_data;
    short thermopile_data;
    short thermistor_data;
    short humidity_data;
    short volts_data;
    unsigned short d1;
    unsigned short d2;
    unsigned short pressure;
    short itemp;
    int wakeups;
    int lastw;
    int tog;
    
    char intersema_state;
    unsigned short cd[4];

    unsigned short c1;
    unsigned short c2;
    unsigned short c3;
    unsigned short c4;
    unsigned short c5;
    unsigned short c6;

}
TOS_FRAME_END(GDI_obj_frame);

//
// Task: turn_wb_on
//
TOS_TASK(turn_wb_on)
{
	VAR(wb_state) = 1;
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_SET_SWITCH_ALL)(0xEC+0x11);
}

//
// Task: turn_wb_off
//
TOS_TASK(turn_wb_off)
{
	VAR(wb_state) = 0;
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_SET_SWITCH_ALL)(0x00);
}

//
// Task: take_photo_reading
//
TOS_TASK(take_photo_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(PHOTO);
}

//
// Task: take_temp_reading
//
TOS_TASK(take_temp_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(TEMP);
}

//
// Task: take_thermopile_reading
//
TOS_TASK(take_thermopile_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(THERMOPILE);
}

//
// Task: take_thermistor_reading
//
TOS_TASK(take_thermistor_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(THERMISTOR);
}

//
// Task: take_humidity_reading
//
TOS_TASK(take_humidity_reading)
{
	TOS_CALL_COMMAND(GDI_MICAWB_PHOTO_GET_READING)(HUMIDITY);
}

//
// Task: take_volts_reading
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
    unsigned short time = (unsigned short) 
        TOS_CALL_COMMAND(GDI_SUB_LFSR_NEXT_RAND)();

//    time %= 8;	// 0 to 7 second sleep times
//    time++;	        // really want 1 - 8 seconds
//    time *= 32;	// scale by 32x for snoozing

//  TOS_CALL_COMMAND(GDI_SUB_SNOOZE)(32 * 4);
    TOS_CALL_COMMAND(GDI_SUB_SNOOZE)(time & 0x1);
}
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


TOS_TASK(process_data) {
    long ut1;
    short dt;
    long temp;
    unsigned short d1, d2; 
    long off;
    long sens;
    long x, p;
    d1 = VAR(d1);
    d2 = VAR(d2);

//    parse_calib_data(&(VAR(data).data[1]));
    ut1=20224;
    ut1 += (VAR(c5)<<3);
    dt = d2-ut1;
    temp = ((long)dt) * ((long)(VAR(c6)+50));
    temp >>= 10;
    temp += 200;
    VAR(itemp) = temp;

//    VAR(data).data[15] = (char)(temp >> 8) & 0xff;
//    VAR(data).data[16] = (char)(temp & 0xff);

    off=-512; 
    off+=VAR(c4);
    off *= dt;
    off >>= 12;
    off += (VAR(c2)<<2);

    sens = (VAR(c3) * dt) >> 10; 
    sens += VAR(c1) + 24576;
      
    x = (sens * (d1 -7168)>>14)-off;
    p = (x* 10)>>5;
    p += 2500;
    VAR(pressure) = p;

//    VAR(data).data[17] = (char)(p >> 8) & 0xff;
//    VAR(data).data[18] = (char)(p & 0xff);

	
/*     TOS_CALL_COMMAND(CHIRP_SUB_PWR)(PWR_ON); */
/*     if (VAR(send_pending) == 0) { */
/* 	if (TOS_CALL_COMMAND(CHIRP_SUB_SEND_MSG)(TOS_UART_ADDR,AM_MSG(CHIRP_MSG),&VAR(data))) { */
/* 	    VAR(send_pending) = 1; */
/* 	    TOS_CALL_COMMAND(CHIRP_LEDg_on)(); */
/* 	} */
/*     } */

}

TOS_TASK(parse_calib_data) {
    unsigned short cd1, cd2, cd3, cd4; 
    cd1 = VAR(cd)[0];
    cd2 = VAR(cd)[1];
    cd3 = VAR(cd)[2];
    cd4 = VAR(cd)[3];
    //printf("0x%04x 0x%04x 0x%04x 0x%04x\n", cd1, cd2, cd3, cd4);
    VAR(c1) =  (cd1 >> 1) & 0x7fff;
    VAR(c2) = ((cd3 &0x003f) << 6) | (cd4 & 0x003f);
    VAR(c3) = (cd4 >> 6) & 0x3ff;
    VAR(c4) = (cd3 >> 6) & 0x3ff;
    VAR(c5) =  (cd2 >> 6)&0x3ff; 
    if (cd1 & 1) 
	VAR(c5) |= 0x0400;
    VAR(c6) = (cd2 &0x3f);
//    TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
    
}


char TOS_EVENT(GDI_INTERSEMA_DATA_EVENT)(unsigned short data){
	gdimsg_t* msg= (gdimsg_t *) (VAR(msg)->data);
	if (VAR(intersema_state) < 4){
		VAR(cd)[(short)VAR(intersema_state)& 0x3] = data;
		msg->cd[VAR(intersema_state)] = data;
		VAR(intersema_state)++;
		if (VAR(intersema_state) < 4) {
			TOS_CALL_COMMAND(INTERSEMA_COMMAND)(VAR(intersema_state));
//			TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
		} else {
			VAR(intersema_state) = 10;
			TOS_CALL_COMMAND(INTERSEMA_COMMAND)(0); 
		}
	} else if (VAR(intersema_state) == 10) {
		msg->cd[0] = data;
		VAR(intersema_state) = 5; 
		VAR(cd)[0] = data;
		TOS_POST_TASK(parse_calib_data);		
	} else if (VAR(intersema_state) == 6) {
		VAR(intersema_state) = 7;
		VAR(d1) = data;
	} else if (VAR(intersema_state) == 8) {
		VAR(d2) = data;
		VAR(intersema_state) = 5;
		TOS_POST_TASK(process_data);
		TOS_CALL_COMMAND(GDI_SUB_PWR)(PWR_ON);
	} 
    return 1;
}

//
// Task: broadcast readings
//
TOS_TASK(send_readings)
{
    gdimsg_t *m = (gdimsg_t *) VAR(msg)->data;

    m->sender_id = (unsigned char) TOS_LOCAL_ADDRESS;
    m->photo_data = (unsigned short)VAR(photo_data);
    m->temp_data = (unsigned short)VAR(temp_data);
    m->thermopile_data = (unsigned short)VAR(thermopile_data);
    m->thermistor_data = (unsigned short)VAR(thermistor_data);
    m->humidity_data = (unsigned short)VAR(humidity_data);
    m->volts_data = (unsigned char) (VAR(volts_data) >> 2);
    m->seqno = eeprom_next_seqno();
    m->intersema_temp_raw = (unsigned short)(VAR(d2));
    m->intersema_pressure_raw = (unsigned short) (VAR(d1));
    m->intersema_pressure = (unsigned short) (VAR(pressure));
    m->intersema_temp = (short)(VAR(itemp));

    TOS_CALL_COMMAND(GDI_SUB_PWR)(PWR_ON);

    TOS_CALL_COMMAND(GDI_SUB_SET_POT_POWER)(TRANSMITPOWER);

    TOS_CALL_COMMAND(GDI_SUB_SEND_MSG)(TOS_BCAST_ADDR,
				       AM_MSG(GDI_UPDATE_MSG),
				       VAR(msg));
}

//
// Task: wakeup reset
//
TOS_TASK(wakeup_reset)
{
    VAR(msg) = &VAR(msg_buf);
    TOS_CALL_COMMAND(GDI_COMM_RESET)();

    TOS_CALL_COMMAND(GDI_SUB_PWR)(PWR_OFF);

    TOS_CALL_COMMAND(IVOLTS_INIT)();
    TOS_CALL_COMMAND(PHOTO_INIT)();

    TOS_POST_TASK(turn_wb_on);
}

//
// Event: volts data ready
//
char TOS_EVENT(GDI_IVOLTS_DATA_READY)(short data) 
{
    VAR(volts_data) = data;
//    TOS_POST_TASK(send_readings);
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
	}
	return 1;
}

//
// After setting the switch...
//
char TOS_EVENT(GDI_MICAWB_PHOTO_SET_SWITCH_ALL_DONE)(char success)
{
    if (VAR(wb_state) == 1) {
	    if (VAR(intersema_state) == 0){
//		    set_yellow_led();
		    TOS_CALL_COMMAND(GDI_SUB_PWR)(PWR_OFF);

		    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(0);
	    }
//	TOS_POST_TASK(take_volts_reading);
    } else {
	set_red_led();
	TOS_POST_TASK(send_readings);
    }
    return 1;
}

//
// Event: snooze wakeup
//
char TOS_EVENT(GDI_SNOOZE_WAKEUP)()
{
    TOS_POST_TASK(wakeup_reset);
//    set_red_led();
    VAR(clockticks) = 0;
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
    VAR(tog) = 0;
    VAR(wb_state) = 0;
    VAR(clockticks) = 0;
    VAR(intersema_state) = 0;
    return(1);
}

//
// start
//
char TOS_COMMAND(GDI_START)()
{
    TOS_CALL_COMMAND(GDI_SUB_SET_POT_POWER)(TRANSMITPOWER);
    TOS_CALL_COMMAND(GDI_CLOCK_INIT)(tick16ps); 
    TOS_POST_TASK(turn_wb_on);
    return(1);
}

void TOS_EVENT(GDI_CLOCK_EVENT)(){
    if((VAR(wakeups) != VAR(lastw))) {
	VAR(lastw) = VAR(wakeups);
    }

    if (VAR(clockticks) == 24) {
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(4);
    } else if (VAR(clockticks) == 25) {
	    VAR(intersema_state) = 6;
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(7);
    } else if (VAR(clockticks) == 26) {
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(4);
    } else if (VAR(clockticks) == 27) {
	    VAR(intersema_state) = 6;
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(7);
    } else if (VAR(clockticks) == 28) {
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(5);
    } else if (VAR(clockticks) == 29) {
	    VAR(intersema_state) = 8;
	    TOS_CALL_COMMAND(INTERSEMA_COMMAND)(7);
    }

    if(++VAR(clockticks) >= 32) {
	TOS_POST_TASK(take_volts_reading);
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

char TOS_EVENT(GDI_INTERSEMA_PWR_DONE)(char value) {
//    TOS_CALL_COMMAND(CHIRP_LEDr_off)();
    return 1;
}


volatile int gval;
 barf() { gval++; };
 mydelay(int i) { while(--i >= 0) barf(); }

/*									tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Robert Szewczyk
 *
 * This component exposes the basic functionality required for network
 * programming. At its core, it exports 4 basic message handlers:
 * NEW_PROGRAM_MSG, READ_PROG, WRITE_PROG, and START_PROG. The component
 * exports the functionality of the GENERIC_COMM and LOGGER. 
 */

#include "tos.h"
#include "PROG_COMM_SIGNAL.h"
#include "pgmspace.h"
#include "dbg.h"

#define DEBUG

#define NORMAL       0
#define BITMAP_WRITE 1
#define BITMAP_READ  2
#define BITMAP_READ_WAIT_1  3
#define BITMAP_READ_WAIT_2  4
#define LG_WAKEUP           5
#define LG_LISTEN           6

#define PRGM_ENABLE 8
#define READ_BYTE   9
#define WRITE_BYTE 10
#define UNKNOWN    11

#define INIT0      15
#define INIT1      16
#define INIT2      17
#define INIT3      18
#define INIT4      19

#define FINAL_CHECK1 26
#define FINAL_CHECK2 27
#define FINAL_CHECK3 28
#define FINAL_CHECK4 29

#define SS   4
#define MOSI 5
#define MISO 6
#define SCK  7 
/* Utility functions */

/* Code capsules are of size 2^n. This makes it simple to map them onto
   loglines, to account for them. Additionally, the uController memory is a
   multiple of that size. For the Atmel, we start out with 16 bytes of code
   per capsule */ 
#define CAPSULE_POWER 4

/* How many capsules can we fit in the entire memory? For Atmel 8535, this
   number is 512. */

#define MAX_CAPSULES 512

/* Where in the EEPROM should we allocate the code? The unit is in
   LOG_LINES. For the current LOG policy, each log line is 16 bytes in length,
   and there is a total of 2048 log lines. Bear in mind that the program code
   also needs some extra space for the bitmaps*/

#define BASELINE 4

typedef struct {
    int prog_id;
    int addr;
    unsigned char code[16];
} capsule;

typedef struct {
    int prog_id;
    int addr;
    short dest;
    char check;
} capsule_req;

#define TOS_FRAME_TYPE PROG_COMM_frame
TOS_FRAME_BEGIN(PROG_COMM_frame) {
    short dest;
    char state;
    char write_delay;
    char q;
    char i2c_pending;
    char check;
    char done;
    char frag_map[16];
    int new_prog;
    int prog_length;
    TOS_Msg msg;  
    TOS_MsgPtr i2c_msg;
}
TOS_FRAME_END(PROG_COMM_frame);

void write_frag();

#define TOS_PROG_ID 0

char TOS_COMMAND(PROG_COMM_INIT)(){
    VAR(i2c_pending) = 0;
    VAR(q) = -1;
    VAR(dest) = TOS_BCAST_ADDR;
    VAR(i2c_msg) = &(VAR(msg));
    TOS_CALL_COMMAND(PROG_COMM_SUB_LOGGER_INIT)();
    TOS_CALL_COMMAND(PROG_COMM_SUB_COMM_INIT)();
    //    TOS_CALL_COMMAND(PROG_COMM_CLOCK_INIT)(11, 3);

    dbg(DBG_BOOT, ("PROG_COMM initialized\n"));

    VAR(i2c_pending) = 1;
    VAR(state) = INIT0;
    TOS_CALL_COMMAND(PROG_COMM_SUB_READ_LOG)(0, VAR(frag_map));
    return 1;
}

char TOS_COMMAND(PROG_COMM_START)(){
    return 1;
}

char TOS_COMMAND(PROG_COMM_WRITE_LOG)(int line, char* data){
    return TOS_CALL_COMMAND(PROG_COMM_SUB_WRITE_LOG)(line, data);
}
char TOS_COMMAND(PROG_COMM_READ_LOG)(int line, char* dest){
    return TOS_CALL_COMMAND(PROG_COMM_SUB_READ_LOG)(line, dest);
}

char TOS_COMMAND(PROG_COMM_SEND_MSG)(short addr, char type, TOS_MsgPtr data) {
    return TOS_CALL_COMMAND(PROG_COMM_SUB_SEND_MSG)(addr, type, data);
}


TOS_MsgPtr TOS_EVENT(PROG_COMM_READ_MSG)(TOS_MsgPtr msg){
    capsule_req * data = (capsule_req *)msg->data;
    int log_line;
    int i;
    if (VAR(i2c_pending) == 0) {
	VAR(i2c_pending) = 1;

#ifdef DEBUG
	TOS_CALL_COMMAND(PROG_COMM_YELLOW_LED_ON)();
#endif
	
	VAR(dest) = data->dest;
	if (data->prog_id == 0) {
	    capsule *data_ret;
	    log_line = data -> addr;
	    data_ret = (capsule *) VAR(i2c_msg)->data;
	    data_ret -> addr = log_line;
	    data_ret -> prog_id = TOS_PROG_ID;
	    for (i=0; i < 16; i++) {
		data_ret -> code[i] = _LPM(log_line++);
	    }
	    TOS_CALL_COMMAND(PROG_COMM_SUB_SEND_MSG)(VAR(dest),
					    AM_MSG(PROG_COMM_WRITE_FRAG_MSG),
					    VAR(i2c_msg));
	} else {
	    VAR(check) = data->check;
	    log_line = data->addr >> CAPSULE_POWER;
	    dbg(DBG_PROG, ("LOG_READ_START \n"));
	    ((capsule *)(VAR(i2c_msg)->data))->addr = data->addr;
	    TOS_CALL_COMMAND(PROG_COMM_SUB_READ_LOG)(BASELINE+log_line,((capsule *)(VAR(i2c_msg)->data))->code);
	}
    } 
    return msg;
}

void brain_xfer() {

#if defined(__AVR_ATmega163__)
    reprogram();
#else
    int i;
    TOS_CALL_COMMAND(PROG_COMM_RED_LED_TOGGLE)();
    MAKE_I2C_BUS1_SDA_OUTPUT();
    CLR_I2C_BUS1_SDA_PIN();
    MAKE_LITTLE_GUY_RESET_OUTPUT();
    CLR_LITTLE_GUY_RESET_PIN();
    for (i=0; i<5000; i++){
	asm volatile("nop"::);
    }
    MAKE_LITTLE_GUY_RESET_INPUT();
    SET_LITTLE_GUY_RESET_PIN();
    for (i=0; i<5000; i++){
	asm volatile("nop"::);
    }
#endif
}


char TOS_EVENT(PROG_COMM_LOG_READ)(char* data, char success){
    capsule * msg = (capsule *) VAR(i2c_msg)->data;
    unsigned char allthere, i;
    char * ptr;
    if ((data != VAR(frag_map)) && (data != msg->code))
	return TOS_SIGNAL_EVENT(PROG_COMM_READ_LOG_DONE)(data, success);
    dbg(DBG_PROG, ("LOG_READ_DONE\n"));
    if (VAR(state) == NORMAL) {
	allthere = 0xff;
	if (VAR(check)) {
	    ptr = msg->code;
	    for (i = 0; i < 16; i++) {
	        allthere &= *ptr++;
	    }
	    VAR(i2c_msg)->data[29] = allthere;
	} else {
	    allthere = 0;
	}
	VAR(check) = 0;
	if (allthere != 0xff) {
	    TOS_CALL_COMMAND(PROG_COMM_SUB_SEND_MSG)(VAR(dest),AM_MSG(PROG_COMM_WRITE_FRAG_MSG),VAR(i2c_msg));
	} else {
	    VAR(i2c_pending) = 0;
	    i = (unsigned char) (msg->addr & 0xff);
	    i >>= 4;
	    VAR(done) |= 1 << i;
	    if (VAR(done) == 0xf) {
		TOS_CALL_COMMAND(PROG_COMM_GREEN_LED_TOGGLE)();
	    }
	}
    } else if (VAR(state) == BITMAP_READ) {
	dbg(DBG_PROG, ("Finished reading the bitmap page\n"));
	VAR(state) = NORMAL;
	VAR(i2c_pending) = 0;
	dbg(DBG_PROG, ("writing the pending page"));
	write_frag();
    } else if (VAR(state) == INIT0) {
	/* Initialize the local ID from the EEPROM */
	VAR(state) = NORMAL;
	VAR(i2c_pending) = 0;
	TOS_LOCAL_ADDRESS = VAR(frag_map)[0] & 0xff;
	TOS_LOCAL_ADDRESS |= VAR(frag_map) [1]<< 8;
	VAR(new_prog) = VAR(frag_map)[2] & 0xff;
	VAR(new_prog) |= VAR(frag_map)[3] << 8;
	VAR(prog_length) = VAR(frag_map)[4] & 0xff;
	VAR(prog_length) |= VAR(frag_map)[5] << 8;
    } 
#if 0
else if ((VAR(state) >= FINAL_CHECK1) && (VAR(state) <= FINAL_CHECK4)) {
	allthere = 0xff;
	ptr = msg->code;
	for (i=0; i < 16; i++) {
	    allthere &= *ptr++;
	}
	if (allthere == 0xff) {
	    if (VAR(state) < FINAL_CHECK4) {
		VAR(state)++;
		TOS_CALL_COMMAND(PROG_COMM_SUB_READ_LOG)(BASELINE+MAX_CAPSULES+VAR(state)-FINAL_CHECK1, msg->code);
	    } else {
		brain_xfer();
	    }
	} else {
	    msg->addr = (MAX_CAPSULES<<CAPSULE_POWER) + ((VAR(state)-FINAL_CHECK1)<<CAPSULE_POWER);
	    msg->prog_id = -1;
	    TOS_CALL_COMMAND(PROG_COMM_SUB_SEND_MSG)(VAR(dest),AM_MSG(PROG_COMM_WRITE_FRAG_MSG),VAR(i2c_msg));
	    VAR(i2c_pending) = 0;
	    VAR(state) = NORMAL;
	}
}
#endif
    return 1;
}

char TOS_EVENT(PROG_COMM_MSG_SENT)(TOS_MsgPtr msg){
    if ((VAR(i2c_pending) == 1) && (msg == VAR(i2c_msg))) {
	VAR(i2c_pending) = 0;
#if 0
#ifdef DEBUG
	TOS_CALL_COMMAND(PROG_COMM_RED_LED_TOGGLE)();
#endif
#endif
	
    } else {
	TOS_SIGNAL_EVENT(PROG_COMM_MSG_SEND_DONE)(msg);
    }
    return 0;
}

void write_frag() {
    capsule * data = (capsule *) VAR(i2c_msg)->data;
    int log_line = data->addr;
    dbg(DBG_PROG, ("LOG_WRITE_FRAG_START 0x%04x\n", log_line & 0xffff));
    log_line >>= CAPSULE_POWER;
    if (VAR(q) != ((log_line >> (CAPSULE_POWER+3)) & 0x3)) {
	VAR(state) = BITMAP_WRITE;
	if (VAR(q) == -1) {
	    VAR(q) =  (log_line >> (CAPSULE_POWER+3)) & 0x3;
	    TOS_SIGNAL_EVENT(PROG_COMM_WRITE_LOG_DONE)(0);
	} else {
	    dbg(DBG_PROG, ("Storing to logline %04x\n", BASELINE +MAX_CAPSULES + VAR(q)));
	    TOS_CALL_COMMAND(PROG_COMM_SUB_WRITE_LOG)(BASELINE + MAX_CAPSULES + VAR(q),
						  VAR(frag_map)); 
	    VAR(q) =  (log_line >> (CAPSULE_POWER+3)) & 0x3;
	}
    } else {
#if 0
#ifdef DEBUG
	TOS_CALL_COMMAND(PROG_COMM_YELLOW_LED_TOGGLE)();
#endif
#endif
	VAR(frag_map)[(log_line>>3)& 0xf] |= 1 << (log_line & 0x07);
	TOS_CALL_COMMAND(PROG_COMM_SUB_WRITE_LOG)(BASELINE+log_line, data->code);
    }
}



TOS_MsgPtr TOS_MSG_EVENT(PROG_COMM_WRITE_FRAG_MSG)(TOS_MsgPtr msg){
    TOS_MsgPtr local = msg;
    capsule * data = (capsule *)local->data;
    if (data->prog_id != VAR(new_prog))
	return msg;
    if (VAR(i2c_pending) == 0) {
	VAR(i2c_pending) = 1;
	local = VAR(i2c_msg);
	VAR(i2c_msg) = msg;
	write_frag();
    }
    return local;
}

char TOS_EVENT(PROG_COMM_WRITE_LOG_DONE)(char success){
    int i;
#ifdef DEBUG
	TOS_CALL_COMMAND(PROG_COMM_YELLOW_LED_TOGGLE)();
#endif
    dbg(DBG_PROG, ("LOG_WRITE_DONE\n"));
    for (i = 0; i < 16; i++) {
	dbg(DBG_PROG, ("%02x ", VAR(frag_map)[i] & 0xff));
    } 
    dbg(DBG_PROG, ("\n"));
#if 0    
#ifdef DEBUG
    TOS_CALL_COMMAND(PROG_COMM_RED_LED_OFF)();
#endif
#endif
    if (VAR(state) == BITMAP_WRITE) {
	dbg(DBG_PROG, ("Finished writing the capsule bitmap\n"));
	VAR(state) = BITMAP_READ;
	TOS_CALL_COMMAND(PROG_COMM_SUB_READ_LOG)(BASELINE + MAX_CAPSULES + VAR(q), VAR(frag_map)); 
    } else if (VAR(state) == NORMAL) {
	VAR(i2c_pending) = 0;
	//	((capsule *)(VAR(i2c_msg)->data))->addr = VAR(count)++;
	//TOS_CALL_COMMAND(COMM_SEND_MSG)(TOS_UART_ADDR,0x06,VAR(i2c_msg));

    } else if ((VAR(state) >= INIT1) && (VAR(state) <= INIT4)) {
	for ( i = 0; i < 16; i++) { 
	    VAR(frag_map)[i] = 0;
	}
	TOS_CALL_COMMAND(PROG_COMM_SUB_WRITE_LOG)(BASELINE + MAX_CAPSULES +
					      VAR(state) - INIT1,
					      VAR(frag_map));
	VAR(state)++;
    } else {
	VAR(state) = NORMAL;
	VAR(i2c_pending) = 0;
    }
    //    TOS_SIGNAL_EVENT(PROG_COMM_APPEND_LOG_DONE)(success);
    return 1;
}


TOS_MsgPtr TOS_MSG_EVENT(PROG_COMM_START_PROG) (TOS_MsgPtr msg) {
#if 0
    if (VAR(i2c_pending) == 0) {
	VAR(i2c_pending) = 1;
	VAR(state) = FINAL_CHECK1;
	TOS_CALL_COMMAND(PROG_COMM_SUB_READ_LOG)(BASELINE+MAX_CAPSULES, 
					     ((capsule *)VAR(i2c_msg))->code);
    }
#else
    brain_xfer();
#endif
    return msg;
}



TOS_MsgPtr TOS_MSG_EVENT(PROG_COMM_NEW_PROG) (TOS_MsgPtr msg) {
    if (VAR(i2c_pending) == 0) {
#ifdef DEBUG
    TOS_CALL_COMMAND(PROG_COMM_GREEN_LED_ON)();
#endif
	
	VAR(state) = INIT1;
	VAR(new_prog) = msg->data[0] & 0xff;
	VAR(new_prog) |= msg->data[1] << 8;
	VAR(prog_length) = msg->data[2] & 0xff;
	VAR(prog_length) |= msg->data[3] << 8;
	VAR(frag_map)[0] = TOS_LOCAL_ADDRESS & 0xff;
	VAR(frag_map)[1] = (TOS_LOCAL_ADDRESS >> 8) & 0xff;
	VAR(frag_map)[2] = msg->data[0];
	VAR(frag_map)[3] = msg->data[1];
	VAR(frag_map)[4] = msg->data[2];
	VAR(frag_map)[5] = msg->data[3];
	TOS_CALL_COMMAND(PROG_COMM_SUB_WRITE_LOG)(0,
					      VAR(frag_map));
    }
    return msg;
}

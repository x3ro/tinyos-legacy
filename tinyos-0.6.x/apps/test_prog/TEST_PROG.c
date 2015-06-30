/*									tab:4
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * programming. 
 */

#include "tos.h"
#include "TEST_PROG.h"
#include "pgmspace.h"
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
    char dest;
} capsule_req;

#define TOS_FRAME_TYPE TEST_PROG_frame
TOS_FRAME_BEGIN(TEST_PROG_frame) {
    char dest;
    char state;
    char write_delay;
    char q;
    char frag_map[16];
    char i2c_pending;
    int new_prog;
    int prog_length;
    TOS_Msg msg;  
    TOS_MsgPtr i2c_msg;
}
TOS_FRAME_END(TEST_PROG_frame);

void write_frag();

#define TOS_PROG_ID 0

char TOS_COMMAND(TEST_PROG_INIT)(){
    VAR(i2c_pending) = 0;
    VAR(state) = NORMAL;
    VAR(q) = -1;
    VAR(dest) = TOS_BCAST_ADDR;
    VAR(i2c_msg) = &(VAR(msg));
    TOS_CALL_COMMAND(TEST_PROG_SUB_INIT)();
    TOS_CALL_COMMAND(COMM_INIT)();
    TOS_CALL_COMMAND(PROG_CLOCK_INIT)(11, 3);
    printf("TEST_PROG initialized\n");
#if 0
    VAR(i2c_pending) = 1;
    VAR(state) = INIT0;
    TOS_CALL_COMMAND(TEST_PROG_READ_LOG)(0, VAR(frag_map));
#endif
    return 1;
}

char TOS_COMMAND(TEST_PROG_START)(){
    return 1;
}

void TOS_EVENT(TEST_PROG_CLOCK_EVENT)(){
    if (VAR(write_delay) > 0) 
	VAR(write_delay)--;
    if (VAR(write_delay) == 0) {
	TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
	TOS_SIGNAL_EVENT(TEST_PROG_WRITE_LOG_DONE)(0);
    }
    
}

TOS_MsgPtr TOS_EVENT(TEST_PROG_READ_MSG)(TOS_MsgPtr msg){
    capsule_req * data = (capsule_req *)msg->data;
    int log_line;
    int i;
    if (VAR(i2c_pending) == 0) {
	VAR(i2c_pending) = 1;
#ifdef DEBUG
		TOS_CALL_COMMAND(YELLOW_LED_ON)();
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
	    TOS_CALL_COMMAND(COMM_SEND_MSG)(VAR(dest),
					    AM_MSG(TEST_PROG_WRITE_FRAG_MSG),
					    VAR(i2c_msg));
	} else {
	    log_line = data->addr >> CAPSULE_POWER;
	    printf("LOG_READ_START \n");
	    ((capsule *)(VAR(i2c_msg)->data))->addr = data->addr;
	    TOS_CALL_COMMAND(TEST_PROG_READ_LOG)(BASELINE+log_line,((capsule *)(VAR(i2c_msg)->data))->code);
	}
    } 
    return msg;
}

char TOS_EVENT(TEST_PROG_READ_LOG_DONE)(char* data, char success){
    capsule * msg = (capsule *) VAR(i2c_msg)->data;
    if ((data != VAR(frag_map)) && (data != msg->code))
	return 0;
    printf("LOG_READ_DONE\n");
    if (VAR(state) == NORMAL) {
	TOS_CALL_COMMAND(COMM_SEND_MSG)(VAR(dest),AM_MSG(TEST_PROG_WRITE_FRAG_MSG),VAR(i2c_msg));
    } else if (VAR(state) == BITMAP_READ) {
	printf("Finished reading the bitmap page\n");
	VAR(state) = NORMAL;
	VAR(i2c_pending) = 0;
	printf("writing the pending page");
	write_frag();
    } else if (VAR(state) == INIT0) {
	/* Initialize the local ID from the EEPROM */
	VAR(state) = NORMAL;
	VAR(i2c_pending) = 0;
	TOS_LOCAL_ADDRESS = VAR(frag_map)[0];
	VAR(new_prog) = VAR(frag_map)[1] & 0xff;
	VAR(new_prog) |= VAR(frag_map)[2] << 8;
    }
    return 1;
}

char TOS_EVENT(TEST_PROG_MSG_SENT)(TOS_MsgPtr msg){
    if ((VAR(i2c_pending) == 1) && (msg == VAR(i2c_msg))) {
	VAR(i2c_pending) = 0;
#ifdef DEBUG
	TOS_CALL_COMMAND(RED_LED_TOGGLE)();
#endif
    }
    return 0;
}

void write_frag() {
    capsule * data = (capsule *) VAR(i2c_msg)->data;
    int log_line = data->addr;
    printf("LOG_WRITE_FRAG_START 0x%04x\n", log_line & 0xffff);
    log_line >>= CAPSULE_POWER;
    if (VAR(q) != ((log_line >> (CAPSULE_POWER+3)) & 0x3)) {
	VAR(state) = BITMAP_WRITE;
	if (VAR(q) == -1) {
	    VAR(q) =  (log_line >> (CAPSULE_POWER+3)) & 0x3;
	    TOS_SIGNAL_EVENT(TEST_PROG_WRITE_LOG_DONE)(0);
	} else {
	    printf("Storing to logline %04x\n", BASELINE +MAX_CAPSULES + VAR(q));
	    TOS_CALL_COMMAND(TEST_PROG_WRITE_LOG)(BASELINE + MAX_CAPSULES + VAR(q),
						  VAR(frag_map)); 
	    VAR(q) =  (log_line >> (CAPSULE_POWER+3)) & 0x3;
	}
    } else {
#ifdef DEBUG
	TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
#endif
	VAR(frag_map)[(log_line>>3)& 0xf] |= 1 << (log_line & 0x07);
	TOS_CALL_COMMAND(TEST_PROG_WRITE_LOG)(BASELINE+log_line, data->code);
    }
}



TOS_MsgPtr TOS_MSG_EVENT(TEST_PROG_WRITE_FRAG_MSG)(TOS_MsgPtr msg){
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

char TOS_EVENT(TEST_PROG_WRITE_LOG_DONE)(char success){
    int i;
    if (VAR(write_delay) < 0) {
	VAR(write_delay) = 2;
	return 1;
    }
    VAR(write_delay) --;
#ifdef FULLPC
    printf("LOG_WRITE_DONE\n");
    for (i = 0; i < 16; i++) {
	printf("%02x ", VAR(frag_map)[i] & 0xff);
    } 
    printf("\n");
#endif
#ifdef DEBUG
    TOS_CALL_COMMAND(RED_LED_OFF)();
#endif
    if (VAR(state) == BITMAP_WRITE) {
	printf("Finished writing the capsule bitmap\n");
	VAR(state) = BITMAP_READ;
	TOS_CALL_COMMAND(TEST_PROG_READ_LOG)(BASELINE + MAX_CAPSULES + VAR(q), VAR(frag_map)); 
    } else if (VAR(state) == NORMAL) {
	VAR(i2c_pending) = 0;
	//	((capsule *)(VAR(i2c_msg)->data))->addr = VAR(count)++;
	//TOS_CALL_COMMAND(COMM_SEND_MSG)(TOS_UART_ADDR,0x06,VAR(i2c_msg));

    } else if ((VAR(state) >= INIT1) && (VAR(state) <= INIT4)) {
	for ( i = 0; i < 16; i++) { 
	    VAR(frag_map)[i] = 0;
	}
	TOS_CALL_COMMAND(TEST_PROG_WRITE_LOG)(BASELINE + MAX_CAPSULES +
					      VAR(state) - INIT1,
					      VAR(frag_map));
	VAR(state)++;
    } else {
	VAR(state) = NORMAL;
	VAR(i2c_pending) = 0;
    }
    return 1;
}

TOS_MsgPtr TOS_MSG_EVENT(TEST_PROG_START_PROG) (TOS_MsgPtr msg) {
    int i;
    TOS_CALL_COMMAND(RED_LED_TOGGLE)();
    MAKE_I2C_BUS1_SDA_OUTPUT();
    CLR_I2C_BUS1_SDA_PIN();

    MAKE_LITTLE_GUY_RESET_OUTPUT();
    CLR_LITTLE_GUY_RESET_PIN();
    for (i=0; i<1000; i++){
	asm volatile("nop"::);
    }
    MAKE_LITTLE_GUY_RESET_INPUT();
    SET_LITTLE_GUY_RESET_PIN();
    for (i=0; i<1000; i++){
	asm volatile("nop"::);
    }
    return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(TEST_PROG_NEW_PROG) (TOS_MsgPtr msg) {
    if (VAR(i2c_pending) == 0) {
	VAR(state) = INIT1;
	VAR(new_prog) = msg->data[0] & 0xff;
	VAR(new_prog) |= msg->data[1] << 8;
	VAR(prog_length) = msg->data[2] & 0xff;
	VAR(prog_length) |= msg->data[3] << 8;
	VAR(frag_map)[0] = TOS_LOCAL_ADDRESS;
	VAR(frag_map)[1] = msg->data[0];
	VAR(frag_map)[2] = msg->data[1];
	VAR(frag_map)[3] = msg->data[2];
	VAR(frag_map)[4] = msg->data[3];
	TOS_CALL_COMMAND(TEST_PROG_WRITE_LOG)(0,
					      VAR(frag_map));
    }
    return msg;
}
#if 0
TOS_MsgPtr TOS_MSG_EVENT(TEST_PROG_SET_PRIVATE) (TOS_MsgPtr msg){
    TOS_MsgPtr local = msg;
    if (VAR(i2c_pending) == 0) {
	VAR(i2c_pending) = 1;
	local = VAR(i2c_msg);
	VAR(i2c_msg) = msg;
	TOS_CALL_COMMAND(TEST_PROG_WRITE_LOG)(0,((capsule *)(VAR(i2c_msg)->data))->code);
    }
    return local;
}

#endif

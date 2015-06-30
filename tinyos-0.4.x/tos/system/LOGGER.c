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
 * Authors:		Jason Hill
 *
 *
 */

#include "tos.h"
#include "LOGGER.h"
#include "dbg.h"

#define LOG_ENTRY_SIZE 16

//various states...
#define IDLE 0

#define READ_LOG_START 11
#define READ_COMMAND 13
#define READ_COMMAND_2 14
#define READ_COMMAND_3 15
#define READ_COMMAND_4 16
#define READ_COMMAND_5 17
#define READ_LOG_READING_DATA 18

#define APPEND_LOG_START 30
#define WRITE_COMMAND 31
#define WRITE_COMMAND_2 32
#define WRITING_TO_LOG 33

#define WRITE_LOG_STOP 40 
#define READ_LOG_STOP 41


#define TOS_FRAME_TYPE LOGGER_obj_frame
TOS_FRAME_BEGIN(LOGGER_obj_frame) {
        int last_line;
        char* data;
	char state;
        char count;
	int current_line;
}
TOS_FRAME_END(LOGGER_obj_frame);


char TOS_COMMAND(APPEND_LOG) (char *data) {
    VAR(last_line) ++;
    return TOS_CALL_COMMAND(WRITE_LOG)(VAR(last_line), data);
}
char TOS_COMMAND(WRITE_LOG)(int line, char* data){
    if(VAR(state) == 0){
	VAR(data) = data;
	VAR(state) = APPEND_LOG_START;
	VAR(current_line) = line;
	VAR(last_line)--;
	VAR(count) = 0;
	if(TOS_CALL_COMMAND(LOGGER_I2C_SEND_START)()){
	    return 1;
	}else{
	    VAR(state) = 0;
	    VAR(count) = 0;
	    return 0;
	}
    }else{
	return 0;
    }
}

char TOS_COMMAND(READ_LOG)(int line, char* data){
    if(VAR(state) == 0){
	VAR(data) = data;
	VAR(state) = READ_LOG_START;
	VAR(count) = 0;
	VAR(current_line) = line;
	if(TOS_CALL_COMMAND(LOGGER_I2C_SEND_START)()){
	    return 1;
	}else{
	    VAR(state) = 0;
	    VAR(count) = 0;
	    return 0;
	}
    }else{
	return 0;
    }
}

char TOS_COMMAND(LOGGER_INIT)(){
    TOS_CALL_COMMAND(LOGGER_SUB_INIT)();
    VAR(state) = 0;
    VAR(last_line) = 0;
    VAR(count) = 0;

    dbg(DBG_BOOT, ("Logger initialized.\n"));

    return 1;
} 


char TOS_EVENT(LOGGER_I2C_READ_BYTE_DONE)(char data, char error){

  dbg(DBG_LOG, ("LOGGER: byte arrived: %02x, STATE: %d, COUNT: %d\n", data&0xff, VAR(state), VAR(count)));

    if(error){
	VAR(state) = IDLE;
	TOS_CALL_COMMAND(LOGGER_I2C_SEND_END)();
	return 0;
    }
    if(VAR(state) == IDLE){
	return 0;
    }
    if(VAR(state) == READ_LOG_READING_DATA){
	VAR(data)[(int)VAR(count)] = data;
	VAR(count) ++;
	if(VAR(count) == LOG_ENTRY_SIZE){
	    VAR(state) = READ_LOG_STOP;
	    TOS_CALL_COMMAND(LOGGER_I2C_SEND_END)();
	    {
		int i; 
		dbg(DBG_LOG, ("log_read to %04x:", VAR(data)));
		for(i = 0; i < LOG_ENTRY_SIZE; i++) {
		    dbg(DBG_LOG, ("%02x,", VAR(data)[i]&0xff));
		}
		dbg(DBG_LOG,("\n"));
	    }
	    return 0;
	}else{
	    TOS_CALL_COMMAND(LOGGER_I2C_READ_BYTE)(VAR(count) !=
						   (LOG_ENTRY_SIZE - 1));
	}
    }
    return 1;
}




char TOS_EVENT(LOGGER_I2C_WRITE_BYTE_DONE)(char success){
    if(success == 0){
	dbg(DBG_ERROR, ("LOGGER_WRITE_FAILED"));
	//TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
	VAR(state) = IDLE;
	    TOS_CALL_COMMAND(LOGGER_I2C_SEND_END)();
	return 0;
    }
    
    if(VAR(state) == WRITING_TO_LOG){
	if(VAR(count) < LOG_ENTRY_SIZE){

	  dbg(DBG_LOG, ("LOGGER: byte sent: %02x, STATE: %d, COUNT: %d\n", VAR(data)[(int)VAR(count)]&0xff, VAR(state), VAR(count)));

	  TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)(VAR(data)[(int)VAR(count)]);
	  VAR(count) ++;
	}else{
	    VAR(state) = WRITE_LOG_STOP;
	    VAR(count) = 0;
	    TOS_CALL_COMMAND(LOGGER_I2C_SEND_END)();
	    return 0;
	}
    }else if(VAR(state) == WRITE_COMMAND){
	VAR(state) = WRITE_COMMAND_2;
	TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) >> 4) & 0x7f);
    }else if(VAR(state) == WRITE_COMMAND_2){
	VAR(state) = WRITING_TO_LOG;
	TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) << 4) & 0xf0);
    }else if(VAR(state) == READ_COMMAND){
	VAR(state) = READ_COMMAND_2;
	TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) >> 4) & 0x7f);
    }else if(VAR(state) == READ_COMMAND_2){
	VAR(state) = READ_COMMAND_3;
	TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) << 4) & 0xf0);
    }else if(VAR(state) == READ_COMMAND_3){
	VAR(state) = READ_COMMAND_4;
	TOS_CALL_COMMAND(LOGGER_I2C_SEND_START)();
    }else if(VAR(state) == READ_COMMAND_5){
	VAR(state) = READ_LOG_READING_DATA;
	TOS_CALL_COMMAND(LOGGER_I2C_READ_BYTE)(1);
    }

   return 1; 
}


char TOS_EVENT(LOGGER_I2C_SEND_START_DONE)(){
    if(VAR(state) == APPEND_LOG_START){
	VAR(state) = WRITE_COMMAND;
	 TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)(0xa0);
    }else if(VAR(state) == READ_LOG_START){
	VAR(state) = READ_COMMAND;
	 TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)(0xa0);
    }else if(VAR(state) == READ_COMMAND_4){ 
	VAR(state) = READ_COMMAND_5;
	TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)(0xa1);
    }
    return 1;
}

#ifndef FULLPC
void set_timeout() {
    outp(95, TCNT0);
    outp(0x04, TCCR0);
    sbi(TIMSK, TOIE0);
}
#else 
void set_timeout() {
    TOS_SIGNAL_EVENT(APPEND_LOG_DONE)(1);
}
#endif

char TOS_EVENT(LOGGER_I2C_SEND_END_DONE)(){
    char state = VAR(state);
    VAR(state) = IDLE;
    if(state == WRITE_LOG_STOP){
	VAR(last_line) ++;
	set_timeout();
    }else if(state == READ_LOG_STOP){
	TOS_SIGNAL_EVENT(READ_LOG_DONE)(VAR(data), 1);
    }
    dbg(DBG_LOG, ("done\n"));
    return 0;
}

TOS_INTERRUPT_HANDLER(_overflow0_, (void)) {
    outp(0x00, TCCR0);
    cbi(TIMSK, TOIE0);
    TOS_SIGNAL_EVENT(APPEND_LOG_DONE)(1);
}

/*									tab:4
 *
 *
 * "Copyright (c) 2002 and The Regents of the University 
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
 * Authors:		Alec Woo
 *
 *
 */

#include "tos.h"
#include "SENSEPOT.h"
#include "dbg.h"

//various states...
#define IDLE 0

#define READ_POT_START 11
#define READ_COMMAND 13
#define READ_COMMAND_2 14
#define READ_COMMAND_3 15
#define READ_COMMAND_4 16
#define READ_COMMAND_5 17
#define READ_POT_READING_DATA 18

#define WRITE_POT_START 30
#define WRITE_COMMAND 31
#define WRITE_COMMAND_2 32
#define WRITING_TO_POT 33

#define WRITE_POT_STOP 40 
#define READ_POT_STOP 41


#define TOS_FRAME_TYPE SENSEPOT_obj_frame
TOS_FRAME_BEGIN(SENSEPOT_obj_frame) {
        char data;
	char state;
        char addr;
        char pot;
}
TOS_FRAME_END(SENSEPOT_obj_frame);


char TOS_COMMAND(WRITE_POT)(char addr, char pot, char data){
    if(VAR(state) == IDLE){
      VAR(addr) = addr;
      VAR(pot) = pot;
      VAR(data) = data;
      VAR(state) = WRITE_POT_START;
      if(TOS_CALL_COMMAND(SENSEPOT_I2C_SEND_START)()){
	return 1;
      }else{
	VAR(state) = IDLE;
	return 0;
      }
    }else{
      return 0;
    }
}

char TOS_COMMAND(READ_POT)(char addr, char pot){
    if(VAR(state) == IDLE){
      VAR(addr) = addr;
      VAR(pot) = pot;
      VAR(state) = READ_POT_START;
      if(TOS_CALL_COMMAND(SENSEPOT_I2C_SEND_START)()){
	return 1;
      }else{
	VAR(state) = IDLE;
	return 0;
      }
    }else{
      return 0;
    }
}

char TOS_COMMAND(SENSEPOT_INIT)(){
    TOS_CALL_COMMAND(SENSEPOT_SUB_INIT)();
    VAR(state) = IDLE;

    dbg(DBG_BOOT, ("Logger initialized.\n"));
    return 1;
} 


char TOS_EVENT(SENSEPOT_I2C_READ_BYTE_DONE)(char data, char error){

    if(error){
	VAR(state) = IDLE;
	VAR(data) = 0;
	TOS_CALL_COMMAND(SENSEPOT_I2C_SEND_END)();
	return 0;
    }
    if(VAR(state) == IDLE){
	VAR(data) = 0;
	return 0;
    }
    if(VAR(state) == READ_POT_READING_DATA){
      VAR(state) = READ_POT_STOP;
      VAR(data) = data;
      TOS_CALL_COMMAND(SENSEPOT_I2C_SEND_END)();
      return 0;
    }
    return 1;
}


char TOS_EVENT(SENSEPOT_I2C_WRITE_BYTE_DONE)(char success){
    if(success == 0){
	dbg(DBG_ERROR, ("SENSEPOT_WRITE_FAILED"));
	VAR(state) = IDLE;
	TOS_CALL_COMMAND(SENSEPOT_I2C_SEND_END)();
	return 0;
    }    
    if(VAR(state) == WRITING_TO_POT){
      VAR(state) = WRITE_POT_STOP;
      TOS_CALL_COMMAND(SENSEPOT_I2C_SEND_END)();
      return 0;      
    }else if(VAR(state) == WRITE_COMMAND){
	VAR(state) = WRITE_COMMAND_2;
	TOS_CALL_COMMAND(SENSEPOT_I2C_WRITE_BYTE)(0 | ((VAR(pot) << 7)&0x80));
    }else if(VAR(state) == WRITE_COMMAND_2){
	VAR(state) = WRITING_TO_POT;
	TOS_CALL_COMMAND(SENSEPOT_I2C_WRITE_BYTE)(VAR(data));
    }else if(VAR(state) == READ_COMMAND){
	VAR(state) = READ_POT_READING_DATA;
	TOS_CALL_COMMAND(SENSEPOT_I2C_READ_BYTE)(0 | ((VAR(pot) << 7)&0x80));
    }
   return 1; 
}


char TOS_EVENT(SENSEPOT_I2C_SEND_START_DONE)(){
    if(VAR(state) == WRITE_POT_START){
	VAR(state) = WRITE_COMMAND;
	TOS_CALL_COMMAND(SENSEPOT_I2C_WRITE_BYTE)(0x58 | ((VAR(addr) << 1) & 0x06));
    }else if(VAR(state) == READ_POT_START){
	VAR(state) = READ_COMMAND;
	TOS_CALL_COMMAND(SENSEPOT_I2C_WRITE_BYTE)(0x59 | ((VAR(addr) << 1) & 0x06));
    }
    return 1;
}

char TOS_EVENT(SENSEPOT_I2C_SEND_END_DONE)(){
    char state = VAR(state);
    VAR(state) = IDLE;
    if(state == WRITE_POT_STOP){
      TOS_SIGNAL_EVENT(WRITE_POT_DONE)(1);
    }else if(state == READ_POT_STOP){
      TOS_SIGNAL_EVENT(READ_POT_DONE)(VAR(data), 1);
    }
    dbg(DBG_SENSEPOT, ("done\n"));
    return 0;
}




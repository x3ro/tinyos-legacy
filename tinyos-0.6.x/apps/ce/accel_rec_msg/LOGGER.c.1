/* LOGGER.C
* Crossbow....
* Rev History:
* Date:         Author:  Comments:
* Sept 26,2001  Asb      Added documentation to original TOS module.
*                        Modified read routine to read just 4 bytes
*                        i.e. write in 16 byte chunks
*                             read  in  4 byte chunks
* Oct 31,2001   Asb      Added APPEND_INIT to reinit the logger 
* DALLAS 24LC256 EPROM: 
*  Size            : 32K bytes
*  Clk(max)        : 100Khz
*  Byte Write Time : 5msec
*  Read/Write Control:
*    1st byte xmitted: 1-0-1-0-A2-A1-A0-R/W
*         1010    = header
*         A2..A0  = Same address as 24LC256 pins A2..A0
*         R/W     = 1 => following is to read EPROM: 0 => write EPROM
*    2nd byte xmitted: Address high byte
*    3rd byte xmitted: Address low  byte
*    4th byte xmitted: Data
*/

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

//LOG_ENTRY_SIZE sets the number of bytes read/written to/from EPROM
//This module uses the page mode EPROM writing.
//Do not change LOG_ENTRY_SIZE as addresses are incremented in blocks of 16
#define LOG_ENTRY_SIZE 16
#define LOG_ENTRY_SIZE_READ 4   //number of bytes to read when reading

//various states...
#define IDLE 0

#define READ_LOG_START 11
#define READ_COMMAND 13
#define READ_COMMAND_2 14
#define READ_COMMAND_3 15
#define READ_COMMAND_4 16
#define READ_COMMAND_5 17
#define READ_LOG_READING_DATA 18

#define APPEND_LOG_START 30        //start appending data to the EPROM
#define WRITE_COMMAND 31           //writing command to EPROM to start writing
#define WRITE_COMMAND_2 32         //writing start address to EPROM 
#define WRITING_TO_LOG 33          //writing data to ERPOM

#define WRITE_LOG_STOP 40          //waiting to stop write
#define READ_LOG_STOP 41           //waiting to stop read


#define TOS_FRAME_TYPE LOGGER_obj_frame
TOS_FRAME_BEGIN(LOGGER_obj_frame) {
    int last_line;    //last address in EPROM?
    char* data;       //pointer to the read/write data
	char state;       //tracks the state of the write/read operations
    char count;       //
	int current_line; //
}
TOS_FRAME_END(LOGGER_obj_frame);
//*****************************************************************************
//LOGGER_INIT
// - init all states
// - set EPROM address to zero
//*****************************************************************************
char TOS_COMMAND(LOGGER_INIT)(){
    TOS_CALL_COMMAND(LOGGER_SUB_INIT)();
    VAR(state) = 0;                           //set to idle state
    VAR(last_line) = 0;                       //set ERPOM address to zero?
    VAR(count) = 0;

    dbg(DBG_BOOT, ("Logger initialized.\n"));

    return 1;
} 
//*****************************************************************************
// APPEND_INIT
//  - init logger state - address zero
// 
//*****************************************************************************
char TOS_COMMAND(APPEND_INIT) () {
    VAR(state) = 0;                           //set to idle state
    VAR(last_line) = 0;                       //set ERPOM address to zero?
    VAR(count) = 0;
}
//*****************************************************************************
// APPEND_LOG
//  - append data to ERPOM
// Vars:
//   data       :pointer to write data
//   last_line  :EPROM address?
//*****************************************************************************
char TOS_COMMAND(APPEND_LOG) (char *data) {
    VAR(last_line) ++;
    return TOS_CALL_COMMAND(WRITE_LOG)(VAR(last_line), data);
}
//*****************************************************************************
// WRITE_LOG
//  - initiate write to EPROM
//  - then exit and wait for event completion 
// Vars:
//   data       :pointer to write data
//   line       :EPROM address?
//*****************************************************************************
char TOS_COMMAND(WRITE_LOG)(int line, char* data){
    if(VAR(state) == 0){
	   VAR(data) = data;                               //point to data buffer
 	   VAR(state) = APPEND_LOG_START;                  //state = starting to append 
	   VAR(current_line) = line;                       //set address
	   VAR(last_line)--;                               //?? 
	   VAR(count) = 0;                            
	   if(TOS_CALL_COMMAND(LOGGER_I2C_SEND_START)()){
	      return 1;
	   }else{
	      VAR(state) = 0;                             //failed to start EPROM write;reset
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
	//if(VAR(count) == LOG_ENTRY_SIZE){
    if(VAR(count) == LOG_ENTRY_SIZE_READ){    // asb
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
	    //TOS_CALL_COMMAND(LOGGER_I2C_READ_BYTE)(VAR(count) !=
//						   (LOG_ENTRY_SIZE - 1));
          TOS_CALL_COMMAND(LOGGER_I2C_READ_BYTE)(VAR(count) !=
						   (LOG_ENTRY_SIZE_READ - 1));     //asb
	}
    }
    return 1;
}


//*****************************************************************************
// LOGGER_I2C_WRITE_BYTE_DONE
//  - return here after LOGGER_I2C_WRITE_BYTE completed 
//  
//
//   
//*****************************************************************************
char TOS_EVENT(LOGGER_I2C_WRITE_BYTE_DONE)(char success){
    if(success == 0){                                        //write failed
    	dbg(DBG_ERROR, ("LOGGER_WRITE_FAILED"));
	    //TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
	    VAR(state) = IDLE;
	    TOS_CALL_COMMAND(LOGGER_I2C_SEND_END)();             //complete operation
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
	    TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) >> 4) & 0x7f);      //write address 
    }else if(VAR(state) == WRITE_COMMAND_2){
	    VAR(state) = WRITING_TO_LOG;
	    TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) << 4) & 0xf0);      //write address
    }else if(VAR(state) == READ_COMMAND){
	    VAR(state) = READ_COMMAND_2;
//	    TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) >> 4) & 0x7f);      //write address  
 	    TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) >> 6) & 0x7f);      //asb read address  
    }else if(VAR(state) == READ_COMMAND_2){
	    VAR(state) = READ_COMMAND_3;
//	    TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) << 4) & 0xf0);     //write address
		TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)((VAR(current_line) << 2) & 0xfc);     //asb - read address
    }else if(VAR(state) == READ_COMMAND_3){
	    VAR(state) = READ_COMMAND_4;
	    TOS_CALL_COMMAND(LOGGER_I2C_SEND_START)();
    }else if(VAR(state) == READ_COMMAND_5){
	    VAR(state) = READ_LOG_READING_DATA;
	    TOS_CALL_COMMAND(LOGGER_I2C_READ_BYTE)(1);
    }

   return 1; 
}
//*****************************************************************************
// LOGGER_I2C_SEND_START_DONE
//  - return here after LOGGER_I2C_SEND_START completed 
//  - then issue write/read command to start reading/writing 
//
//   
//*****************************************************************************
char TOS_EVENT(LOGGER_I2C_SEND_START_DONE)(){
    if(VAR(state) == APPEND_LOG_START){                  
     	VAR(state) = WRITE_COMMAND;
	    TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)(0xa0);          //write command to EPROM to start writing
    }else if(VAR(state) == READ_LOG_START){
	    VAR(state) = READ_COMMAND;
	    TOS_CALL_COMMAND(LOGGER_I2C_WRITE_BYTE)(0xa0);          //write command to EPROM to start reading
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

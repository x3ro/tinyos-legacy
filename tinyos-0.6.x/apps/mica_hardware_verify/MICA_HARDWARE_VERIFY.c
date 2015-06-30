/*                                                                      tab:4
 * MICA_HARDWARE_VERIFY: component description of basic command application
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
 * Authors:  Jason Hill 
 * Date:     Jan 29, 2002
 *
 *
 *
 * This component check the functionality of the device and sends a report message
 * over both the UART and the radio.  It should be run with the java program 
 * hardware_check.java which will interpret the report messages.  If the radio is 
 * to be tested, then program a second mote with generic_base_high_speed.  This will
 * forward the radio receptions to the java program for interpretation.  This program 
 * also prints out he serial_ID for the ID chip of the mote.
 */






#include "tos.h"
#include "MICA_HARDWARE_VERIFY.h"
#include "dbg.h"
/* Utility functions */

#define MICA_HARDWARE_VERIFY_MSG_TYPE 10 
#define READINGS_PER_PACKET 10 
#define DATA_CHANNEL 1

typedef struct {
    unsigned int source_mote_id;
    unsigned int last_reading_number;
    unsigned int channel;
    int data[READINGS_PER_PACKET];
}data_packet;

typedef struct {
    char serial_ID[8];
    char flash_check[3];
    char SPI_FIX;
    char flash_comm;
    char RX_TEST;
    char count;
    char send_type;

}diag_packet;

#define TOS_FRAME_TYPE MICA_HARDWARE_VERIFY_frame
TOS_FRAME_BEGIN(MICA_HARDWARE_VERIFY_frame) {
    char count;
    TOS_Msg diag;
}
TOS_FRAME_END(MICA_HARDWARE_VERIFY_frame);


/* MICA_HARDWARE_VERIFY_INIT:  
   flash the LEDs
   initialize lower components.
   initialize component state, including constant portion of msgs.
*/
void check_FLASH();
void check_SERIAL_ID();
void check_SPI_FIX();

char TOS_COMMAND(MICA_HARDWARE_VERIFY_INIT)(){
	
    TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDy_off)();   
    TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDr_off)();
    TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDg_off)();       /* light LEDs */

    check_SERIAL_ID();
    check_SPI_FIX();
    check_FLASH();

    TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_SUB_INIT)();       /* initialize lower components */
    TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_CLOCK_INIT)(128, 5);    /* set clock interval */
    //turn on the sensors so that they can be read.
    SET_PW1_PIN();
    SET_PW2_PIN();
    dbg(DBG_BOOT, ("MICA_HARDWARE_VERIFY initialized\n"));
    return 1;
}

/* MICA_HARDWARE_VERIFY_START
   start data reading.
*/
char TOS_COMMAND(MICA_HARDWARE_VERIFY_START)(){
    return 1;
}


char TOS_EVENT(MICA_HARDWARE_VERIFY_CHANNEL1_DATA_EVENT) (short data) {
    if(data > 0x20)TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDr_on)();
    else TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDr_off)();
    return 1;
}



/*   MICA_HARDWARE_VERIFY_SUB_MSG_SEND_DONE event handler:
     When msg is sent, shot down the radio.
*/
char TOS_EVENT(MICA_HARDWARE_VERIFY_SUB_MSG_SEND_DONE)(TOS_MsgPtr msg){
    return 1;
}


/* Clock Event Handler: 
   signaled at end of each clock interval.

 */
void TOS_EVENT(MICA_HARDWARE_VERIFY_CLOCK_EVENT)(){
	diag_packet* pack = (diag_packet*)VAR(diag).data;
	int state = pack->count ++;
	unsigned short dest = 0;
	dest = (pack->send_type ^= 1) & 0x1;
	if(dest){
		dest = TOS_UART_ADDR;
	}else{
		dest = 0xffff;
	}
  	if (state & 1) TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDy_on)();  else TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDy_off)();
  	if (state & 2) TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDg_on)();  else TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDg_off)();
  	if (state & 4) TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDr_on)();  else TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_LEDr_off)();
    	TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_SUB_SEND_MSG)(dest, 0xff, &VAR(diag));
}

TOS_MsgPtr TOS_MSG_EVENT(RESET_COUNTER)(TOS_MsgPtr msg){
	diag_packet* pack = (diag_packet*)VAR(diag).data;
	int state = pack->RX_TEST ++;
    	//TOS_CALL_COMMAND(MICA_HARDWARE_VERIFY_SUB_SEND_MSG)(TOS_BCAST_ADDR, 0xaa, &VAR(diag));
	return msg;
}




char serial_delay_null_func(){
	return 1;
}
char serial_delay(int u_sec){
     int cnt;
     for(cnt = 0; cnt < u_sec / 8; cnt ++) serial_delay_null_func();
     return 1;
}



unsigned char serial_ID_read(){
    int i;
    unsigned char data = 0;
    for(i = 0; i < 8; i ++){
        data >>= 1;
        data &= 0x7f;
        MAKE_ONE_WIRE_OUTPUT();
        serial_delay(1);
        MAKE_ONE_WIRE_INPUT();
        serial_delay(10);
        if(READ_ONE_WIRE_PIN()){
                data |= 0x80;
        }
        serial_delay(30);
    }
    return data;
}
char serial_ID_send(unsigned char data){
    int i;
    for(i = 0; i < 8; i ++){
        MAKE_ONE_WIRE_OUTPUT();
        serial_delay(1);
        if(data & 0x1){
            MAKE_ONE_WIRE_INPUT();
        }
        serial_delay(50);
        MAKE_ONE_WIRE_INPUT();
        serial_delay(10);
        data >>= 1;
    }
    return 1;
}



void check_SERIAL_ID(){
     char cnt = 0;
     CLR_ONE_WIRE_PIN();
     MAKE_FLASH_SELECT_INPUT();
     MAKE_ONE_WIRE_OUTPUT();
     serial_delay(400);
     cnt = 0;
     MAKE_ONE_WIRE_INPUT();
     while(0 == READ_ONE_WIRE_PIN() && cnt < 30){
	cnt ++;
	serial_delay(40);
     }
     if(cnt < 30){
	diag_packet* pack = (diag_packet*)VAR(diag).data;
     	serial_delay(200);
        serial_ID_send(0x33);
	for(cnt = 0; cnt < 8; cnt ++){
	    pack->serial_ID[(int)cnt] = serial_ID_read();
	}
     }
}



char send_byte(char input){
    int i;
    for(i = 0; i < 8; i ++){
        if(input & 0x80){
           SET_FLASH_OUT_PIN();
        }else{
           CLR_FLASH_OUT_PIN();
        }
        input <<= 1;
        SET_FLASH_CLK_PIN();
        if(READ_FLASH_IN_PIN()){
          input |= 0x1;
        }
        CLR_FLASH_CLK_PIN();
    }
    return input;
}


void check_FLASH(){
	diag_packet* pack = (diag_packet*)VAR(diag).data;
     	MAKE_ONE_WIRE_INPUT();
	MAKE_FLASH_SELECT_OUTPUT();
	CLR_FLASH_SELECT_PIN();
  	send_byte(0x84);
  	send_byte(0x0);
  	send_byte(0x0);
  	send_byte(0x0);
  	send_byte(0x1);
  	send_byte(0x8f);
  	send_byte(0x9);
   	SET_FLASH_SELECT_PIN();
     	serial_delay(200);
   	CLR_FLASH_SELECT_PIN();
  	send_byte(0xD4);
  	send_byte(0x0);
  	send_byte(0x0);
  	send_byte(0x0);
  	send_byte(0x0);
	pack->flash_check[0] = send_byte(0x0);
	pack->flash_check[1] = send_byte(0x0);
	pack->flash_check[2] = send_byte(0x0);
  	CLR_FLASH_OUT_PIN();
	SET_FLASH_SELECT_PIN();
}

void check_SPI_FIX(){
	//MAKE
	diag_packet* pack = (diag_packet*)VAR(diag).data;
	pack->SPI_FIX = 0;
	pack->flash_comm = 1;
     	MAKE_ONE_WIRE_OUTPUT();
	MAKE_FLASH_SELECT_INPUT();
	CLR_ONE_WIRE_PIN();
     	serial_delay(200);
	
	if(READ_FLASH_SELECT_PIN() == 0) pack->SPI_FIX |= 1;
	else pack->SPI_FIX |=2;
	SET_ONE_WIRE_PIN();
     	serial_delay(200);
	if(READ_FLASH_SELECT_PIN() == 1) pack->SPI_FIX |= 4;
	else pack->SPI_FIX |=8;
     	MAKE_ONE_WIRE_INPUT();
}


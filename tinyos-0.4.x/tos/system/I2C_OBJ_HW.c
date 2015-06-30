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
 * Authors:		Jason Hill, Robert Szewczyk
 *
 *
 */

#include "tos.h"
#include "I2C_OBJ.h"
#include "dbg.h"

//states
#define READ_DATA 1
#define WRITE_DATA 2
#define SEND_START 3
#define SEND_END 4

#define TOS_FRAME_TYPE I2C_frame
TOS_FRAME_BEGIN(I2C_frame) {
        char state;
}
TOS_FRAME_END(I2C_frame);

char TOS_COMMAND(I2C_init)(){
	dbg(DBG_I2C, ("i2c_init\n"));
	sbi(PORTC, 0);
	sbi(DDRC, 0);
	sbi(PORTC, 1);
	sbi(DDRC, 1);
	outp(0x08, TWBR);
	VAR(state) = 0;
	return 1;
}

char TOS_COMMAND(I2C_read)(char ack){
    if(VAR(state) != 0) return 0;
    VAR(state) = READ_DATA;
    if (ack) {
	sbi(TWCR, TWEA);
    } else {
	cbi(TWCR, TWEA);
    }
    return 1;
}

char TOS_COMMAND(I2C_write)(char data){
    if(VAR(state) != 0) return 0;
    VAR(state) = WRITE_DATA;
    outp(data, TWDR);
    return 1;
}
char TOS_COMMAND(I2C_send_start)(){
    if(VAR(state) != 0) return 0;
    VAR(state) = SEND_START;
    outp(0x05, TWCR); //initialize 2-wire control register, enable interrupts
    sbi(TWCR, TWSTA); //transmit the start condition
    return 1;
}   
char TOS_COMMAND(I2C_send_end)(){
    if(VAR(state) != 0) return 0;
    VAR(state) = SEND_END;
    sbi(TWCR, TWSTO); //transmit the stop condition
    return 1;
}

TOS_INTERRUPT_HANDLER(_twi_, ()) {
    char state = VAR(state);
    VAR(state) = 0;
    switch (state) {
    case WRITE_DATA:
	TOS_SIGNAL_EVENT(I2C_write_done) (inp(TWSR) & 0x08);
	break;
    case READ_DATA:
	TOS_SIGNAL_EVENT(I2C_read_done) ();
	break;
    case SEND_START:
	TOS_SIGNAL_EVENT(I2C_send_start_done)();
	break;
    case SEND_END:
	TOS_SIGNAL_EVENT(I2C_send_end_done)();
	break;
    }
    if (VAR(state) != 0) {
	sbi(TWCR, TWINT);
    }
}

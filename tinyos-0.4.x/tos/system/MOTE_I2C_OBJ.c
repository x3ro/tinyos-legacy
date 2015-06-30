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
#include "MOTE_I2C_OBJ.h"


#define TOS_FRAME_TYPE I2C_frame
TOS_FRAME_BEGIN(I2C_frame) {
        char state;
	int data1;
	int data2;
	int addr;
}
TOS_FRAME_END(I2C_frame);

inline void i2c_read(int a,int* b, int* c){
	*b = 0x1234;
	*c = 0x5678;
}
void i2c_write(int a, int b, int c){}; 

TOS_TASK(I2C_task){
    if(VAR(state) == 1){
	i2c_read(VAR(addr),&VAR(data1), &VAR(data2)); 
	TOS_SIGNAL_EVENT(MOTE_I2C_read_done)(VAR(data1), VAR(data2));
    }else{
	i2c_write(VAR(addr), VAR(data1), VAR(data2));
	TOS_SIGNAL_EVENT(MOTE_I2C_write_done)(1);
    }
	VAR(state) = 0;
}



char TOS_COMMAND(MOTE_I2C_init)(){
	VAR(state) = 0;
	return 1;
}

char TOS_COMMAND(MOTE_I2C_read)(int addr){
    if(VAR(state) != 0) return 0;
    VAR(state) = 1;
    TOS_POST_TASK(I2C_task);
    return 1;
}

char TOS_COMMAND(MOTE_I2C_write)(int addr, int data, int data2){
    if(VAR(state) != 0) return 0;
    VAR(state) = 2;
    VAR(addr) = addr;
    VAR(data1) = data;
    VAR(data2) = data2;
    TOS_POST_TASK(I2C_task);
    return 1;
}


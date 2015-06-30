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
#include "MAIN.h"
#include "dbg.h"

/* grody stuff to set mote address into code image */

short TOS_LOCAL_ADDRESS = 1;
unsigned char LOCAL_GROUP = DEFAULT_LOCAL_GROUP;

/**************************************************************
 *  Generic main routine.  Issues an init command to subordinate
 *  modules and then a start command.  These propagate down the
 *  tree as required.  The application component sits below main
 *  and above various levels of hardware support components
 *************************************************************/


int main() {    
    /* reset the ports, and set the directions */
    SET_PIN_DIRECTIONS();
    TOS_CALL_COMMAND(MAIN_SUB_POT_INIT)(0);
    TOS_sched_init();
    
    TOS_CALL_COMMAND(MAIN_SUB_INIT)();
    TOS_CALL_COMMAND(MAIN_SUB_START)();
    dbg(DBG_BOOT,("mote initialized.\n"));

    while(1){
	while(!TOS_schedule_task()) { };
	sbi(MCUCR, SE);
	asm volatile ("sleep" ::);
        asm volatile ("nop" ::);
        asm volatile ("nop" ::);
    }
}
	

char TOS_EVENT(MAIN_SUB_SEND_DONE)(TOS_MsgPtr msg){return 1;}
char TOS_EVENT(MAIN_SUB_APPEND_DONE)(char success){return 1;}
char TOS_EVENT(MAIN_SUB_READ_DONE)(char* data, char success){return 1;}






/*									tab:4
 * SENSE.c - use tasks to display processed sensor value on the LEDs
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
 * Authors:   David Culler
 * History:   created 10/9/2001
 *
 */

#include "tos.h"
#include "SENSE.h"


//Frame Declaration

#define maxdata 8
#define maskdata 0x7
#define shiftdata 3

#define TOS_FRAME_TYPE SENSE_frame
TOS_FRAME_BEGIN(SENSE_frame) {
  char head;
  char currentBuffer;
  int data[maxdata*2];
  int * bufferPtr[2];
  short nsamples;
}
TOS_FRAME_END(SENSE_frame);

char TOS_COMMAND(SENSE_INIT)(){
    VAR(head) = 0;
    VAR(currentBuffer) = 0;
    VAR(bufferPtr)[0] = &(VAR(data)[0]);
    VAR(bufferPtr)[1] = &(VAR(data)[8]);
    TOS_CALL_COMMAND(SENSE_SUB_INIT)(); 
    return 1;
}

/* SENSE_START: 
   initialize clock component to generate periodic events.
*/
char TOS_COMMAND(SENSE_START)(short nsamples, char scale, char ticks){
    VAR(nsamples) = nsamples;
    TOS_CALL_COMMAND(SENSE_CLOCK_INIT)(scale, ticks); 
    return 1;
}

/* Clock Event Handler:
   Increment counter and display
 */
void TOS_EVENT(SENSE_CLOCK_EVENT)(){
    VAR(nsamples)--;
    if (VAR(nsamples)== 0) {
	// Stop the clock. 
	TOS_CALL_COMMAND(SENSE_CLOCK_INIT)(255, 0);
    }
    TOS_CALL_COMMAND(SENSE_LEDr_toggle)();
    TOS_CALL_COMMAND(SENSE_GET_DATA)();
}

/* Data ready event Handler:
   store the reading in the buffer, when the buffer fills up, write it out to
   the logger. 
*/
char TOS_EVENT(SENSE_DATA_READY)(short data){
    int p = VAR(head);
    VAR(bufferPtr)[VAR(currentBuffer)][p] = data;
    VAR(head) = ((p+1) & maskdata);
    if (VAR(head) == 0) {
	TOS_CALL_COMMAND(SENSE_APPEND_LOG)((char *)VAR(bufferPtr)[VAR(currentBuffer)]);
	VAR(currentBuffer) ^= 0x01;
    }
    return 1;
}

char TOS_EVENT(SENSE_LOG_WRITE_DONE)(char status) {
    return 1;
}


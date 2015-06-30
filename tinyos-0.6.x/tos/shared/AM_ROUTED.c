/*									tab:4
 *  AM_ROUTED
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
 * Authors:		Jason Hill, David Culler
 * Revision History:    10/25 extracted app specfic data collection
 *
 */

/*
  AM_ROUTED provides delivery of data readings either to the local cell
  or to a base (host) node.  

  Internally, it handles two classes of messages.  
   handler 5: derives base routing tree and propagates routing updates
   handler 6: propages base messages to the base, whereupon the
    encapsulated handler is invoked.

  Demonstration of buffer management and synchronization semantics.
  Active Message send buffers must remain valid until the message is sent.
  This is indicated by the AM_send_done event.
  The lower level msg component may refuse the send.  The AM_send_done event 
  is used to restry.
*/

#include "tos.h"
#include "AM_ROUTED.h"

extern const short TOS_LOCAL_ADDRESS;

#define MAXFILTERS 8
#define FILTERMASK 7

#define TOS_FRAME_TYPE ROUTED_obj_frame
TOS_FRAME_BEGIN(ROUTED_obj_frame) {
  char msgfilter[MAXFILTERS];	/* xsums for duplicate supression */
  char mfptr;			/* revolvng ptr into msgfilter */
  char hops;
  char route;			/* upwards node identifier */
  char epoch;
  char pendingData;		/* 0: idle, 1: pending send */
  char databuf[30];		/* data outgoing msg buffer */
  char beaconbuf[30];		/* beacon outgoing msg buffer */
}
TOS_FRAME_END(ROUTED_obj_frame);

char mfLookup(char sum) {
  int i;
  for (i = 0; i< MAXFILTERS; i++) {
    if (VAR(msgfilter)[i] == sum) return 1;
  }
  return 0;
}

void mfInsert(char sum) {
  int i = VAR(mfptr);
  VAR(mfptr) = (i+1) & FILTERMASK;
  VAR(msgfilter)[i] = sum;
}

char mfSum(char *msg, int len) {
  int i;
  char sum = 0;
  for (i=0; i<len; i++) sum = sum+msg[i];
  return sum;
}

char TOS_COMMAND(ROUTED_INIT)(){
  int i;
  VAR(pendingData) = 0;
  for (i=0; i<MAXFILTERS; i++) VAR(msgfilter)[i] = 0;
  VAR(mfptr) = 0;

  //initialize sub components
  TOS_CALL_COMMAND(ROUTED_SUB_INIT)();
#ifdef BASE_STATION
    //set beacon rate for route updates to be sent
    TOS_COMMAND(ROUTED_CLOCK_INIT)(255, 0x06);
	
   //set route to base station over UART.
    VAR(route) = TOS_UART_ADDR;
    VAR(hops)  = 0;
    printf("base route set to %2x\n", VAR(route));
#else
  //set rate for sampling and data update
    TOS_COMMAND(ROUTED_CLOCK_INIT)(255, 0x04);
    VAR(route) = TOS_BCAST_ADDR;	/* broadcast till route established */
    VAR(hops)  = 0xFF;
#endif
   return 1;
}

char TOS_COMMAND(ROUTED_SEND_LOCAL)(short data)
{
  if (VAR(pendingData)) return 0; /* fail, previous output pending */  
  VAR(databuf)[0] = data >> 8;
  VAR(databuf)[1] = data & 0xff;
  VAR(databuf)[2] = TOS_LOCAL_ADDRESS;
  return TOS_CALL_COMMAND(ROUTED_SUB_SEND_MSG)(TOS_BCAST_ADDR,6,VAR(databuf));
}

char TOS_COMMAND(ROUTED_SEND_HOST)(char val0, char val1, char val2, char val3,
				   char val4, char val5, char val6, char val7)
{
  if (VAR(pendingData)) return 0; /* fail, previous output pending */
  VAR(databuf[0]) = val0;
  VAR(databuf[1]) = val1;
  VAR(databuf[2]) = val2;
  VAR(databuf[3]) = val3;
  VAR(databuf[4]) = val4;
  VAR(databuf[5]) = val5;
  VAR(databuf[6]) = val6;
  VAR(databuf[7]) = val7;
  if (!TOS_CALL_COMMAND(ROUTED_SUB_SEND_MSG) (TOS_UART_ADDR,6,VAR(databuf))) {
    VAR(pendingData) = 1;		/* on its way */
  }
  return 1;
}


/* ROUTED_SEND_BASE
   Propagate msg to base
   0 - 5 addresses on route to base
   6:7   data value

   Attemp to send msg to base.  If AM layer is busy, mark as pending
   for AM_send_done.
   If already pending, return busy.

*/
char TOS_COMMAND(ROUTED_SEND_BASE)(short val)
{
  if (VAR(pendingData)) return 0; /* fail, previous output pending */
  VAR(databuf[0]) = (val >> 8) & 0xff;
  VAR(databuf[1]) = val & 0xff;
  VAR(databuf[2]) = TOS_LOCAL_ADDRESS;
  VAR(databuf[3]) = 0;
  VAR(databuf[4]) = 0;
  VAR(databuf[5]) = 0;
  VAR(databuf[6]) = VAR(route);
  VAR(databuf[7]) = VAR(epoch);
  if (!TOS_CALL_COMMAND(ROUTED_SUB_SEND_MSG) (VAR(route),6,VAR(databuf))) {
    VAR(pendingData) = 1;		/* on its way */
  }
  return 1;
}

/* AM_msg_handler_6:
   Forward data packet toward base
   Shift address sequence 2-4 downward
   Append self to front
*/
char TOS_MSG_EVENT(AM_msg_handler_6)(char* data){
    //this handler forwards packets traveling to the base.
  TOS_CALL_COMMAND(ROUTED_LED2_ON)();		/* green */
  if(VAR(route) != 0){	/* forward packet */
#ifndef BASE_STATION      
    data[5] = data[4];
    data[4] = data[3];
    data[3] = data[2];
    data[2] = TOS_LOCAL_ADDRESS;
#endif
    //send the packet.
    TOS_CALL_COMMAND(ROUTED_SUB_SEND_MSG)(VAR(route),6,data);
    printf("routing to home via %x\n", VAR(route));
  }
  return 1;
}



/* AM_msg_handler_5 - routing beacon
 * 
 * msg format:
 *  0   - epoch
 *  1   - length of routing list
 *  2-7 - routing list
 *
 * Beacon is suppressed if it is longer than previous accepted beacon
 * or if it appears to be a copy of previous beacon.
 */
char TOS_MSG_EVENT (AM_msg_handler_5)(char* data){
  char sum = mfSum(data,8);
  char newepoch  = data[0];
  int  hops      =  data[1];
  TOS_CALL_COMMAND(ROUTED_LED2_ON)();		/* flash green LED */
  
  if ((hops <= VAR(hops)) && !mfLookup(sum)) { /* new route update */
    mfInsert(sum);
    VAR(epoch) = newepoch;
    VAR(hops) = hops;
    hops++;
    VAR(route) = data[hops];
    data[1] = hops;
    data[hops+1] = TOS_LOCAL_ADDRESS;
    // propagate route beacon outward
    TOS_CALL_COMMAND(ROUTED_SUB_SEND_MSG)(TOS_BCAST_ADDR,5,data);
    printf("route set to %x\n", VAR(route));
  }
  else {
    printf("route update %x[%x]ignored\n", newepoch,data[hops+1]);
  }
  return 1;
}


/* AM_msg_handler_7 - updload bytecode
 * 0 - len
 * 1:len-1 bytes of code
 * 
 * broadcast out from base station
 */
char TOS_MSG_EVENT (AM_msg_handler_7)(char* data){
  char sum = mfSum(data,8);
  TOS_CALL_COMMAND(ROUTED_LED3_ON)();	
  if (!mfLookup(sum)) {
    mfInsert(sum);
    TOS_SIGNAL_EVENT(ROUTED_CAPSULE_EVENT)(data);
    return TOS_CALL_COMMAND(ROUTED_SUB_SEND_MSG)(TOS_BCAST_ADDR,7,data);
  }
  return 0;			/* duplicate suppressed */
}




char TOS_EVENT(AM_msg_send_done)(char success){
  if (VAR(pendingData)) {
    if (TOS_CALL_COMMAND(ROUTED_SUB_SEND_MSG) (VAR(route),6,VAR(databuf))) {
      VAR(pendingData) = 0;		/* on its way */
    }
  }
  return 1;
}


void TOS_EVENT (ROUTED_CLOCK_EVENT)(){
  TOS_CALL_COMMAND(ROUTED_LED2_OFF)();		
  TOS_CALL_COMMAND(ROUTED_LED3_OFF)();		
  printf("routed clock\n");
#ifdef BASE_STATION
  /* Base station initiates route beacon  */
  VAR(beaconbuf[0]) = VAR(epoch)++;
  VAR(beaconbuf[1]) = 1;
  VAR(beaconbuf[2]) = TOS_LOCAL_ADDRESS;
  TOS_CALL_COMMAND(ROUTED_SUB_SEND_MSG)(TOS_BCAST_ADDR, 5, VAR(beaconbuf));
#endif
  TOS_SIGNAL_EVENT(SUPER_CLOCK_EVENT)();
}




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


//this components explores routing topology and then broadcasts back
// light readings.

#include "tos.h"
#include "MOTE_TEST.h"

extern const short TOS_LOCAL_ADDRESS;

struct uart_ping_packet{
	char buf[28];
};
struct data_collection_packet{
	char source;
	char hops[5];
	int data;
};

#define TOS_FRAME_TYPE MOTE_TEST_obj_frame
TOS_FRAME_BEGIN(MOTE_TEST_obj_frame) {
        char route;
	char set;
	TOS_Msg msg_buf;
	char place;
	char state;
}
TOS_FRAME_END(MOTE_TEST_obj_frame);

char TOS_COMMAND(MOTE_TEST_INIT)(){
    //initialize sub components
   TOS_CALL_COMMAND(MOTE_TEST_SUB_INIT)();
   //set beacon rate for route updates to be sent
 	TOS_COMMAND(MOTE_TEST_SUB_CLOCK_INIT)(255, 0x05);
	printf("base route set to TOS_UART_ADDR\n");
	//route to base station is over UART.
	VAR(route) = TOS_UART_ADDR;
	VAR(set) = 1;
	VAR(place) = 0;
	VAR(msg_buf).data[0] = 1;
	VAR(msg_buf).data[1] = TOS_LOCAL_ADDRESS;
   return 1;
}


//This handler responds to routing updates.
TOS_MsgPtr TOS_MSG_EVENT(AM_msg_handler_5)(TOS_MsgPtr msg){ 
	char* data = msg->data;
    TOS_CALL_COMMAND(ROUTE_LED3_TOGGLE)();
    //if route hasn't already been set this period...
    if(VAR(set) == 0){
	//record route
	VAR(route) = data[(int)data[0]];
	VAR(set) = 8;
       	data[0] ++;
	//create a update packet to be sent out.
        data[(int)data[0]] = TOS_LOCAL_ADDRESS;
	//send the update packet.
	TOS_CALL_COMMAND(MOTE_TEST_SUB_SEND_MSG)(TOS_BCAST_ADDR,5,msg);
	printf("route set to %x\n", VAR(route));
    }
	else printf("route already set to %x\n", VAR(route));
    return msg;
}

TOS_MsgPtr TOS_MSG_EVENT(AM_msg_handler_6)(TOS_MsgPtr msg){
	char* data = msg->data;
	TOS_CALL_COMMAND(ROUTE_LED2_TOGGLE)();
	data[6] = 0xff;
    TOS_CALL_COMMAND(MOTE_TEST_SUB_SEND_MSG)(TOS_UART_ADDR,6,msg);
    printf("routing to home %x\n", VAR(route));
    return msg;
}


void TOS_EVENT(MOTE_TEST_SUB_CLOCK)(){
    printf("route clock\n");
    if(VAR(state) == 0){
	//send out the route update to test TX.
	//if is the base, then it should send out the route update.
	VAR(msg_buf).data[0] = 1;
	VAR(msg_buf).data[1] = TOS_LOCAL_ADDRESS;
	TOS_CALL_COMMAND(MOTE_TEST_SUB_SEND_MSG)(TOS_BCAST_ADDR, 5,&VAR(msg_buf));
	VAR(state) ++;
    }else if(VAR(state) == 1){
	//send out a packet to the uart;
	TOS_CALL_COMMAND(MOTE_TEST_SUB_SEND_MSG)(TOS_UART_ADDR, 6,&VAR(msg_buf));
	VAR(state) ++;
    }else{
	TOS_CALL_COMMAND(MOTE_TEST_SUB_READ)(0x2);
	VAR(state) = 0;
    }
    TOS_CALL_COMMAND(ROUTE_LED1_TOGGLE)();
}



//testing reading form the local sensors.
char TOS_EVENT(MOTE_TEST_SUB_DATA_READY)(int data){
    if(VAR(route) != 0){
	struct data_collection_packet* pack = (struct data_collection_packet*) &VAR(msg_buf);
        //if a new data packet needs to be sent, go for it.
	
	//VAR(buf)[6] = data >> 8;
	//VAR(buf)[7] = data & 0xff;
	//VAR(buf)[0] = TOS_LOCAL_ADDRESS;
	////VAR(buf)[1] = VAR(route);
	//TOS_CALL_COMMAND(MOTE_TEST_SUB_SEND_MSG)(TOS_BCAST_ADDR, 6,VAR(buf));
	pack->source = TOS_LOCAL_ADDRESS;
	pack->hops[0] = VAR(route);
	pack->data = data;
	TOS_CALL_COMMAND(MOTE_TEST_SUB_SEND_MSG)(TOS_UART_ADDR, 6,(char*)pack);
	//blink the LED
	TOS_CALL_COMMAND(ROUTE_LED3_TOGGLE)();
    }
    //increment the counter and store the previous reading.
    return 1;
}




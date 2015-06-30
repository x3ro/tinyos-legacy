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
#include "CONNECT_ACCEL.h"

extern const char TOS_LOCAL_ADDRESS;


#define TOS_FRAME_TYPE ROUTE_obj_frame
TOS_FRAME_BEGIN(ROUTE_obj_frame) {
        char route;
	char set;
	char buf[28];
	char place;
	char prev_x_axis;
	char prev_y_axis;
}
TOS_FRAME_END(ROUTE_obj_frame);

struct accel_packet{
	char from;
	char to;
	char data[4];
	char x_axis;
	char y_axis;
};             


char TOS_COMMAND(CONNECT_ACCEL_INIT)(){
    //initialize sub components
   TOS_CALL_COMMAND(CONNECT_ACCEL_SUB_INIT)();
#ifdef BASE_STATION
   //set beacon rate for route updates to be sent
 	TOS_COMMAND(CONNECT_ACCEL_SUB_CLOCK_INIT)(0x06);
	printf("base route set to TOS_UART_ADDR\n");
	//route to base station is over UART.
	VAR(route) = TOS_UART_ADDR;
	VAR(set) = 1;
	VAR(place) = 0;
	VAR(buf)[0] = 1;
	VAR(buf)[1] = TOS_LOCAL_ADDRESS;
#else
	//set rate for sampling.
 	TOS_COMMAND(CONNECT_ACCEL_SUB_CLOCK_INIT)(0x03);
	VAR(set) = 0;
	VAR(route) = 0;
#endif
   return 1;
}


void update_connections(char source, char strength){
    //first off, update the local state to reflect being able to 
     //hear this sender.
     
     VAR(buf)[8 + VAR(place)] = source;
     VAR(buf)[8 + VAR(place) + 1] = strength;
     VAR(place) = (VAR(place) + 2) & 0xf;


}

//This handler responds to routing updates.
char TOS_MSG_EVENT(AM_msg_handler_5)(char* data){
    //clear LED2 when update is received.
#ifdef WEC
    update_connections(data[(int)data[0]], 0xff);
#else
    update_connections(data[(int)data[0]], data[28]);
#endif
    
    TOS_CALL_COMMAND(ROUTE_LED2_OFF)();
    //if route hasn't already been set this period...
    if(VAR(set) == 0){
	//record route
	VAR(route) = data[(int)data[0]];
	VAR(set) = 8;
       	data[0] ++;
	//create a update packet to be sent out.
        data[(int)data[0]] = TOS_LOCAL_ADDRESS;
	//send the update packet.
	TOS_CALL_COMMAND(CONNECT_ACCEL_SUB_SEND_MSG)(TOS_BCAST_ADDR,5,data);
	printf("route set to %x\n", VAR(route));
    }
	else printf("route already set to %x\n", VAR(route));
    return 1;
}

char TOS_MSG_EVENT(AM_msg_handler_6)(char* data){
    //this handler forwards packets traveling to the base.
    	char source;
	TOS_CALL_COMMAND(ROUTE_LED2_OFF)();
     //if this is the first hop on the route, then use the origin of the packet<     //as the name of the person who sent the packet to you instead of the 
     //last hop ID (which is null)
     source = data[2];
     if(source == 0) {
       source = data[0];
     }
#ifdef WEC
    update_connections(source, 0xff);
#else
    update_connections(source, data[28]);
#endif

    //if a route is know, forward the packet towards the base.
    if(VAR(route) != 0 && data[1] == TOS_LOCAL_ADDRESS){
#ifdef BASE_STATION
#ifdef WEC
	data[27] = 0xff;    
#else
	data[27] = data[28];
#endif
	TOS_CALL_COMMAND(CONNECT_ACCEL_SUB_SEND_MSG)(TOS_UART_ADDR,6,data);
#else
	//update the packet.
	data[5] = data[4];
	data[4] = data[3];
	data[3] = data[2];
	data[2] = data[1];
	data[1] = VAR(route);
	//send the packet.
	TOS_CALL_COMMAND(CONNECT_ACCEL_SUB_SEND_MSG)(TOS_BCAST_ADDR,6,data);
#endif
	printf("routing to home %x\n", VAR(route));
    }
    return 1;
}


void TOS_EVENT(CONNECT_ACCEL_SUB_CLOCK)(){
    //clear LED3 when the clock ticks.
    TOS_CALL_COMMAND(ROUTE_LED3_OFF)();
    printf("route clock\n");
#ifdef BASE_STATION
	//if is the base, then it should send out the route update.
	TOS_CALL_COMMAND(CONNECT_ACCEL_SUB_SEND_MSG)(TOS_BCAST_ADDR, 5,VAR(buf));
#else
	//decrement the set var to know when a period is over.
	if(VAR(set) > 0) VAR(set) --;
	//read the value from the sensor.
	TOS_COMMAND(CONNECT_ACCEL_SUB_READ)(0x2);
#endif //BASE_STATION
    TOS_CALL_COMMAND(ROUTE_LED1_TOGGLE)();

}


char TOS_EVENT(CONNECT_ACCEL_SUB_SECOND_DATA_READY)(int data){
    //when the data comes back from the sensor, see if the counter
	struct accel_packet* pack = (struct accel_packet*)VAR(buf);        
	data -= 0x100;
	pack->x_axis = ((data) & 0xff) - VAR(prev_x_axis);
	VAR(prev_x_axis) = (data) & 0xff; 
	pack->from = TOS_LOCAL_ADDRESS;
	pack->to = VAR(route);
	TOS_CALL_COMMAND(CONNECT_ACCEL_SUB_SEND_MSG)(TOS_BCAST_ADDR, 6,VAR(buf));
	//blink the LED
	TOS_CALL_COMMAND(ROUTE_LED3_OFF)();
        return 1;
}



char TOS_EVENT(CONNECT_ACCEL_SUB_FIRST_DATA_READY)(int data){
    //when the data comes back from the sensor, see if the counter
	struct accel_packet* pack = (struct accel_packet*)VAR(buf);        
        TOS_CALL_COMMAND(ROUTE_LED3_ON)();
	data -= 0x100;
	pack->y_axis = ((data) & 0xff) - VAR(prev_y_axis);
	VAR(prev_y_axis) = (data) & 0xff; 
	TOS_COMMAND(CONNECT_ACCEL_SUB_READ)(0x3);
        return 1;
}




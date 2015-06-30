/*									tab:4
 * @(#)CORYHALL.c
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
 * Authors:		Alec Woo, Robert Szewczyk, Su Ping
 *
 *
 * This is the initial temperature/light monitoring application for Cory
 * Hall.  The application performs several functions:
 *  - it establishes a multihop routing tree based on beacons from the base
 *  station 
 *  - it periodically reports light and temperature readings. These are
 *  packaged in "snowball" packets -- as the packet passes through the
 *  network, it accumulates the readings along the way.
 *  - it records the strenght of signal in the neighborhood. This can be used
 *  for either monitoring the network connectivity, or for computing location
 *  of other nodes in the network, e.g. badges.
 *
 * WHILE THIS IS A REASONABLE EXAMPLE OF A WORKING APPLICATION, PLEASE DO NOT
 * USE THIS AS AN EXAMPLE OF DESIGN. 
 *
 */
module DemoCoryhallM 
{

  provides interface StdControl ;

  uses {
    interface Leds;
    interface Clock;
    interface StdControl as CommControl;
    interface SendMsg as SendReportSig;
    interface SendMsg as SendRouteUpdate;
    interface SendMsg as SendLightTemp;
    interface ReceiveMsg as ReceiveRouteUpdate;
    interface ReceiveMsg as ReceiveLightTemp;
    interface ReceiveMsg as ReceiveReportSig;
    interface ReceiveMsg as ReceiveSignalMsg;
    interface ADC as TempADC;
    interface ADC as PhotoADC;
    interface StdControl as ADCControl;
  }
}

implementation {


enum {
  NUM_HOPS= 8,
  NUM_SIG_UNITS=7,
  NUM_LT_UNIT = 5, 
  LIGHTTEMP_SENDRATE=15 // change this to change send rate (15 is 30 seconds)
};

typedef struct {
    uint16_t strength;
    uint16_t signalID;
}sigStrength; // size is 4 bytes.  We can fit 7 units in a packet

typedef struct {
    int16_t source;
    sigStrength readings[NUM_SIG_UNITS];
} signalStrengthPacket;

typedef struct{
    int8_t index;
    int16_t route[NUM_HOPS];
}routePacket;

typedef struct{
    int16_t id;
    int8_t data[3];
    uint8_t seqno;
}lightTempElemt;

typedef struct{
    lightTempElemt data[NUM_LT_UNIT];
}lightTemp;

    TOS_Msg recv_buf;
    TOS_Msg data_buf;
    TOS_Msg lightTemp_buf;
    TOS_MsgPtr msgPtr;
    int16_t route;
    int8_t set;
    int8_t level;
    int8_t data_buf_size;
    sigStrength *ssptr;
    int8_t data_send_pending;
    int8_t msg_send_pending;
    lightTemp * ltptr;
    int light;
    int lightPrev;
    int tempPrev;
    int8_t sendRate;
    uint8_t seqno;


command result_t StdControl.init(){
    //initialize sub components
    int8_t i;
    //TOS_CALL_COMMAND(CORYHALL_SUB_INIT)();
    msgPtr = &recv_buf;
    data_send_pending = 0;
    msg_send_pending = 0;
    ssptr = ((signalStrengthPacket*)(&data_buf.data[0]))->readings;
    ((signalStrengthPacket*)(&data_buf.data[0]))->source = TOS_LOCAL_ADDRESS; 
    data_buf_size = 0;
    ltptr = (lightTemp *) &(lightTemp_buf.data[0]);
    for (i = 0; i < NUM_LT_UNIT; i ++) {
	ltptr->data[i].id = TOS_BCAST_ADDR;
    }
    sendRate = LIGHTTEMP_SENDRATE;
    seqno = 0;
    route = 0;
    set = 0;
    level = 100;
    call ADCControl.init();
    call CommControl.init();
    call Clock.setRate(255, 0x06);
    call Leds.yellowOn();
    return SUCCESS;
}

command result_t StdControl.start() {
    return SUCCESS;
}

command result_t StdControl.stop() {
    return SUCCESS;
} 

// event handler when receiving SIGNAL_MSG typed msg
/* Store into buffer */
event TOS_MsgPtr ReceiveSignalMsg.receive(TOS_MsgPtr pmsg) {
    signalStrengthPacket *packet = (signalStrengthPacket *)pmsg->data;
    call Leds.greenToggle();
    if (data_buf_size < NUM_SIG_UNITS){
	ssptr[(int)data_buf_size].strength = pmsg->strength;
	ssptr[(int)data_buf_size].signalID = packet->source;
	data_buf_size++;
    }
    return pmsg;
}

event TOS_MsgPtr ReceiveLightTemp.receive(TOS_MsgPtr pmsg){
    int16_t i, Index = 0;
    TOS_MsgPtr tmp;

    lightTemp * msgltptr = (lightTemp *) pmsg->data;
    if (route != 0){
	while(Index < NUM_LT_UNIT) {
	    if (msgltptr->data[Index].id == TOS_BCAST_ADDR) 
		break;
	    Index++;
	}
	if (Index < NUM_LT_UNIT){
	    for (i=0; i < sizeof(lightTempElemt); i++){
		((int8_t *)&(msgltptr->data[Index]))[i] = ((int8_t *)&(ltptr->data[0]))[i];
	    }
	}
	if (msg_send_pending == 0){
	    call Leds.greenToggle();
	    msg_send_pending = call SendLightTemp.send(route, 30,  pmsg);
	    tmp = msgPtr;
	    msgPtr = pmsg;
	    if (msg_send_pending != 0){
		sendRate = LIGHTTEMP_SENDRATE;
		return tmp;
	    }
	}
    }
    return pmsg;
}

event TOS_MsgPtr ReceiveReportSig.receive(TOS_MsgPtr pmsg){
    TOS_MsgPtr tmp;
    if (msg_send_pending == 0 && route != 0){
	msg_send_pending = call SendReportSig.send(route, 30,pmsg);
	tmp = msgPtr;
	msgPtr = pmsg;
	return tmp;
    }

    return pmsg;
}

// clock event handler 
event result_t Clock.fire() {

    if (set !=0) set--;

    // for the rest of the time, if there are location information, I send it out
    if (data_send_pending == 0 && route != 0 && sendRate != 0){
	if(data_buf_size != 0){      
	    data_send_pending = call SendReportSig.send(route, 30, &data_buf); 
	    data_buf_size = 0;
	}
    } 
    call PhotoADC.getData();
    call Leds.redToggle();

    return SUCCESS;
}


event TOS_MsgPtr ReceiveRouteUpdate.receive(TOS_MsgPtr pmsg){
    TOS_MsgPtr tmp;
    routePacket * rpptr = (routePacket *) pmsg->data;

    if (rpptr->index < NUM_HOPS){
	if (set == 0 || (rpptr->index < level-1)){
	    route = rpptr->route[(int)(rpptr->index)];
	    set = 4; // Expires route every 8 seconds
	    call Leds.yellowOff();
	    rpptr->index++;
	    level = rpptr->index;
	    if (level < NUM_HOPS){
		rpptr->route[(int)level] = TOS_LOCAL_ADDRESS;
		if (msg_send_pending == 0){
		    msg_send_pending = call SendRouteUpdate.send(TOS_BCAST_ADDR, 30,  pmsg);
		    tmp = msgPtr;
		    msgPtr = pmsg;
		    return tmp;
		}
	    }else{
		return pmsg;
	    }
	}
    }
    return pmsg;  
}


result_t send_done(TOS_MsgPtr data){
    int i;
    if(data == msgPtr){ 
	msg_send_pending = 0;
    }
    if(data == &data_buf) {
	data_send_pending = 0;
	for (i = 0; i < NUM_SIG_UNITS; i++) {
	    ssptr[i].signalID = TOS_BCAST_ADDR;
	}
    }
    if (data == &lightTemp_buf){
	data_send_pending = 0;
    }

    // ok route_buf_send_pending == 0
    // but pointer is route_buf, why is that?
    // ok route
    //if (VAR(data_send_pending) != 0)
    //    TOS_CALL_COMMAND(CORYHALL_LED3_TOGGLE)();

    return 1;
}

event result_t SendRouteUpdate.sendDone(TOS_MsgPtr data, result_t x) {
    return send_done(data);
}
event result_t SendReportSig.sendDone(TOS_MsgPtr data, result_t x) {
    return send_done(data);
}

event result_t SendLightTemp.sendDone(TOS_MsgPtr data, result_t x) {
    return send_done(data);
}

event result_t TempADC.dataReady(uint16_t data) {
    light = data;
    // read temperature 
    call TempADC.getData();   
    return SUCCESS;
}

event result_t PhotoADC.dataReady(uint16_t data ) {

    if (sendRate != 0) 
	sendRate--;

    ltptr->data[0].id = TOS_LOCAL_ADDRESS;
    ltptr->data[0].data[0] = (data & 0xff);
    ltptr->data[0].data[1] = (data >> 4) & 0x30;
    ltptr->data[0].data[1] |= (light >> 8) & 0x03;
    ltptr->data[0].data[2] = (light & 0xff);
    if (seqno != 255)
	ltptr->data[0].seqno = seqno++;
    else
	seqno = 0;

    if ((light - lightPrev) > 50 ||
	(lightPrev - light)> 50 ||
	(data - tempPrev) > 10 ||
	(tempPrev - data)> 10 ||
	sendRate == 0){
	sendRate = LIGHTTEMP_SENDRATE; 
	if (data_send_pending == 0){
	    data_send_pending = call SendLightTemp.send(route, 30, &lightTemp_buf);
	}
    }
    lightPrev = light;
    tempPrev = data;

    return 1;
}
} // end of implementation

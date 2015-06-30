/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti, Janos Sallai
 * Date last modified: 08/26/03
 */
 
/* VIJAI: Changed "rval" in FloodRouting.receive(...) to 16 bits from 8 bits. */

includes Timer;
includes TimeSlotNegotiation;

module AcousticLocalizationM
{
	provides 
	{
		interface StdControl;
		interface IntCommand;		
	}
	uses
	{
#ifdef WITH_XNP
		interface Xnp;
#endif
		interface Timer;
		interface Leds;

		interface StdControl as TimeSlotNegotiationControl;
		interface TimeSlotNegotiation;
		interface AcousticRangingActuator;
		interface AcousticRangingSensor;

		interface FloodRouting;
	}
}

implementation
{
#define	TIMESLOT_LENGTH  5
#define	CHIRP_OFFSET  2	  // chirp in the middle of the time slot

	typedef struct {
		uint16_t actuator;
		uint16_t sensor;
		int16_t distance;
	} data_token;

	enum {
		IDLE,
		RANGING
	};

	uint8_t routingBuffer[100];
	uint8_t state;
	int16_t ticks;
	bool SEND_ALL_RESULTS;
		
	command result_t StdControl.init() 
	{
#ifdef WITH_XNP		
		call Xnp.NPX_SET_IDS();			   //set mote_id and group_id */
#endif
		SEND_ALL_RESULTS = TRUE;
		return SUCCESS; 
	}

	command result_t StdControl.start() 
	{ 
		state = IDLE;
		call FloodRouting.init(6, 6, routingBuffer, sizeof(routingBuffer));
		return SUCCESS; 
	}

	command result_t StdControl.stop() 
	{
		call TimeSlotNegotiationControl.stop();
		call Timer.stop();
		state = IDLE;
		return SUCCESS;
	}

	event void AcousticRangingActuator.sendDone()
	{
		call Leds.redOff();
	}

	event result_t AcousticRangingSensor.receive(uint16_t actuator)
	{
		call Leds.greenOn();
		return SUCCESS;
	}

	event void AcousticRangingSensor.receiveDone(uint16_t actuator, int16_t distance)
	{
		data_token token;

		if(SEND_ALL_RESULTS || distance>=0) {   
			token.actuator = actuator;
			token.sensor = TOS_LOCAL_ADDRESS;
			token.distance = distance;

			call FloodRouting.send(&token);
		}
		
		call Leds.greenOff();

	}

	event result_t Timer.fired() {

		call Leds.yellowToggle();
		
		if(ticks == call TimeSlotNegotiation.getTimeSlot() * TIMESLOT_LENGTH + CHIRP_OFFSET) {
			if( call AcousticRangingActuator.send() == SUCCESS )
			{
				call Leds.redOn();
			}
		}
		
		if(ticks == call TimeSlotNegotiation.getTimeSlotCount() * TIMESLOT_LENGTH) {
			call Timer.stop();
			call Leds.set(0);
			state = IDLE;
			call TimeSlotNegotiationControl.start();
		}
		
		ticks++;

		return SUCCESS;
	}
   
	event result_t FloodRouting.receive(void *data){
		return SUCCESS;
	}

	command void IntCommand.execute(uint16_t param) {
		uint16_t rval = FAIL;
		if (state == IDLE && param == 1) {
			if(call TimeSlotNegotiation.isNegotiating()) call TimeSlotNegotiationControl.stop();
		
			ticks = 0;
			call Timer.start(TIMER_REPEAT, 1000);
  
			state = RANGING;
			rval = SUCCESS;
		}
		
		if (state == RANGING && param == 0) {
			call Timer.stop();
			call Leds.set(0);
			state = IDLE;
			rval = SUCCESS;
		}

		if (param == 2) {
			SEND_ALL_RESULTS = FALSE;
			rval = SUCCESS;
		}

		if (param == 3) {
			SEND_ALL_RESULTS = TRUE;
			rval = SUCCESS;
		}

		signal IntCommand.ack(rval);
	}
#ifdef WITH_XNP
	event result_t Xnp.NPX_DOWNLOAD_REQ(uint16_t wProgramID, uint16_t wEEStartP, uint16_t wEENofP){
  		//Acknowledge NPX
  		call StdControl.stop();
		call Leds.redOn();
		call Xnp.NPX_DOWNLOAD_ACK(SUCCESS);
  		return SUCCESS;
	}
  
	event result_t Xnp.NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet,uint16_t wEENofP){
		return SUCCESS;
	}	
#endif
}

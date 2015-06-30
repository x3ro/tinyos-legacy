/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified 11/21/05
 */

includes RipsPhaseOffset;
includes RipsDataStore;
includes RipsDataCollection;
includes RipsOneHop;

module RipsOneHopM
{
        provides 
        {
		    interface StdControl;
            interface DataCommand as StartMeasurementCommand;
        }

        uses
        {
            interface StdControl as SubControl;
            interface Leds;
            interface Timer;
            interface RSSILogger;
            interface RipsDataStore;
            interface RipsPhaseOffset;
            interface FloodRouting;
    }
}

implementation
{
    struct StartCommand{
        uint8_t seqNum;
        uint16_t assistID;
    };

    enum{
        STATE_READY = 0,
        STATE_BUSY = 1,
        STATE_SENDING = 2,
        STATE_STOPPED = 4,
    };

    norace uint8_t state;
    uint16_t assistID, seqNumber;
    uint8_t *routingBuffer;

    command void StartMeasurementCommand.execute(void *data, uint8_t length){
        
        if (state != STATE_READY)
            return;
        state = STATE_BUSY;

        seqNumber  = ((struct StartCommand *)data)->seqNum;
        assistID = ((struct StartCommand *)data)->assistID;
        if (!call Timer.start(TIMER_ONE_SHOT, 500)){ //wait until the radio comm caused by remote ctl dies
            state = STATE_READY;
        }
    } 

    event result_t Timer.fired(){
        if (!call RipsPhaseOffset.startRanging(seqNumber, assistID))
            state = STATE_READY;

        return FAIL;
    }

    event void RipsPhaseOffset.measurementStarted(uint8_t seqNum, uint16_t master, uint16_t assistant){
        //we currently don't enforce the radio silence around
        seqNumber = seqNum;
    }

    async event void RipsPhaseOffset.measurementEnded(result_t result){
        state = STATE_READY;
    }

    
    norace void *dataBuffer;
    norace uint8_t bufferIdx;
    norace uint8_t bufferLength;

#define PERIOD_MIN_LIMIT 800L/*50Hz*/
#define PERIOD_MAX_LIMIT 16368L/*1023Hz*/
    task void sendData(){
        uint8_t i, j;

        // (1) parsing of the data buffer -> can use this code as a feed into routing algorithm
        //* 
        struct RoutingPacket packet;
        packet.seqNumber = seqNumber;
        packet.slaveID = TOS_LOCAL_ADDRESS;
        
        i=0;
        while ( i < NUM_MEASUREMENTS && 
                bufferIdx <= bufferLength - sizeof(struct RipsPacket) )
        {
            struct RipsPacket *minMaxPacket = (struct RipsPacket *)(dataBuffer+bufferIdx);
            uint16_t period = minMaxPacket->period;

            if (period >= PERIOD_MAX_LIMIT)
                period = PERIOD_MAX_LIMIT-1;
            else if (period < PERIOD_MIN_LIMIT)
                period = PERIOD_MIN_LIMIT;

            packet.measurements[i].period = ( ((uint16_t)bufferIdx) / sizeof(struct RipsPacket) << 10) | (period+8)>>4;
            packet.measurements[i].phaseOffset = minMaxPacket->phase;
            ++i;
            bufferIdx += sizeof(struct RipsPacket);
        }

        for (j=i; j<NUM_MEASUREMENTS; j++)
            packet.measurements[j].period = 0;

        call FloodRouting.send(&packet);

        if ( bufferIdx <= bufferLength - sizeof(struct RipsPacket) )
            post sendData();
 
        //*/
        
        // (2) just broadcasting the whole buffer one hop, use net.tinyos.mcenter.BigMSGDisplay to receive it in java
        //call RSSILogger.report();
    }
    event result_t FloodRouting.receive(void *data){
        return SUCCESS;
    }
	event void RSSILogger.reportDone() 
	{
	}

    async event void RipsPhaseOffset.reportPhaseOffsets(void *buffer, uint16_t length){
        if (buffer != 0 && length > 0){
            dataBuffer = buffer;
            bufferIdx = 0;
            bufferLength = length;

            post sendData();
            state = STATE_READY;
        }
    }

    command result_t StdControl.init()
    {
        routingBuffer = call RipsDataStore.getRoutingBuffer();
        call Leds.init();
        call SubControl.init();
        
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        call SubControl.stop();
        state = STATE_STOPPED;
        return SUCCESS;
    }

    command result_t StdControl.start()
    {
        call SubControl.start();
        call FloodRouting.init(sizeof(struct RoutingPacket), ROUTING_UNIQUE_SIZE, routingBuffer, call RipsDataStore.getRoutingBufferSize());
        state = STATE_READY;

        return SUCCESS;
    }
}

/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

#define MAC_ADDR_LOCATION         0xFDB6
#include "mc13192Const.h"
#include "timerconversiontest.h"

module mc13192Ieee802154M {
	provides {
		interface StdControl;
		interface IeeeRadioControl as Control;
		interface IeeeRadioSend as Send;
		interface IeeeRadioRecv as Recv;
		interface IeeeRadioCCA as CCA;
		interface IeeeRadioEvents as Events;
	}
	uses {
		interface mc13192Send as RadioSend;
		interface mc13192Receive as RadioRecv;
		interface mc13192StreamEvents as RadioEvents;
		interface mc13192CCA as RadioCCA;
		interface mc13192Control as RadioControl;
		interface mc13192TimerCounter as Time;
		interface LocalTime;
		interface Debug;
		//interface AsyncAlarm<uint32_t> as Timer;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	uint8_t *radioMACAddr = (uint8_t*)MAC_ADDR_LOCATION;

	command result_t StdControl.init()
	{
		// Set the MAC address of the device.
		memcpy(aExtendedAddress,radioMACAddr,8);
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call RadioControl.setTimerPrescale(5);
		return SUCCESS;	
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;	
	}

	// Energy detection..

	command result_t CCA.energyDetect()
	{
		signal Recv.start();
		call RadioRecv.disableReceiver();
		return call RadioCCA.energyDetect();
	}
	
	command result_t CCA.clearChannelAssessment()
	{
		signal Recv.start();
		call RadioRecv.disableReceiver();
		return call RadioCCA.clearChannelAssessment(0x96); // The value Freescale uses.
	}
	
	default async event void CCA.energyDetectDone(uint8_t power) {}
	default async event void CCA.clearChannelAssessmentDone(bool isClear) {}

	// Radio control.

	command result_t Control.setChannel(uint8_t channel)
	{
		return call RadioControl.setChannel(channel);
	}
	
	command result_t Control.enableReceiver()
	{
		// Wait while the receiver is enabled..
		// 144 us for MC13192.
		//call Timer.armCountdown(300);
		result_t res = call RadioRecv.enableReceiver(0);
		atomic {
		test_lt1 = call LocalTime.getTimeL();
		test_rt1 = call Time.getTimerCounter();
		}
		return res;
	}
	
	command result_t Control.enableTransmitter()
	{
		// Disable receiver if it was on!
		call RadioRecv.disableReceiver();
		//call Timer.armCountdown(300);
		return SUCCESS;
	}
	
	command result_t Control.disableTransceiver()
	{
		// Try to disable the receiver if it was on!
		call RadioRecv.disableReceiver();
		//call Timer.armCountdown(300);
		return SUCCESS;
	}
	
/*	async event result_t Timer.alarm()
	{
		signal Control.stateChangeDone();
	}*/
	
//	default async event void Control.stateChangeDone() {}
	
	default event result_t Control.resetIndication() {}

	command result_t Recv.initRxQueue(uint8_t *packetBuf)
	{
		return call RadioRecv.initRxQueue(packetBuf);
	}
	
	default async event uint8_t* Recv.dataReady(PdIndication_t *data, bool crc)
	{
		return data->psdu;
	}

	command result_t Send.send(PdMessageRequestData_t *data)
	{
		if (data->deferred) {
			uint32_t tmp = call LocalTime.timeDiff(call LocalTime.getTimeL(), data->commenceTime);
			tmp >>= 4;
			call Time.resetTimerCounter();
			return call RadioSend.send(data->psdu, data->psduLength, tmp);
		} else {
			return call RadioSend.send(data->psdu, data->psduLength, 0);
		}
	}
	
	default async event void Send.sendDone(uint8_t *packet, result_t status) {}


	// Handle radio events.
	async event void RadioCCA.energyDetectDone(uint8_t power)
	{
		signal Recv.stop();
		call RadioRecv.enableReceiver(0);
		signal CCA.energyDetectDone(power);
	}
	
	async event void RadioCCA.clearChannelAssessmentDone(bool isClear)
	{
		signal Recv.stop();
		call RadioRecv.enableReceiver(0);
		signal CCA.clearChannelAssessmentDone(isClear);
	}
	
	event result_t RadioControl.resetIndication()
	{
		return signal Control.resetIndication();
	}
	
	async event uint8_t* RadioRecv.dataReady(uint8_t *packet, uint8_t length, bool crc, uint8_t lqi)
	{
		PdIndication_t radioData;
		
		radioData.psduLength = length;
		radioData.psdu = packet;
		radioData.pdduLinkQuality = lqi;
		radioData.commenceRadio = call RadioControl.getRXTimestamp();
		commence_r = radioData.commenceRadio;
		radioData.nowLocal = call LocalTime.getTimeL();
		radioData.nowRadio = call Time.getTimerCounter();
		test_rt2 = radioData.nowRadio;
		test_lt2 = radioData.nowLocal;

		return signal Recv.dataReady(&radioData, crc);
	}
	
	event void RadioRecv.timeout(uint8_t *packet) {}
	
	async event void RadioSend.sendDone(uint8_t *packet, result_t status)
	{
		signal Send.sendDone(packet, status);
	}
	
	async event void RadioEvents.rxStart()
	{
		signal Recv.start();
	}
	
	async event void RadioEvents.rxEnd()
	{
		signal Recv.stop();
	}
	
	async event void RadioEvents.txStart()
	{
		signal Send.start();
	}
	
	async event void RadioEvents.txEnd()
	{
		signal Send.stop();
	}
	
	async event void RadioEvents.opDone()
	{
		signal Events.radioOperationDone();
	}
	
}

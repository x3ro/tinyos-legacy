#include "PhyTypes.h"

module TestRadioDriverM
{
	provides {
		interface StdControl;
	}
	uses {
		interface PhyTransmit;
		interface PhyReceive;
		interface PhyAttributes;
		interface PhyEnergyDetect;
		interface LocalTime;
		interface Timer;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#define DBG_MIN_LEVEL 0
	#include "Debug.h"
	
	uint8_t myTestFrame[19] = {0x23, 0x8C, 0x12, 0xDE, 0xFE, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0xFF, 0xFF, 0x1F, 0x00, 0x01, 0x80};
//	uint8_t myTestFrame[125];
	uint8_t myTestFrameLength = 19;
	
	uint8_t rxBuf[126]; // Initial receive buffer.
 
 	txdata_t txBuf;
 
	task void receive();
	task void send();
	task void energy();
	
	/* **********************************************************************
	 * Setup/Init code
	 * *********************************************************************/

	/* Init */
	command result_t StdControl.init()
	{
		call PhyReceive.initRxBuffer(rxBuf);
		return SUCCESS;
	}

	/* start */
	command result_t StdControl.start()
	{
		uint8_t i;
		call PhyAttributes.setChannel(0);

		txBuf.frame = myTestFrame;
		txBuf.length = myTestFrameLength;
		txBuf.cca = TRUE;
		txBuf.immediateCommence = TRUE;
		txBuf.commenceTime = 0x0000FFFF;

		post energy();
		//call Timer.start(TIMER_ONE_SHOT, 1000);
		return SUCCESS;
	}

	/* stop - never called */
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	/* **********************************************************************
	 * Timer/radio related code
	 * *********************************************************************/

	task void send()
	{
		call PhyTransmit.tx(&txBuf);
	}

/*	task void sendCca()
	{
		call PhyDriver.ccaSend(&txBuf, TRUE);
	}*/
	
	task void receive()
	{
/*		uint32_t test1,test2;
		uint32_t i = 0x2FFFFF;

		call PhyDriver.resetEventTime();
		call LocalTime.reset();
		test1 = call PhyDriver.getEventTime();
		test2 = call LocalTime.getTimeL();

		DBG_STRINT("Time1:",test1,1);
		DBG_STRINT("Time2:",test2,1);
		while(i--);
		
		test2 = call LocalTime.getTimeL();
		test1 = call PhyDriver.getEventTime();

		DBG_STRINT("Time1:",test1,1);
		DBG_STRINT("Time2:",test2,1);*/
		call PhyAttributes.setDefaultFilter();
		call PhyReceive.rxOn(0,TRUE);
	}

	task void energy()
	{
		call PhyEnergyDetect.ed();
	}

	async event void PhyEnergyDetect.edDone(phy_error_t error, uint8_t energy)
	{
		DBG_STRINT("Energy detection done. Power was:",energy,1);
	}
	
	async event void PhyTransmit.txDone(phy_error_t error)
	{
		if (error == PHY_SUCCESS) {
			DBG_STR("Transmission completed!",1);
		} else if (error == PHY_CCA_FAIL) {
			DBG_STR("Transmission failed. Channel was busy.",1);
		} else if (error == PHY_ACK_FAIL) {
			DBG_STR("Transmission failed. No ACK was received.",1);
		}
	}
	
	async event uint8_t *PhyReceive.dataReady(rxdata_t *rxPacket)
	{
		DBG_STR("Packet received",1);
		DBG_DUMP(rxPacket->frame, rxPacket->length,1);
		return rxPacket->frame;
	}

	/* We transmit a packet each time the timer fires */
	event result_t Timer.fired()
	{
		return SUCCESS;
	}
}

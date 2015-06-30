
module RadioTestM
{
	provides interface StdControl;
	uses 
	{
		interface StdControl as Radio;

		interface PhyComm;
		interface RadioState;

		interface Leds;
		interface UARTDebug as Debug;
	}
}

implementation
{
#include "TMACEvents.h"
#include "TMACMsg.h"

	void sendRadio();
	char *testbytes = "\x0a\x0a\x02\x00\x01\x01\x5f\x02\x35\x96";

	int8_t counter=0;
	uint32_t packets=0;
	uint16_t sleeptime=0;
	enum {Red=1,Green=2,Yellow=4};

	command result_t StdControl.init()
	{
		counter = 0;
		packets = 0;
		call Debug.init(7);
		call Debug.txState(RADIO_TEST_INIT);
		call Radio.init();

		call Leds.init();
		call Debug.txStatus(_LED_SET,Red);
		return call Leds.redOn();
	}

	command result_t StdControl.start()
	{
		call Debug.txStatus(_LED_UNSET,Yellow);
		call Leds.yellowOff();
		call Debug.setFlags(7|8);

		call Radio.start();
		call RadioState.idle();

		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		counter = -1;
		call Debug.txStatus(_LED_UNSET,Red);
		call Leds.redOff();
		call Radio.stop();

		return SUCCESS;
	}

	event result_t PhyComm.startSymDetected(void *packet) {return SUCCESS;}
	
	event void* PhyComm.rxPktDone(uint8_t* packet, uint16_t error, uint16_t rssi)
	{
		PhyHeader *mac = (PhyHeader*)packet;
		uint8_t len = mac->length,i;
		call Debug.tx16status(__RADIO_TEST_RECV,0xFFFF);
		for (i=0;i<len+1;i++)
		{
			call Debug.tx16status(__RADIO_TEST_RECV,packet[i]);
		}
		call Leds.yellowToggle();
		return packet;
	}

	event result_t PhyComm.txPktDone(uint8_t *packet)
	{
		return SUCCESS;
	}
}


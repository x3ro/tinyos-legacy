
module RadioTestM
{
	provides interface StdControl;
	uses 
	{
		interface StdControl as Radio;

		interface RadioSPI;
		interface ClockMS as Clock;
		interface StdControl as ClockControl;

		interface Leds;
		interface UARTDebug as Debug;
	}
}

implementation
{
#include "TMACEvents.h"

	uint16_t counter=0;
	uint16_t packets=0;

	command result_t StdControl.init()
	{
		counter = 0;
		call Debug.init(7);
		call Debug.txState(RADIO_TEST_INIT);
		call RadioSPI.init();

		call Leds.init();
		call ClockControl.init();
		return call Leds.redOn();
	}

	command result_t StdControl.start()
	{
		call ClockControl.start();
		call RadioSPI.idle();

		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		counter = -1;
		call Leds.redOff();

		return SUCCESS;
	}


	event result_t RadioSPI.dataReady(uint8_t byte, bool valid)
	{
		atomic counter++;
		return SUCCESS;
	}


	event void Clock.fire(uint16_t ms)
	{
		atomic packets+=ms;
		if (packets == 1024)
		{
			uint16_t tosend;
			packets = 0;
			atomic {
				tosend = counter;
				counter = 0;
			}
			call Debug.tx16status(__RADIO_TEST_RECV,tosend);
			dbg(DBG_ERROR,"Bandwidth = %.3f\n",tosend/125.0);
		}
	}

	event result_t RadioSPI.xmitReady()
	{
		return SUCCESS;
	}
}


module TestLedsM
{
	provides interface StdControl;

	uses
	{
		interface Leds;
		interface Timer;
	}
}

implementation
{
	typedef enum {RED_LED=1,YELLOW_LED,GREEN_LED,WAIT_1,WAIT_2,RESET} LedState;

	LedState state;
	
	command result_t StdControl.init()
	{
		call Leds.init();
		state = RED_LED;
		call Leds.redOn();
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		return call Timer.start(TIMER_REPEAT, 1000);
	}

	command result_t StdControl.stop()
	{
		return call Timer.stop();
	}

	event result_t Timer.fired()
	{
		state++;
		switch(state)
		{
			case YELLOW_LED:
				call Leds.redOff();
				call Leds.yellowOn();
				break;

			case GREEN_LED:
				call Leds.yellowOff();
				call Leds.greenOn();
				break;

			case WAIT_1:
				call Leds.greenOff();
			case WAIT_2:
				break;

			case RESET:
				state = RED_LED;
				call Leds.redOn();
				break;
			
			case RED_LED: // shouldn't occur
				break;
		}
		return SUCCESS;
	}
}

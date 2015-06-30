/*
	HPLKBI implementation for HCS08
	
	Author:			Jacob Munk-Stander <jacobms@diku.dk>
	Modified:	May 24, 2005

	Last modified:	July 6, 2006, marcus@diku.dk
*/
module HPLKBIM
{
	provides interface HPLKBI as KBI;
	uses interface Timer;
}

implementation
{

	uint8_t sw = 0x00;

	command result_t KBI.init()
	{
		atomic
		{
		      TOSH_MAKE_GIO9_INPUT();
		      TOSH_MAKE_GIO10_INPUT();
		}

		call Timer.start(TIMER_REPEAT, 100);

		return SUCCESS;
	}
	
  
	event result_t Timer.fired()
 	{

		uint8_t i = 0;
	
		if (TOSH_READ_GIO10_PIN() == 0x80)
			i |= 0x01;
		
		if (TOSH_READ_GIO9_PIN() == 0x01)
			i |= 0x02;

		if (i != sw) {
			sw = i;
			signal KBI.switchDown(i);
		}

		return SUCCESS;
	}
}

#include <mac.h>
module TestTimerCorrelationM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface mc13192Control as RadioControl; 
		interface mc13192TimerCounter as RadioTime;
		interface LocalTime;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	task void timerTest();
	command result_t StdControl.init()
	{
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		post timerTest();
		call RadioControl.setTimerPrescale(5);
		call RadioTime.resetTimerCounter();
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
	
	task void timerTest()
	{
		uint32_t i;
		time_t rt1,rt2,lt1,lt2;
		
		atomic  {
			rt1 = call RadioTime.getTimerCounter();
			lt1 = call LocalTime.getTimeL();
		}
		for (i = 0; i < 150000 ; i++ ){};
		atomic {
			rt2 = call RadioTime.getTimerCounter();
			lt2 = call LocalTime.getTimeL();
		}
		DBG_INT_CLEAN(rt1,1);
		DBG_STR_CLEAN(", ",1);
		DBG_INT_CLEAN(rt2,1);
		DBG_STR_CLEAN(", ",1);
		DBG_INT_CLEAN(lt1,1);
		DBG_STR_CLEAN(", ",1);
		DBG_INT_CLEAN(lt2,1);
		DBG_STR_CLEAN("\n",1);
		
		post timerTest();
	}
	
	event result_t RadioControl.resetIndication()
	{
		return SUCCESS;
	}
	
}

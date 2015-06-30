#include <mac.h>
module TestTimeM
{
	provides
	{
		interface TestTime;
	}
	uses
	{
		interface LocalTime as myTime;
		interface AsyncAlarm<time_t> as myAlarm;
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	time_t nextAlarm;	
	uint8_t hour, min, sec;
	
	command void TestTime.start()
	{
		nextAlarm = call myTime.getTimeL()+1000000;
		hour = min = sec = 0;
		call myAlarm.armAlarmClock(nextAlarm);
	}
	
	async event result_t myAlarm.alarm()
	{
		nextAlarm += 1000000;
		sec++;
		min += sec/60;
		hour += min/60;
		sec %= 60;
		min %= 60;
		
		DBG_INT_CLEAN(hour,1);
		DBG_STR_CLEAN(":",1);
		DBG_INT_CLEAN(min,1);
		DBG_STR_CLEAN(":",1);
		DBG_INT_CLEAN(sec,1);
		DBG_STR_CLEAN("\n",1);		
		return call myAlarm.armAlarmClock(nextAlarm);
	}
}

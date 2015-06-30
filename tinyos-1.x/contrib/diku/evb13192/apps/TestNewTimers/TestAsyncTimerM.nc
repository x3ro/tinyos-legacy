
module TestAsyncTimerM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface AsyncAlarm<uint32_t> as Alarm1;
		interface AsyncAlarm<uint32_t> as Alarm2;
		interface LocalTime;
		interface ConsoleOutput as ConsoleOut;
	}
}
implementation
{
	uint32_t time1, time2;
	uint32_t waitInterval = 10;
	
	void startTime();

	command result_t StdControl.init()
	{;
		return SUCCESS;
	}
	
	command result_t StdControl.start()
	{
		startTime();
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
	
	async event result_t Alarm1.alarm()
	{
		time2 = call LocalTime.getTimeL() - time1;
		call ConsoleOut.print("0x");
		call ConsoleOut.printHexlong(time2);
		call ConsoleOut.print("\n");
		waitInterval++;
		startTime();
		return SUCCESS;
	}
	
	void startTime()
	{
		time1 = call LocalTime.getTimeL();
		call Alarm1.armCountdown(waitInterval);
	}
	
	async event result_t Alarm2.alarm()
	{
		return SUCCESS;
	}

}

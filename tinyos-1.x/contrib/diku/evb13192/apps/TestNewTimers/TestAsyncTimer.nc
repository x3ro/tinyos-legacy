//#define LEDS_TO_UART

configuration TestAsyncTimer
{

}

implementation
{
	components AsyncAlarmC,
	           Main,
	           ConsoleC,
	           LocalTimeM,
	           TestAsyncTimerM;

	Main.StdControl -> AsyncAlarmC.StdControl;
	Main.StdControl -> ConsoleC.StdControl;
	Main.StdControl -> TestAsyncTimerM.StdControl;
	
	TestAsyncTimerM.ConsoleOut -> ConsoleC.ConsoleOut;
	TestAsyncTimerM.LocalTime -> LocalTimeM.LocalTime;
	TestAsyncTimerM.Alarm1 -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
	TestAsyncTimerM.Alarm2 -> AsyncAlarmC.Alarm[unique("AsyncAlarm")];
}

configuration TestTimerCorrelation
{
}
implementation
{
	components Main,
	           TestTimerCorrelationM,
	           RadioTimeTestC,
	           AsyncAlarmC,
	           LocalTimeM,
	           ConsoleDebugM,
	           ConsoleC,
	           LedsC,
	           HPLSPIM as mcuSPI;
	           
	// StdControl
	Main.StdControl -> mcuSPI.StdControl;
	Main.StdControl -> RadioTimeTestC;
	Main.StdControl -> ConsoleC.StdControl;

	Main.StdControl -> AsyncAlarmC;


	Main.StdControl -> TestTimerCorrelationM.StdControl;
	
	// DEBUG           
	RadioTimeTestC.ConsoleOut -> ConsoleC;
	ConsoleDebugM.ConsoleOut -> ConsoleC;
	RadioTimeTestC.Debug -> ConsoleDebugM;
	AsyncAlarmC.Debug -> ConsoleDebugM;
	TestTimerCorrelationM.Debug -> ConsoleDebugM;
	
	// app
	TestTimerCorrelationM.RadioControl -> RadioTimeTestC;
	TestTimerCorrelationM.RadioTime -> RadioTimeTestC;
	TestTimerCorrelationM.LocalTime -> LocalTimeM; 
	
	// misc
	RadioTimeTestC.SPI -> mcuSPI;
	mcuSPI.Leds -> LedsC;
}

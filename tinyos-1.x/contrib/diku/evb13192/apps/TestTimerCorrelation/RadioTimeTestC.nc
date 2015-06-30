configuration RadioTimeTestC
{
	provides
	{
		interface StdControl;
		interface mc13192Control as RadioControl; 
		interface mc13192TimerCounter as RadioTime;
	}
	uses
	{
		interface FastSPI as SPI;
		interface Debug;
		interface ConsoleOutput as ConsoleOut;
	}
}
implementation
{
	
	components mc13192ControlM as RadioControlM,
	           mc13192InterruptM as Interrupt,
	           mc13192HardwareM as Hardware,
	           mc13192TimerM as Timer,
	           mc13192TimerCounterM as TimerCounter,
	           mc13192StateM as State,
	           LedsC;
	           
	StdControl = RadioControlM.StdControl;
	StdControl = Timer.StdControl;
	RadioControl = RadioControlM;
	RadioTime = TimerCounter.Time;
	
	SPI = Hardware.SPI;
	SPI = Interrupt.SPI;
	
	// RadioControlM wiring
	RadioControlM.Interrupt -> Interrupt.Control;
	RadioControlM.Regs -> Hardware.Regs;
	RadioControlM.Timer2 -> Timer.Timer[1];
	RadioControlM.Time -> TimerCounter.Time;
	RadioControlM.State -> State.State;
	RadioControlM.Leds -> LedsC;
	RadioControlM.ConsoleOut = ConsoleOut;
	
	Timer.Regs -> Hardware.Regs;
	Timer.Interrupt -> Interrupt.Timer;
	Timer.Leds -> LedsC;
	Timer.ConsoleOut = ConsoleOut;
	
	Interrupt.State -> State.State;
	Interrupt.Debug = Debug;
	
	
	State.Regs -> Hardware.Regs;
	State.ConsoleOut = ConsoleOut;
	
	Hardware.Leds -> LedsC;
	Hardware.ConsoleOut = ConsoleOut;
	
	TimerCounter.Regs -> Hardware.Regs;
	TimerCounter.Leds -> LedsC;
	TimerCounter.ConsoleOut = ConsoleOut;
}

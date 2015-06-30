module TestSwitchM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface ConsoleOutput as ConsoleOut;
		interface HPLKBI as KBI;
		interface Leds;
	}
}

implementation
{
	norace uint8_t theSw;
	task void handleSwitch();
	
	command result_t StdControl.init()
	{
		call KBI.init();
		call Leds.init();
		
		call Leds.set(0xF);
		
		return SUCCESS;
	}
  
	command result_t StdControl.start()
	{
    	return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
	
	async event result_t KBI.switchDown(uint8_t sw)
	{
		theSw = sw;
		
		post handleSwitch();
		
		return SUCCESS;
	}
	
	task void handleSwitch()
	{
		call ConsoleOut.print("SW: ");
		call ConsoleOut.printHex(theSw);
		call ConsoleOut.print("\r\n");
		
		switch(theSw)
		{
			case 1:
				call Leds.redToggle();
				break;

			case 2:
				call Leds.greenToggle();
				break;
				
			case 3:
				call Leds.yellowToggle();
				break;
				
			case 4:
				call Leds.blueToggle();
				break;
		}				
	}
}


// @author Jan Flora <janflora@diku.dk>
// NB: The timer is not very precise for bus clock speeds not a power of 2.
module HPLTimer2M
{
	provides
	{
		interface StdControl;
		interface HPLTimer<uint16_t> as HPLTimer;
	}
}
implementation
{

	command result_t StdControl.init()
	{
		TPM2C0SC = 0x10;  // MBD: Timer 1 Channels 0 and 1
		TPM2C1SC = 0x10;  // Set for no pin out - conflicts with leds.
		TPM2C2SC = 0x10;  // MBD: Timer 1 Channels 0 and 1
		TPM2C3SC = 0x10;  // Set for no pin out - conflicts with leds.
		TPM2C4SC = 0x10;  // MBD: Timer 1 Channels 0 and 1

		return SUCCESS;
	}

	command result_t StdControl.start()
	{
/*		uint8_t clock = busClock/1000000; // Bus clock in MHz.
		uint8_t div = 16;//clock;
		uint8_t i = 0;
		
		// HW timer clicks every us.
		while (div > 1) {
			i++;
			div >>= 1;
		}
		TPM2SC = i;*/
		
		// Select the bus clock and enable overflow interrupts.
		TPM2SC_TOIE = 1;
		//TPM2SC |= 0x08;
		TPM2SC |= 0x10;
		//TPM2SC = 0x50;
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		TPM2SC &= (~0x58); //no clock, disabled
		return SUCCESS;
	}

	command uint16_t HPLTimer.getTime()
	{
		return TPM2CNT;
	}
	
	command void HPLTimer.reset()
	{
		TPM2CNT = 0;
	}

	command result_t HPLTimer.shortDelay(uint16_t delay, uint8_t channel)
	{
		if (channel == 0) {
			TPM2C0SC &= 0x7F;
			TPM2C0V = TPM2CNT+delay;
			TPM2C0SC_CH0IE = 1;
			return SUCCESS;
		} else if (channel == 1) {
			TPM2C1SC &= 0x7F;
			TPM2C1V = TPM2CNT+delay;
			TPM2C1SC_CH1IE = 1;
			return SUCCESS;		
		} else if (channel == 2) {
			TPM2C2SC &= 0x7F;
			TPM2C2V = TPM2CNT+delay;
			TPM2C2SC_CH2IE = 1;
			return SUCCESS;
		} else if (channel == 3) {
			TPM2C3SC &= 0x7F;
			TPM2C3V = TPM2CNT+delay;
			TPM2C3SC_CH3IE = 1;
			return SUCCESS;
		} else if (channel == 4) {
			TPM2C4SC &= 0x7F;
			TPM2C4V = TPM2CNT+delay;
			TPM2C4SC_CH4IE = 1;
			return SUCCESS;
		}
		return FAIL;
	}

	command result_t HPLTimer.arm(uint16_t timeStamp, uint8_t channel)
	{
		if (channel == 0) {
			TPM2C0SC &= 0x7F;
			TPM2C0V = timeStamp;
			TPM2C0SC_CH0IE = 1;
			return SUCCESS;
		} else if (channel == 1) {
			TPM2C1SC &= 0x7F;
			TPM2C1V = timeStamp;
			TPM2C1SC_CH1IE = 1;
			return SUCCESS;		
		} else if (channel == 2) {
			TPM2C2SC &= 0x7F;
			TPM2C2V = timeStamp;
			TPM2C2SC_CH2IE = 1;
			return SUCCESS;
		} else if (channel == 3) {
			TPM2C3SC &= 0x7F;
			TPM2C3V = timeStamp;
			TPM2C3SC_CH3IE = 1;
			return SUCCESS;
		} else if (channel == 4) {
			TPM2C4SC &= 0x7F;
			TPM2C4V = timeStamp;
			TPM2C4SC_CH4IE = 1;
			return SUCCESS;
		}
		return FAIL;
	}

	command result_t HPLTimer.stop(uint8_t channel)
	{
		if (channel == 0) {
			TPM2C0SC_CH0IE = 0;
			return SUCCESS;
		} else if (channel == 1) {
			TPM2C1SC_CH1IE = 0;
			return SUCCESS;		
		} else if (channel == 2) {
			TPM2C2SC_CH2IE = 0;
			return SUCCESS;
		} else if (channel == 3) {
			TPM2C3SC_CH3IE = 0;
			return SUCCESS;
		} else if (channel == 4) {
			TPM2C4SC_CH4IE = 0;
			return SUCCESS;
		}
		return FAIL;
	}

	TOSH_SIGNAL(TPM2OVF)
	{
		// Clear the interrupt flag
		TPM2SC &= 0x7F;
		signal HPLTimer.wrapped();
	}

	TOSH_SIGNAL(TPM2CH0)
	{
		// Clear the interrupt flag
		TPM2C0SC &= 0x7F;
		signal HPLTimer.fired(0);
	}

	TOSH_SIGNAL(TPM2CH1)
	{
		// Clear the interrupt flag
		TPM2C1SC &= 0x7F;
		signal HPLTimer.fired(1);
	}

	TOSH_SIGNAL(TPM2CH2)
	{
		// Clear the interrupt flag
		TPM2C2SC &= 0x7F;
		signal HPLTimer.fired(2);
	}
	
	TOSH_SIGNAL(TPM2CH3)
	{
		// Clear the interrupt flag
		TPM2C3SC &= 0x7F;
		signal HPLTimer.fired(3);
	}

	TOSH_SIGNAL(TPM2CH4)
	{
		// Clear the interrupt flag
		TPM2C4SC &= 0x7F;
		signal HPLTimer.fired(4);
	}

	default async event void HPLTimer.fired(uint8_t channel)
	{
	}

	default async event void HPLTimer.wrapped()
	{
	}
}

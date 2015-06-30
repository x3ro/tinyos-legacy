
module HPLSPIM {
	provides {
		interface FastSPI as SPI;
		interface StdControl;
	}
	uses {
		interface Leds;
	}
}
implementation
{
	command result_t StdControl.init()
	{
		call Leds.init();
		return SUCCESS;
	}
	
	command result_t StdControl.start()
	{
		// SPIC1
		// bit 7: SPI Interrupt Enable          (0)
		// bit 6: SPI System Enable             (1)
		// bit 5: SPI Transmit Interrupt Enable (0)
		// bit 4: Master/Slave Mode Select      (1 = Master)
		// bit 3: Clock Polarity                (0 = Active-high SPI clock)
		// bit 2: Clock Phase                   (0)
		// bit 1: Slave Select Output Enable    (0)
		// bit 0: LSB First                     (0 = MSB first)
	
		SPIC1 = 0x50; // Init SPI

		// SPIC2
		// bit 7-5: Reserved/Unimplemented
		// bit 4:   Master Mode-Fault Function Enable (0)
		// bit 3:   Bidirectional Mode Output Enable  (0)
		// bit 2:   Reserved/Unimplemented
		// bit 1:   SPI Stop in Wait Mode             (0)
		// bit 0:   SPI Pin Control 0                 (0)

		SPIC2 = 0x00;
	
		// SPIBR
		// bit 7:   Reserved/Unimplemented
		// bit 6-4: SPI Baud Rate Prescale Divisor (1)
		// bit 3:   Reserved/Unimplemented
		// bit 2-0: SPI Baud Rate Divisor          (2)
		SPIBR = 0x00;
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		// SPIC1
		// bit 7: SPI Interrupt Enable          (0)
		// bit 6: SPI System Enable             (0)
		// bit 5: SPI Transmit Interrupt Enable (0)
		// bit 4: Master/Slave Mode Select      (0 = Slave)
		// bit 3: Clock Polarity                (0 = Active-high SPI clock)
		// bit 2: Clock Phase                   (0)
		// bit 1: Slave Select Output Enable    (0)
		// bit 0: LSB First                     (0 = MSB first)
	
		SPIC1 = 0x00;
		return SUCCESS;
	}
	
	async command uint8_t SPI.txByte(uint8_t data)
	{
		uint8_t temp_value;
		temp_value = SPIS; // Clear status register (possible SPRF, SPTEF)
		temp_value = SPID; // Clear receive data register. SPI entirely ready for read or write
		
		while (!SPIS_SPTEF);
		SPID = data;
		while (!SPIS_SPRF);
		return SPID;
	}
}

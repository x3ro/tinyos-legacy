module TestMicro4M {
	provides {
		interface StdControl;
	}
	uses {
		interface Timer;
		interface Leds;
		interface StdOut;
		interface ThreeAxisAccel;
		interface LocalTime;
		interface Spi;
	}
}

implementation {

	///////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////
	command result_t StdControl.init() {

		call Leds.init(); 
		call Spi.init();

		return SUCCESS;
	}

	command result_t StdControl.start() {

		call StdOut.init();

		//call Leds.greenOn();
		
		call StdOut.print("Program initialized\n\r");
		
		// Start a repeating timer that fires every 1000ms
		call Timer.start(TIMER_REPEAT, 250);
		// call ThreeAxisAccel.setRange(ACCEL_RANGE_2x5G);
		// call ThreeAxisAccel.setRange(ACCEL_RANGE_3x3G);
		// call ThreeAxisAccel.setRange(ACCEL_RANGE_6x7G);
		// call ThreeAxisAccel.setRange(ACCEL_RANGE_10x0G);

		P1OUT &= ~0x40;           
		
		return SUCCESS;
	}

	command result_t StdControl.stop() {

		call Timer.stop();
		
		return SUCCESS;
	}



	///////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////
#define AVG_SIZE 10
	uint16_t x[AVG_SIZE], y[AVG_SIZE], z[AVG_SIZE];
	uint8_t avg = 0;
	task void handle_acceleration();

	event result_t ThreeAxisAccel.dataReady(uint16_t sx, uint16_t sy, uint16_t sz, uint8_t status) {

		if (status == ACCEL_STATUS_SUCCESS)
		{
			x[avg] = sx;
			y[avg] = sy;
			z[avg] = sz;

			avg++;

			if (avg == AVG_SIZE)
				avg = 0;

            post handle_acceleration();     

		} else {
			//x = status;
			//y = status;
			//z = status;
		} 

		return SUCCESS;
	}


    uint16_t min_x = 0xFFFF, max_x = 0, min_y = 0xFFFF, max_y = 0, min_z = 0xFFFF, max_z = 0;

	task void handle_acceleration() {
		uint32_t lx = 0,ly = 0,lz = 0;
		int32_t g;
		uint8_t i;

		for (i = 0; i < AVG_SIZE; i++)
		{
			lx += x[i];
			ly += y[i];
			lz += z[i];
		}

		lx /= AVG_SIZE;
		ly /= AVG_SIZE;
		lz /= AVG_SIZE;
				
		g = lx*lx + ly*ly + lz*lz;

	        call StdOut.printBase10uint32(lx);
        	call StdOut.print(" ");
	        call StdOut.printBase10uint32(ly);
        	call StdOut.print(" ");
	        call StdOut.printBase10uint32(lz);
        	call StdOut.print("\r\n");

	}

	///////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////
	uint8_t counter = 48;
	event result_t Timer.fired()
	{
//		counter++;			

		// call Leds.redToggle();
		// call Leds.greenToggle();

		// call UART.put(counter);

		// call Leds.set(counter);

		// call ExtLeds.set(counter);
		call ThreeAxisAccel.getData();
		//call AccelControl.start();

		//call StdOut.printHexlong(call LocalTime.read());
		//call StdOut.print("\r\n");
	
		return SUCCESS;
	}

	///////////////////////////////////////////////////////////////////////
	// StdOut
	///////////////////////////////////////////////////////////////////////
	uint8_t keyBuffer;
	task void consoleTask();
	
	async event result_t StdOut.get(uint8_t data) {
		
		keyBuffer = data;

		call Leds.redToggle();

		post consoleTask();

		return SUCCESS;
	}
	
	
	uint8_t buffer[256];
	uint8_t fastbuffer[256];
	uint8_t writebuffer[256];

	task void consoleTask() 
	{
		uint8_t data[] = "a";
		

		atomic data[0] = keyBuffer;

		if (data[0] == '\r') {

			call StdOut.print("\r\n");

			return;

		} else if (data[0] == '1') {

			// Start a repeating timer that fires every 250ms
			call Timer.start(TIMER_REPEAT, 250);
			return;

		} else if (data[0] == '2') {

			// Stop timer 
			call Timer.stop();
			return;

		}
		
		call StdOut.print(data);
		
		return;
	}


}



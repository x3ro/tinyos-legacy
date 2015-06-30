module TestMicro4M {
	provides {
		interface StdControl;
	}
	uses {
		interface StdOut;
		interface HPL1wire;
	}
}

implementation {

#define MAX_DEVICES 25


	/**********************************************************************
	** StdControl
	**********************************************************************/
	command result_t StdControl.init() {

		return SUCCESS;
	}

	command result_t StdControl.start() 
    {
        call StdOut.init();
        call StdOut.print("Program initialized\n\r");

		return SUCCESS;
	}

	command result_t StdControl.stop() {
		
		return SUCCESS;
	}




	/**********************************************************************
	** StdOut
	**********************************************************************/
	uint8_t keyBuffer;
	task void consoleTask();
	
	async event result_t StdOut.get(uint8_t data) {
		
		keyBuffer = data;

		post consoleTask();

		return SUCCESS;
	}

	task void consoleTask() 
	{
        b1w_reg devices[MAX_DEVICES];
        uint8_t n_devices = 0;
        uint8_t i, j, retry = 0;
		uint8_t data[2];
		
		atomic data[0] = keyBuffer;

		switch (data[0]) {
		case '\r': 
        
            for (i = 0; i < MAX_DEVICES; i++)
            {
                for (j = 0; j < 8; j++)
                {
                    devices[i][j] = 0;
                }
            }

            while(!n_devices && (retry++ < 5))
            {
                call HPL1wire.enable();
                n_devices = call HPL1wire.search(devices, MAX_DEVICES);
                call HPL1wire.disable();
            }
        

			call StdOut.print("n_devices: ");
			call StdOut.printHex(n_devices);
			call StdOut.print("\n\r");

			for (i = 0; i < n_devices; i++)
			{
				call StdOut.print("Device ");
				call StdOut.printHex(i);
				call StdOut.print(": ");
				call StdOut.dumpHex(devices[i], 8, " ");
				call StdOut.print("\r\n");
			}

			call StdOut.print("\r\n");
			break;
		
		default:
			data[1] = '\0';
			call StdOut.print(data);
			break;
		}
	}



}



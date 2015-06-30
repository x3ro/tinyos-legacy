module TestMicro4M {
	provides {
		interface StdControl;
	}
	uses {
		interface Leds;
		interface Timer;
		interface StdOut;
		interface FlashAccess;
		interface StdControl as FlashControl;
		interface BusArbitration;
        interface Spi;
	}
}

implementation {

#include "HPLSpi.h"

	///////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////
	command result_t StdControl.init() {

        call Spi.init();
		call Leds.init(); 
        call FlashControl.init();

		return SUCCESS;
	}

	command result_t StdControl.start() {

		call StdOut.init();

		call Leds.greenOn();

		// call Timer.start(TIMER_REPEAT, 250);


		call StdOut.print("Program initialized\n\r");


		return SUCCESS;
	}

	command result_t StdControl.stop() {
	
		return SUCCESS;
	}

	event result_t Timer.fired() 
	{
		call Leds.greenToggle();
		
		return SUCCESS;
	}

	///////////////////////////////////////////////////////////////////////
	// BusArbitration
	///////////////////////////////////////////////////////////////////////
	event result_t BusArbitration.busFree()
	{
		call StdOut.print("Bus released\r\n");

		return SUCCESS;
	}

	///////////////////////////////////////////////////////////////////////
	// HALSTM25P40
	///////////////////////////////////////////////////////////////////////
	uint8_t readbuffer[256];
    uint8_t writebuffer[256];

	event void FlashAccess.readReady(uint16_t page_no, void * page, uint16_t length)
	{
		uint16_t i;
		
		call StdOut.print("Read ready: ");
		call StdOut.printHexword(page_no);
		call StdOut.print("\r\n");

		// print buffer
		for (i = 0; i < length; i++) {
			call StdOut.printHex( ((uint8_t *)page)[i]);
		}

		call StdOut.print("\r\n");
	}

	event void FlashAccess.eraseDone(uint16_t page_no)
	{
		call StdOut.print("Sector erase done: ");
		call StdOut.printHexword(page_no);
		call StdOut.print("\r\n");
	}

	event void FlashAccess.eraseAllDone()
	{
		call StdOut.print("Bulk erase done\r\n");
	}
	
	event void FlashAccess.writeDone(uint16_t page_no, void *page)
	{
		call StdOut.print("Write done: ");
		call StdOut.printHexword(page_no);
		call StdOut.print("\r\n");
	}


	///////////////////////////////////////////////////////////////////////
	// StdOut
	///////////////////////////////////////////////////////////////////////
	uint8_t keyBuffer;
	task void consoleTask();
	
	async event result_t StdOut.get(uint8_t data) {
		
		keyBuffer = data;

		// call Leds.redToggle();

		post consoleTask();

		return SUCCESS;
	}
		
	task void consoleTask() 
	{
		uint8_t data[2];
				uint16_t i;
		
		atomic data[0] = keyBuffer;
		data[1] = '\0';

		switch(data[0]) 
		{
			case '1':

				call StdOut.print("Wake-up: ");
				call StdOut.printHex(call FlashControl.start());
				call StdOut.print("\r\n");

				break;


			case '2':

				call StdOut.print("Sleep: ");
				call StdOut.printHex(call FlashControl.stop());
				call StdOut.print("\r\n");

				break;

			case '3':

				// clear buffer
				for (i = 0; i < 256; i++)
				{
					readbuffer[i] = 0;
				}

				// read from buffer
				if (call FlashAccess.read(0x06FF, readbuffer) == SUCCESS) {
					call StdOut.print("Read from page: 0x06FF\r\n");
				} else 	{
					call StdOut.print("Read failed\r\n");
				}

				break;

			case '4':

				for (i = 0; i < 256; i++)
				{
					writebuffer[i] = i;
				}

				call StdOut.print("Write numbers to page: 0x06FF\r\n");

				call FlashAccess.write(0x06FF, writebuffer);

				break;

			case '5':

				// clear buffer
				for (i = 0; i < 256; i++)
				{
					readbuffer[i] = 0;
				}

				// read from buffer
				if (call FlashAccess.read(0x0700, readbuffer) == SUCCESS) {
					call StdOut.print("Read from page: 0x0700\r\n");
				} else 	{
					call StdOut.print("Read failed\r\n");
				}

				break;

			case '6':

				for (i = 0; i < 256; i++)
				{
					writebuffer[i] = i;
				}

				call StdOut.print("Write numbers to page: 0x0700\r\n");

				call FlashAccess.write(0x0700, writebuffer);

				break;

			case '7':

				call StdOut.print("Erase sector: 0x060000\r\n");

				call FlashAccess.erase(0x0600);

				//call FlashAccess.eraseAll();

				break;

			case '8':

				call StdOut.print("Erase sector: 0x070000\r\n");

				call FlashAccess.erase(0x0700);

				//call FlashAccess.eraseAll();

				break;

			case '9':

				call StdOut.print("Erase all\r\n");

				call FlashAccess.eraseAll();

				break;

			case 'q':
				if (call BusArbitration.getBus() == SUCCESS) 
				{
					call StdOut.print("Bus locked\r\n");
				} else 
				{
					call StdOut.print("Bus locked failed\r\n");
				}
				break;

			case 'w':
				call BusArbitration.releaseBus();
				break;

			case '\r':
				call StdOut.print("\r\n");
				break;

			default:
				call StdOut.print(data);
		}
		
		return;
	}

}



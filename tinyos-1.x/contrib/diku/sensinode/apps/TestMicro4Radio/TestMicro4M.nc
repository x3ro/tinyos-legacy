module TestMicro4M {
	provides {
		interface StdControl;
	}
	uses {
		interface Timer;
		interface Leds;
		interface ExtLeds;
		interface HPLKBI as KBI;
		interface StdOut;
		interface SimpleMac;
		interface StdControl as SimpleMacControl;
		interface BusArbitration;
		interface LocalTime;
	}
}

implementation {

/*#include "HPLSpi.h"*/

	mac_addr_t shortAddress;
	uint8_t transmitPacket[128];
	packet_t * transmitPacketPtr;
	bool echo = FALSE, filter = TRUE;
	bool radioOn = FALSE, receiverOn = FALSE, timerOn = FALSE;

	const ieee_mac_addr_t * ieeeAddress;

	task void sendPacketTask();

	/**********************************************************************
	** StdControl
	**********************************************************************/
	command result_t StdControl.init() {
		call Leds.init(); 
		call ExtLeds.init();
		call SimpleMacControl.init();

		shortAddress = TOS_LOCAL_ADDRESS;
		transmitPacketPtr = (packet_t *) transmitPacket;

		// Beacon packet
		transmitPacketPtr->length = 9; //7 + 118 + 2;
		transmitPacketPtr->fcf = 0x0000;
		transmitPacketPtr->data_seq_no = 0x01;
		transmitPacketPtr->dest = 0xFFFF;
		transmitPacketPtr->src = 0;

/*			// 118 bytes
		for (i = 0; i < 118; i++)
		{
			transmitPacketPtr->data[i] = i;
		}
*/
		// 2 bytes
		transmitPacketPtr->fcs.rssi = 0;
		transmitPacketPtr->fcs.correlation = 0;

		return SUCCESS;
	}

	command result_t StdControl.start() {
		call StdOut.init();
		call KBI.init();

		call Leds.greenOn();
		call ExtLeds.greenOn();
		
		call StdOut.print("Program initialized\n\r");

		//call Timer.start(TIMER_REPEAT, 1000);
		//call PowerMode.set(1);
		//call SimpleMacControl.start();		
		//LPMode_enable();
		//__nesc_atomic_sleep();
		//_BIS_SR(GIE+CPUOFF+SCG1+SCG0+OSCOFF);
		
		return SUCCESS;
	}

	command result_t StdControl.stop() {
		call Timer.stop();
		
		return SUCCESS;
	}



	///////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////
	event result_t KBI.switchDown(uint8_t key)
	{

		call Leds.redToggle();

		if ( (key & 0x01) == 0x01) {
			call ExtLeds.redToggle();
		} 

		if ( (key & 0x02) == 0x02) {
			call ExtLeds.greenToggle();
		} 


		return SUCCESS;
	}

	event result_t Timer.fired()
	{
		
		if (radioOn) {
			radioOn = FALSE;
			receiverOn = FALSE;
			call SimpleMacControl.stop();
			call StdOut.print("Radio turned off\r\n");
		} else {
			radioOn = TRUE;
			receiverOn = TRUE;
			call SimpleMacControl.start();		
			call StdOut.print("Radio turned on\r\n");
		}
		// post sendPacketTask();

		return SUCCESS;
	}


 	/**********************************************************************
 	 *********************************************************************/
 	event result_t BusArbitration.busFree()
 	{
		call StdOut.print("Bus released\r\n");

 		return SUCCESS;
 	}


	/**********************************************************************
	** CC2420
	**********************************************************************/

	task void sendPacketTask() 
	{
		//uint8_t * ptr = (uint8_t *) transmitPacketPtr;

		//ptr[3]++;
		
		call SimpleMacControl.start();
		call SimpleMac.sendPacket(transmitPacketPtr);
		call SimpleMacControl.stop();
	}
	
	event void SimpleMac.sendPacketDone(packet_t *packet, result_t result)
	{
/*		if (result == SUCCESS) {
			call StdOut.print("Transmission done\r\n");
		} else {
			call StdOut.print("Transmission failed\r\n");
		}
*/
		return;
	}

	event packet_t * SimpleMac.receivedPacket(packet_t *packet)
	{
		uint8_t i;
		packet_t * ptr;
	
		call StdOut.print("Received packet: ");
		call StdOut.printHex(packet->length);
		call StdOut.print(" ");
		call StdOut.printHexword(packet->fcf);
		call StdOut.print(" ");
		call StdOut.printHex(packet->data_seq_no);
		call StdOut.print(" ");
		call StdOut.printHexword(packet->dest);
		call StdOut.print(" ");
		call StdOut.printHexword(packet->src);
		call StdOut.print(" ");
		
		for (i = 0; i < packet->length - 9; i++)
		{
			call StdOut.printHex(packet->data[i]);
			call StdOut.print(" ");
		}

		call StdOut.printHex(packet->fcs.rssi);
		call StdOut.print(" ");
		call StdOut.printHex(packet->fcs.correlation);
		call StdOut.print("\r\n");
				
		ptr = packet;
		packet = transmitPacketPtr;
		transmitPacketPtr = ptr;

		if (echo)
		{
			post sendPacketTask();
		}

		return packet;
	}

	/**********************************************************************
	** StdOut
	**********************************************************************/
	uint8_t keyBuffer;
	uint16_t i = 0;
	task void consoleTask();
	
	async event result_t StdOut.get(uint8_t data) {
		
		keyBuffer = data;

		call Leds.redToggle();

		post consoleTask();

		return SUCCESS;
	}

	task void consoleTask() 
	{
		uint8_t data[2];
		
		atomic data[0] = keyBuffer;

		switch (data[0]) {
		case '\r': 
			call StdOut.print("\r\n");
			break;
		case '1':
			if (call BusArbitration.getBus() == SUCCESS) {
				call StdOut.print("Bus reserved\r\n");
			} else {
				call StdOut.print("Bus already reserved\r\n");
			}			

			break;
		case '2':
			call BusArbitration.releaseBus();

			break;

		case 't':
			call StdOut.print("Transmitting packet: ");
			
			call StdOut.dumpHex(transmitPacket, 18, " ");
			call StdOut.print("\r\n");

			call SimpleMac.sendPacket((packet_t *)transmitPacket);

			break;
		case 'r':
			if (!radioOn) {
			
				call StdOut.print("Radio is off\r\n");
			
			} else if (receiverOn) {
				receiverOn = FALSE;
				call StdOut.print("Receiver turned off\r\n");
				call SimpleMac.rxDisable();
			} else {
				receiverOn = TRUE;
				call StdOut.print("Receiver turned on\r\n");
				call SimpleMac.rxEnable();
			}

			break;
		case 's':
			if (radioOn) {
				radioOn = FALSE;
				receiverOn = FALSE;
				call SimpleMacControl.stop();
				call StdOut.print("Radio turned off\r\n");
			} else {
				radioOn = TRUE;
				receiverOn = TRUE;
				call SimpleMacControl.start();		
				call StdOut.print("Radio turned on\r\n");
			}
			
			break;
		case 'a':

			shortAddress = *(call SimpleMac.getAddress());

			call StdOut.print("Short address: ");
			call StdOut.printHexword(shortAddress);
			call StdOut.print("\r\n");
			
			break;
		case 'b':
			shortAddress = TOS_LOCAL_ADDRESS;
			
			call StdOut.print("Set shortAddress: ");
			call StdOut.printHexword(TOS_LOCAL_ADDRESS);
			call StdOut.print("\r\n");

			call SimpleMac.setAddress(&shortAddress);
			
			break;

		case 'c':

			if (filter) {
				filter = FALSE;
				call StdOut.print("Address filtering off\r\n");
				call SimpleMac.addressFilterDisable();
			} else {
				filter = TRUE;
				call StdOut.print("Address filtering on\r\n");
				call SimpleMac.addressFilterEnable();
			}

			break;
		case 'd':

			ieeeAddress = call SimpleMac.getExtAddress();
			
			call StdOut.print("Extended address: ");
			call StdOut.dumpHex((uint8_t *) ieeeAddress, 8, " ");
			call StdOut.print("\r\n");

			break;

		case 'e':
			if (echo) {
				echo = FALSE;
				call StdOut.print("Echo off\r\n");
			} else {
				echo = TRUE;
				call StdOut.print("Echo on\r\n");
			}
			
			break;

		case 'm':
			if (timerOn) {
				timerOn = FALSE;
				call Timer.stop();
			} else {
				timerOn = TRUE;
				call Timer.start(TIMER_REPEAT, 1000);
			}
			
			break;


		default:
			data[1] = '\0';
			call StdOut.print(data);
			break;
		}

	}



}



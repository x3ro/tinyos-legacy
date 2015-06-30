/* $Id: TestSMACM.nc,v 1.4 2005/07/20 15:36:48 janflora Exp $ */
/** Test application for SimpleMac

  Copyright (C) 2004 Mads Bondo Dydensborg, <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

/** Test application for SimpleMac.
 *
 * <p>This is a very simplistic test of SimpleMac. The application
 * will try to send packets on a fixed channel, while also listening
 * to them.</p>
 *
 * <p>Each time a packet is sent, the green led will be toggles -
 * about once a second, and the string "sent" will be output to the
 * UART.</p>
 *
 * <p>In case of error, the red led will blink on and off.</p>
 *
 * <p>Every time a packet is received, the yellow led will toggle.</p>
 *
 * @author Mads Bondo Dydensborg, <madsdyd@diku.dk>
 * Note: This is a work in progress.
 */
module TestSMACM
{
	provides {
		interface StdControl;
	}
	uses {
		interface SimpleMac as Mac;
		interface Timer;
		interface Leds;
		interface HPLUART as Uart;
	}
}
implementation
{
	// Variables for the mac comm
	// rx_packet_t rx_packet;
	// char rx_buf[20] = "receive buffer";
	tx_packet_t tx_packet;
	char tx_buf[20] = "transmit buffer";

	char ok[6] = "Sent\n";
	char fail[6] = "FAIL\n";
	char fired[6] = "fired";
	char booted[7] = "booted";
	char packets[8] = "packet\n";

	/*int rx_count = 0;
	int tx_count = 0;
	uint8_t dsn = 0;*/
	
	char uart_transmit[2];	
	
	result_t transmitPacket();
 
	/* **********************************************************************
	 * Setup/Init code
	 * *********************************************************************/

	/* Init */
	command result_t StdControl.init()
	{
		// Just make sure that something happens.
		call Leds.init();
		call Leds.redOn();

		// init variables
		/*rx_packet.data = rx_buf;
		rx_packet.maxDataLength = 20;*/
		tx_packet.data = tx_buf;
		tx_packet.dataLength = 20;
    
		// Set up a packet to control the Freescale ligth demo device app.
		/*tx_buf[0] = 0xE1; // Code bytes non-ZigBee
		tx_buf[1] = 0xCC;
		tx_buf[2] = 0x01; // SECURITY;  Generic security number
		tx_buf[3] = 1; // device_led;  Target device
		tx_buf[4] = 4; // Targeted device's LED. Position contains result on RX
		tx_buf[5] = dsn; // Current data sequence number 
		tx_buf[6] = 0x00; // Target device's receive count
		tx_buf[7] = 0x11; // toggle light
		tx_packet.dataLength = 8;*/

		// Other init
		call Uart.init();
		if (call Mac.init()) {
			//call Leds.greenOn();
		}
		if (call Mac.setChannel(0)) {
			//call Leds.yellowOn();
		}

		call Uart.put2(booted, &booted[sizeof(booted)-1]);
		return SUCCESS;
	}

	/* start */
	command result_t StdControl.start()
	{
		//transmitPacket();
		//call Leds.redOn();
		return call Timer.start(TIMER_REPEAT, 1000);
		//return SUCCESS;
	}

	/* stop - never called */
	command result_t StdControl.stop()
	{
		//call Leds.redOff();
		return SUCCESS;
	}

	/* **********************************************************************
	 * Timer/radio related code
	 * *********************************************************************/
	
	result_t transmitPacket()
	{
		result_t res=SUCCESS;
		call Leds.redOff();
		//call Leds.greenOff();
		//call Leds.yellowOff();
		/*if (call Uart.put2(fired, &fired[6])) {
			call Leds.yellowToggle();
		}
		return SUCCESS; */
		
		res = call Mac.send(&tx_packet);
		if (res) {
			call Leds.greenToggle();
			if (call Uart.put2(ok, &ok[sizeof(ok)-1])) {
				call Leds.yellowOn();
			} else {
				call Leds.redOn();
			}
			/*tx_count++;   
			dsn++;
			if (dsn == 0xFF) {
				dsn = 0;
			}
			tx_buf[5] = dsn;*/ // Current data sequence number
		} /*else {
			//call Leds.redOn();
			if (call Uart.put2(fail, &fail[sizeof(fail)])) {
				//call Leds.yellowOn();
			} else {
				//call Leds.yellowOff();
			}
		}*/
		// todo: IntToLeds
		//call Leds.yellowToggle();
		return res;
	}

	/* We transmit a packet each time the timer fires */
	event result_t Timer.fired()
	{
		return transmitPacket();
		// return SUCCESS;
	}


	/**************************************************************************/
	/**
	 * Receving a packet.
	 *
	 * <p>Upon receiving a packet, we output a string, and toggle the
	 * yellow led.</p>
	 *
	 * @param pacet The packet we received
	 * @return A new packet (the same) for the mac layer to use.
	 */
	/**************************************************************************/
	event rx_packet_t * Mac.receive(rx_packet_t * packet)
	{
		call Leds.greenToggle();
		//rx_count++;
		call Uart.put2(packets, &packets[sizeof(packets)]);
		return packet;
		// call Mac.enableReceive(&rx_packet, 0);
	}

	event void Mac.sendDone(tx_packet_t * packet)
	{
		//call Leds.yellowToggle();
	}

	/* Don't know what to do with this, lets boogie */
	event void Mac.reset()
	{
		int i;
		call Leds.redOff();
		call Leds.greenOff();
		call Leds.yellowOff();
		while(1) {
			for( i=0; i<50; i++ ) // wait 0.5s
			TOSH_uwait( 10000 ); // actually 0.01s
			call Leds.redToggle();
			call Leds.greenToggle();
			call Leds.yellowToggle();
		}
	}

	/* **********************************************************************
	 * Handle stuff from the Uart
	 * *********************************************************************/

	/** 
	 * Happily echo any data for now */
	async event result_t Uart.get(uint8_t uartData)
	{
		atomic uart_transmit[0] = uartData;
		call Uart.put2(uart_transmit, &uart_transmit[1]);
		call Leds.greenToggle();
		return SUCCESS;
	}
	
	/**
	 * "Proud little uart, done you are." */
	async event result_t Uart.putDone() {
		//call Leds.greenOn();
		return SUCCESS;
	}
}

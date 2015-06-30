/* $Id: TestSMACM.nc,v 1.6 2005/09/23 13:32:01 janflora Exp $ */
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
 * to them. The packets are compatible with the packets needed to control
 * the Freescale LigthDemo Controller.</p>
 *
 * <p>Each time a packet is sent, the green led will be toggled -
 * about once a second, and the packet send will be dumped on the
 * console.</p>
 *
 * <p>Every time a packet is received, the yellow led will toggle, and
 * the packet will be dumped on the console.</p>
 *
 * <p>In case of error, the red led will blink on and off.</p>
 *
 * <p>The demo outputs information on the console, and accepts the following
 * commands:</p>
 * <ul>
 * <li>d : Disable receiving (go to idle mode).</li>
 * <li>e : Enable receive (go to listen mode).</li>
 * <li>s : Toggle sending when timer triggers.</li>
 * <li>p : Print status information.</li>
 * <lI>r : Test of reset handler, its borken...</li>
 *
 * @author Mads Bondo Dydensborg, <madsdyd@diku.dk>
 * Note: This is a work in progress.
 */
// includes hcs08hardware;
module TestSMACM {
  provides {
    interface StdControl;
  }
  uses {
    interface SimpleMac as Mac;
    interface Timer;
    interface Leds;
    interface ConsoleInput as ConsoleIn;
    interface ConsoleOutput as ConsoleOut;
  }
}
implementation {
  /** Do we send or not */
  bool isSending;
  
  /** Packet to transmit */
  tx_packet_t tx_packet;
  /** Packet buffer space */
  char tx_buf[29] = "abcdefghijklmnopqrstuvwxyzabc";

  /** Receive conter is here */
  uint32_t rx_count = 0;
  /** Transmit counter is here */
  uint32_t tx_count = 0;
  /** Increments every time a packet is sent, controls
      the SMAC light demo thingy. */
  uint8_t dsn = 0; 
  
  /* **********************************************************************
   * Setup/Init code
   * ******************************************************************* */

  /* ********************************************************************** */
  /**
   * Init.
   *
   * <p>Sets up our send buffer, inits hardware.</p>
   *
   * @return SUCCESS always.
   */
  /* ********************************************************************** */
  command result_t StdControl.init() {
    /* Just make sure that something happens. */
    call Leds.init();
    call Leds.redOn();

    /* init variables */
    tx_packet.data = tx_buf;
    
    /* Set up a packet to control the Freescale ligth demo device app */
    //tx_buf[0] = 0xE1; /* Code bytes non-ZigBee */
    //tx_buf[1] = 0xCC;
    //tx_buf[2] = 0x01; // SECURITY; /* Generic security number */
    //tx_buf[3] = 1; // device_led; /* Target device */
    //tx_buf[4] = 4; /* Targeted device's LED. Position contains result on RX */
    //tx_buf[5] = dsn; /* Current data sequence number */
    //tx_buf[6] = 0x00; /* Target device's receive count */
    //tx_buf[7] = 0x11; /* toggle light */
    //tx_packet.dataLength = 8;

	tx_packet.dataLength = 29;

    /* Other init */
    if (call Mac.init()) {
      //call Leds.greenOn();
    }
    if (call Mac.setChannel(0)) {
      //call Leds.yellowOn();
    }
    call ConsoleOut.print("\n\rTestSMACM.nc booted\n\r");
    return SUCCESS;
  }

	/* ********************************************************************** */
	/**
	 * Start
	 *
	 * <p>Get the timer going.</p>
	 *
	 * @return SUCCESS if the timer was started, FAIL otherwise.
	 */
	/* ********************************************************************** */
	command result_t StdControl.start()
	{
		isSending = call Timer.start(TIMER_REPEAT, 1000);
		//while (1) {
			//call ConsoleOut.print("Testing...");
			//TOSH_uwait( 10000 ); // actually 0.01s
			//call ConsoleOut.print("\n123");
			
		//}
		return isSending;
	}

  /* ********************************************************************** */
  /**
   * Stop.
   *
   * <p>Never really called, but we kill the timer.</p>
   *
   * @return SUCCESS if the timer was stopped, FAIL otherwise.
   */
  /* ********************************************************************** */
  command result_t StdControl.stop() {
    return call Timer.stop(); 
  }


  /* **********************************************************************
   * Code that actually does something
   * ******************************************************************* */

  /* ********************************************************************** */
  /**
   * Transmit task.
   *
   * <p>This task transmit a packet and updates the dsn field.</p>
   *
   */
  /* ********************************************************************** */
  task void transmitPacket() {
    call Leds.redOff();
    if (call Mac.send(&tx_packet)) {
      call Leds.greenToggle();
      call ConsoleOut.print("Packet sent: 0x");
      call ConsoleOut.dumpHex(tx_packet.data, tx_packet.dataLength, " 0x");
      call ConsoleOut.print("\n\r");
      tx_count++;   
      dsn++;
      if (dsn == 0xFF) {
	dsn = 0;
      }
      //tx_buf[5] = dsn; /* Current data sequence number */
    } else {
      call Leds.redOn();
      call ConsoleOut.print("Error sending packet\n\r");
    }
  }
  
  /* ********************************************************************** */
  /**
   * sendDone handler.
   *
   * <p>Its a proud little chip. We ignore it. One could check the
   * status flag, I think. Maybe.</p>
   *
   * @param packet the packet that was transmitted.
   * @return
   */
  /* ********************************************************************** */
  event void Mac.sendDone(tx_packet_t * packet) {
     //call ConsoleOut.print("Senddone\n\r");
  }

  /** We post a task to transmit a packet each time the timer fires */
  /* ********************************************************************** */
  /**
   * Timer fired handler.
   *
   * <p>Post a transmitTask task.</p>
   *
   * @return SUCCESS always.
   */
  /* ********************************************************************** */
  event result_t Timer.fired() {
    if (isSending) post transmitPacket();
    return SUCCESS;
  }


  /* ********************************************************************** */
  /**
   * Receving a packet.
   *
   * <p>Upon receiving a packet, we dump the packet, and toggle the
   * yellow led.</p>
   *
   * @param packet The packet we received
   * @return A new packet (the same) for the mac layer to use.
   */
  /* ********************************************************************** */
  event rx_packet_t * Mac.receive(rx_packet_t * packet) {
    rx_count++;
    call ConsoleOut.print("Packet received: 0x");
    call ConsoleOut.dumpHex(packet->data, packet->dataLength, " 0x");
    call ConsoleOut.print("\n\r");
    call Leds.yellowToggle();
    call Mac.enableReceive();
    return packet;
  }

  /* **********************************************************************
   * Broken reset handler code. Never seen a reset anyway.
   * ******************************************************************* */

  /** TinyOS is sooo lean, it can do infinte loops in just 5 seconds.
      Anyway, we need a task for the Console print statements to work...
      TODO: Fix this. It is broken.....

 */
  task void resetToggle() {
    uint16_t i;
    call ConsoleOut.print("\nresetToggle\n");
    for( i=0; i<500; i++ ); // wait some time.
      // TOSH_uwait( 10000 ); // actually 0.01s
    call Leds.redToggle();
    call Leds.greenToggle();
    call Leds.yellowToggle();
    post resetToggle();
  }

  task void resetTask() {
    call ConsoleOut.print("Got RESET from Mac layer!\n\r");
    call Leds.redOff();
    call Leds.greenOff();
    call Leds.yellowOff();
    post resetToggle();
  }

  /* Don't know what to do with this, lets boogie */
  event void Mac.reset() {
    post resetTask();
  }

  /* **********************************************************************
   * Handle stuff from the console
   * ******************************************************************* */
  /** 
   * Store data from the Console.get event here. */
  char console_data;
  
  /* ********************************************************************** */
  /**
   * Handle data from the console.
   *
   * <p>Simply dump the data, handle any commands.</p>
   *
   */
  /* ********************************************************************** */

  task void handleGet() {
    char console_transmit[2];
    atomic console_transmit[0] = console_data;
    console_transmit[1] = 0;
    call ConsoleOut.print(console_transmit); 
    switch (console_transmit[0]) {
    case 'd':
      call Mac.disableReceive();
      call ConsoleOut.print("\n\tDisabled SimpleMac Receive\n");
      break;
    case 'e':
      if (call Mac.enableReceive()) {
	call ConsoleOut.print("\n\tEnabled SimpleMac Receive\n");
      } else {
	call ConsoleOut.print("\n\tDisabled SimpleMac Receive\n");
      }
      break;
    case 'p':
      call ConsoleOut.print("\n\tHere is ");
      call ConsoleOut.printHexword(TOS_LOCAL_ADDRESS);
      call ConsoleOut.print("\n\tStatus: sent: ");
      call ConsoleOut.printHexlong(tx_count);
      call ConsoleOut.print(", received: ");
      call ConsoleOut.printHexlong(rx_count);
      call ConsoleOut.print("\n");
      /*      call ConsoleOut.print("\tSchedules = ");
      call ConsoleOut.printHexlong(schedules);
      call ConsoleOut.print("\n"); */
      break;
    case 'r':
      call ConsoleOut.print("\n\tYou ask for it, you get it\n");
      post resetTask();
      break;
    case 's':
      isSending = !isSending;
      if (isSending) {
	if (call Timer.start(TIMER_REPEAT, 1000)) {
	  call ConsoleOut.print("\n\tStarting sending\n");
	} else {
	  call ConsoleOut.print("\n\tError starting send\n\n");
	  isSending = FALSE;
	}
      } else {
	call ConsoleOut.print("\n\tStopping sending\n");
	call Timer.stop();
      }
      break;
    default:
    }
  }

	/* ********************************************************************** */
	/**
	 * Console data event.
	 *
	 * <p>We store the data, post a task.</p>
	 *
	 * @param data The data from the console.
	 * @return SUCCESS always.
	 */
	/* ********************************************************************** */
	async event result_t ConsoleIn.get(uint8_t uartData) {
		atomic console_data = uartData;
		post handleGet();
		return SUCCESS;
	}

}

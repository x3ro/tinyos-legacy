/* $Id: SimpleMacM.nc,v 1.1 2006/07/04 09:02:40 marcus_chang Exp $ */
/* SimpleMac module. Wrapper around Freescale SMAC library.

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
includes simplemac;

/** 
 * SimpleMac module.
 * 
 * <p>Provides an implementation of the Freescale SMAC interface. This
 * module is mostly a thin wrapper to allow the various compilation
 * stages to take place. See the interface for documentation about the
 * methods, etc. </p>
 *
 * <p>NOTE: I am currently adapting this to be more "TinyOS Like". So,
 * this module must support always receive, and stuff like that. </p>
 *
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */
includes AM;

module SimpleMacM
{
	provides {
		interface SimpleMac;
	}
	uses {
		interface Leds;
	}
	/*
	uses {
		interface StdOut;
		interface HCIPacket;
		interface Interrupt;
	}*/
}
implementation
{

	/* Buffers needed for communication to the SMAC library.  Note: We
	   allocate an entire TOS_Msg, although slightly less is actually
	   used. */
	TOS_Msg commBuf_; 
	rx_packet_t rxPacket_; 
	rx_packet_t *rxPacketPtr_;
  
	/* Used for checking if we are in receive mode */
	bool inReceiveMode_;

	/* Used to check if we are already sending, and to store the data pointer */
	tx_packet_t * txPacket;
 
	/**************************************************************************/
	/**
	 * Initialise the SMAC layer.
	 *
	 * <p>The hardware is actually initialized in HPLInit, because of
	 * dependencies on the clock/external osciliator. In here, we set up
	 * our buffers, and try to set the SMAC layer into receive mode.</p>
	 *
	 * @return SUCCESS if the SMAC layer is in receive mode, FAIL otherwise.
	 */
	/**************************************************************************/
	command result_t SimpleMac.init() {
		rxPacket_.data          = (uint8_t *) &commBuf_;
		rxPacket_.maxDataLength = sizeof(commBuf_);
		rxPacketPtr_            = &rxPacket_;
		txPacket                = NULL;
		//inReceiveMode_ = MLME_RX_enable_request(rxPacketPtr_, 0);
		return inReceiveMode_;
	}

	/**************************************************************************/
	/**
	 * Reset call back.
	 *
	 /**************************************************************************/

	/* Reset call back */
	void MLME_MC13192_reset_indication() __attribute__((C, spontaneous))
	{
		signal SimpleMac.reset();
	}
  

	/**************************************************************************/
	/**
	 * Disable receive.
	 *
	 */
	/**************************************************************************/
	command void SimpleMac.disableReceive()
	{
		MLME_RX_disable_request();
		inReceiveMode_ = FALSE;
	}

	/**************************************************************************/
	/**
	 * Enable receive.
	 *
	 */
	/**************************************************************************/
	command result_t SimpleMac.enableReceive()
	{
		inReceiveMode_ = MLME_RX_enable_request(rxPacketPtr_, 0);
		return inReceiveMode_;
		return SUCCESS;
	}

	/**************************************************************************/
	/**
	 * Task that sends a packet.
	 *
	 * <p>Uses the shared variable txPacket.</p>
	 *
	 */
	/**************************************************************************/
	task void sendPacket()
	{
		tx_packet_t * data;
		data = txPacket;
		txPacket = NULL;
		// TODO: There are most likely problems with inReceiveMode here...
		if (inReceiveMode_) {
			MLME_RX_disable_request();
		}
		MCPS_data_request(data);
		if (inReceiveMode_) {
			inReceiveMode_ = MLME_RX_enable_request(rxPacketPtr_, 0);
		}
		signal SimpleMac.sendDone(data);
	}

	/**************************************************************************/
	/**
	 * Send a packet.
	 *
	 * <p>Send a TOS_Msg.</p>
	 *
	 * @param
	 * @return SUCCESS if the buffer will be sent, FAIL if not. If
	 * SUCCESS a sendDone event should be expected, if FAIL it should
	 * not.
	 */
	/**************************************************************************/
	command result_t SimpleMac.send(tx_packet_t * data)
	{
		if (txPacket) {
			return FAIL;
		} 
		txPacket = data;
		post sendPacket();
		return SUCCESS;
	}
  
	/* Callback function from SMAC, note the attributes. These are needed
	   so that nescc/ncc does not remove this function. */
	void MCPS_data_indication(rx_packet_t * data) __attribute__((C, spontaneous))
	{
		// TODO: Check status. I reckon. Hmm. 
		rxPacketPtr_ = signal SimpleMac.receive(data);
		if (inReceiveMode_) {
			//inReceiveMode_ = MLME_RX_enable_request(rxPacketPtr_, 0);
		}
	}

	/* Set the channel. Note the parameter checking */
	command result_t SimpleMac.setChannel(uint8_t channel)
	{
		if (channel <= 15) {
			MLME_set_channel_request(channel);
			return SUCCESS;
		} else {
			return FAIL;
		}
		return FAIL;
	}

	/* Enable receive */
	/*  command result_t SimpleMac.enableReceive(rx_packet_t * packet, uint32_t timeout) {
		return MLME_RX_enable_request(packet, timeout);
	}*/

	// Just redirect handling of interrupts to the SMAC interrupt handler.
/*	TOSH_SIGNAL(IRQ)
	{
		asm("PSHH");
		irq_isr();
		asm("PULH");
	}	*/
}

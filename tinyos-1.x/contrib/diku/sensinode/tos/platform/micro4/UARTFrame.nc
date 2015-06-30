/*
  Copyright (C) 2004 Klaus S. Madsen <klaussm@diku.dk>
  Copyright (C) 2006 Marcus Chang <marcus@diku.dk>

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

includes UARTFrame;

interface UARTFrame {
	/**
	 * send will send a packet through the UART to a PC. The packet will
	 * be returned when sendDone is signalled.
	 *
	 * @param packet_t *packet The packet to send
	 */
	command result_t sendFrame(uint8_t * frame);
	event void sendFrameDone(uint8_t * frame);

	event void receivedFrame(uint8_t * frame);
}
	

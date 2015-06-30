/* Copyright (c) 2007, Marcus Chang, Klaus Madsen
   All rights reserved.

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer. 

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution. 

    * Neither the name of the Dept. of Computer Science, University of 
      Copenhagen nor the names of its contributors may be used to endorse or 
      promote products derived from this software without specific prior 
      written permission. 

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
   POSSIBILITY OF SUCH DAMAGE.
*/  

/*
        Author:         Marcus Chang <marcus@diku.dk>
                        Klaus S. Madsen <klaussm@diku.dk>
        Last modified:  March, 2007
*/


includes packet;

interface Connection
{
	command result_t accept();
	command result_t reject();
	event void established();
	event void lost();

	command result_t open();
	event void openDone(uint8_t result);
	command result_t close();
	command result_t setPublicChannel(uint8_t channel);
	command result_t setPrivateChannel(uint8_t channel);
	command uint16_t getShortAddress();

	/**
	 * sendPacket will perform a CCA, put the device into transmit mode,
	 * send the packet and return. If the SPI bus is not free or CCA
	 * fails, the sending of the packet is delayed. The contents
	 * of packet_t must not be changed after the call to sendPacket.
	 *
	 * @param packet_t * packet The packet that should be sent.
	 * @return result_t If the packet was queued for sending successfully.
	 */
	command result_t sendPacket(packet_t *packet);

	/**
	 * sendPacketDone is signaled when a packet have been sent successfully.
	 *
	 * @param packet_t *packet The packet that have been sent.
	 * @param result_t result If the packet was sent successfully.
	 */
	event void sendPacketDone(packet_t *packet, result_t result);

	/**
	 * receivedPacket is signalled when the radio have received a full
	 * packet.  The function must return a free packet_t to the radio
	 * stack. This can be the same packet that have been signaled
	 *
	 * @param packet_t *packet The received packet
	 * @return packet_t* A free packet
	 */
	event packet_t *receivedPacket(packet_t *packet);

}

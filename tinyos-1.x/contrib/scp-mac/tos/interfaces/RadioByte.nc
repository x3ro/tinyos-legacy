/*
 * Copyright (C) 2003-2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye
 *
 * This interface is for sending and receiving bytes over the radio
 * The return values for result_t is either SUCCESS or FAIL
 */

interface RadioByte 
{
   // transmission of bytes
   
   // startTx sets radio to Tx state, and send start symbol automatically
   command result_t startTx(uint16_t addPreamble);
   
   // tx next byte in the packet
   command result_t txNextByte(uint8_t data);
   
   // tx byte is done, asking for another byte
   async event result_t txByteReady();
   
   // start symbol is just sent; used for time stamping outgoing pkt
   async event result_t startSymSent();

   // reception of bytes
   
   // start symbol is just received; used for time stamping incoming pkt
   async event result_t startSymDetected(uint8_t bitOffset);
   
   // a byte in packet is just received
   async event result_t rxByteDone(uint8_t data);
}

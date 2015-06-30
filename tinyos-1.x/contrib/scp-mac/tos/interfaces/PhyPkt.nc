/*
 * Copyright (C) 2005 the University of Southern California.
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
 * Authors:	Wei Ye
 *
 * This interface provides packet transmission and reception at the 
 * physical layer.
 */

includes PhyPktError;
interface PhyPkt
{
  // packet transmission
  
  // send a packet with packet length and additional preamble bytes
  command result_t send(void* packet, uint8_t pktLen, uint16_t addPreamble);
  
  // transmission is done, signalled in a task
  event result_t sendDone(void* packet);
  
  // packet reception
  
  // a packet is received, signalled in a task
  event void* receiveDone(void* packet, uint8_t error);
}

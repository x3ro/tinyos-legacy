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
 * Authors: Wei Ye
 *
 * This interface is for adjusting carrier sense threshold
 */

interface CsThreshold
{
  /**
   * reset carrier sense threshold to initial value
   */
  command void reset();

  /**
   * update threshold with measured RSSI samples on signal and noise 
   * it is required that ALL samples are taken when a packet is correctly
   * received, i.e., it should be signaled by PhyRadio after CRC check
   * @param signalVal Measured signal strength
   * @param noiselVal Measured noise level 
   */
  command void update(uint16_t signalVal, uint16_t noiselVal);
  
  /**
   * when a node is starved on Tx, busyThreshold will be raised to make
   * it more aggressive. Starvation is defined by MAC that uses carrier
   * sense, e.g., consecutive failures on randamized carrier sense
   */
  command void starved();
}

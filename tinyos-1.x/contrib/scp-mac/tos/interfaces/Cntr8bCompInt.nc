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
 * This interface is to control and handle the compare interrupt on the 
 * 8-bit hardware timer/counter, e.g., counter0 and couter2 on the AtMega128L.
 */
 
interface Cntr8bCompInt
{
  // enable output compare interrupt
  command void enable();
   
  // disable output compare interrupt
  command void disable();
   
  // Get output compare register value
  command uint8_t getCompReg();

  // Set output compare register value
  command void setCompReg(uint8_t value);
   
  // Signal event on output compare match interrupt
  async event void fire();
}

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
 * Authors: Wei Ye, Asif Pathan
 *
 * This interface is controls LPL MAC parameters
 */

interface LplControl
{
  /**
   * temporarily disable periodic radio sleeping
   * in this mode, a node does not sleep, but still sends long preambles
   */
  command void disableSleeping();

  /**
   * enable periodic radio sleeping; this is default, normal LPL
   */
  command void enableSleeping();

  /**
   * temporarily disable regular polling
   */
  command void disablePolling();

  /**
   * enable periodic polling; this is default, normal LPL
   */
  command void enablePolling();

  /**
   * poll channel activity now
   */
  command result_t pollChannel();

  /**
   * set the length of additional preamble
   * @param length of additional preamble to be added to normal preamble
   */
  command void addPreamble(uint16_t length);

  /**
   * set contention window size
   * @param numSlots The size of the contention window, must be 2^n - 1
   */
  command void setContWin(uint8_t numSlots);

  /**
   * set backoff time when poll channel indicates channel busy
   * @param time The backoff time should be longer than preamble transmission
   *    time, so that the start symbol can be detected if there is an actual
   *    transmission
   * @param repeat If true will repeat backoff if channel is still busy at
   *    the end of last backoff. If false, will go back to sleep after first
   *    backoff period
   */
  command void setBackoffTime(uint32_t time, bool repeat);

  /**
   * disable automatic re-send after previous attempt fails
   * autoReTx is default mode on LPL
   */
  command void disableAutoReTx();

  /**
   * enable automatic re-send after previous attempt fails
   * autoReTx is default mode on LPL
   */
  command void enableAutoReTx();

}

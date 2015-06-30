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
 * This interface provides radio control: state control, Tx and Rx bytes
 * The return values for result_t is either SUCCESS or FAIL
 */

includes RadioState;
interface RadioState 
{
   // Radio state control
   
   /* put radio into idle state
    * if wakes up from sleep, may not be immediately done
    * Return: 0 -- fail; 1 -- success_done; 2 -- success_wait
    */
   command int8_t idle();

   /* signal radio wakeup is done */
   async event result_t wakeupDone();

   /* put radio into sleep state */
   command result_t sleep();
   
   /* get current radio state */
   command uint8_t get();
}

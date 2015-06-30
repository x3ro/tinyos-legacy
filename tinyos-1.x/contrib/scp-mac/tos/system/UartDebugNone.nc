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
 * Authors:	Wei Ye
 * 
 * UART debugging: this component is for sending debugging bytes thru UART
 *   Note: can't be used with any application that uses the UART, e.g. motenic
 *
 * There are two known problems:
 * 1) Initializing UART (e.g., for UART debugging) may cause a node fail to 
 *   start or stop running when it's not connected with a serial board/cable.
 *   The reason needs to be checked further.
 * 2) When HPLPowerManagement is enabled, the bytes sent to the UART could 
 *   be corrupted. To be safe, HPLPowerManagement should be disabled when
 *   using UART debug.
 */


module UartDebugNone
{
  provides {
    interface UartDebug;
  }
}

implementation
{

  command void UartDebug.init()
  {
  }

  command void UartDebug.txState(uint8_t state)
  {
  }
  
  command void UartDebug.txEvent(uint8_t eventNum)
  {
  }
  
  command void UartDebug.txByte(uint8_t byte)
  {
  }
}

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
 * This module implements the hardware clock with a resolution of 1ms.
 * The hardware counter is running asynchronously with a separate watch
 * crystal (32,768Hz). The counter is free-running, and each tick
 * is 1ms (actually 1000/1024 ms). It is able to maintain a local system time 
 * while enabling CPU deep sleep mode.
 */

configuration CounterAsyncC
{
  provides {
    interface StdControl;
    interface GetSetU8 as CntrValue;
    interface Cntr8bCompInt as CntrCompInt;
    interface Cntr8bOverInt as CntrOverInt;
  }
}

implementation
{
  components CounterAsyncM, HPLPowerManagementM;
  
  StdControl = CounterAsyncM;
  CntrValue = CounterAsyncM;
  CntrCompInt = CounterAsyncM;
  CntrOverInt = CounterAsyncM;
  
  // wiring to lower layers
  
  CounterAsyncM.PowerManagement -> HPLPowerManagementM;
}
   

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
 * This module implements basic CSMA protocol
 * Physical layer carrier sense is used before sending each packet
 * Random backoff when carrier sense fails
 */

configuration Csma
{
  provides {
    interface StdControl;
    interface CsmaControl;
    interface MacMsg;
    interface MacActivity;
    interface GetSetU8 as RadioTxPower;
    interface RadioEnergy;
  }
}

implementation
{
  components CsmaM, PhyRadio, RandomLFSR, TimerC, 

#if defined CSMA_UART_DEBUG_STATE_EVENT
    UartDebugStateEvent as UartDbg,
#elif defined CSMA_UART_DEBUG_BYTE
    UartDebugByte as UartDbg,
#else
    UartDebugNone as UartDbg,
#endif

#ifdef CSMA_LED_DEBUG  
    LedsC;
#else
    NoLeds as LedsC;
#endif
  
  StdControl = CsmaM;
  CsmaControl = CsmaM;
  MacMsg = CsmaM;
  MacActivity = CsmaM;
  RadioTxPower = PhyRadio;
  RadioEnergy = PhyRadio;
  
  // wiring to lower layers
  
  CsmaM.PhyControl -> PhyRadio;
  CsmaM.RadioState -> PhyRadio;
  CsmaM.CarrierSense -> PhyRadio;
  CsmaM.CsThreshold -> PhyRadio;
  CsmaM.PhyPkt -> PhyRadio;
  CsmaM.PhyNotify -> PhyRadio;
  CsmaM.PhyStreamByte -> PhyRadio;
  CsmaM.Random -> RandomLFSR;
  CsmaM.TimerControl -> TimerC;
  CsmaM.NavTimer -> TimerC.Timer[unique("Timer")];
  CsmaM.NeighbNavTimer -> TimerC.Timer[unique("Timer")];
  CsmaM.BackoffTimer -> TimerC.Timer[unique("Timer")];
  CsmaM.Leds -> LedsC;
  CsmaM.UartDebug -> UartDbg;
}

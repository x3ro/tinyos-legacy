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
 * This configuration wires for CSMA with low power listening (LPL)
 */

configuration Lpl
{
  provides {
    interface StdControl;
    interface MacMsg;
    interface LplControl;
    interface MacActivity as LplActivity;
    interface LplPollTimer;
    interface GetSetU8 as RadioTxPower;
    interface RadioEnergy;
  }
}

implementation
{
  components LplM, Csma, PhyRadio, LocalTimeC, TimerC,

#if defined LPL_UART_DEBUG_STATE_EVENT
    UartDebugStateEvent as UartDbg,
#elif defined LPL_UART_DEBUG_BYTE
    UartDebugByte as UartDbg,
#else
    UartDebugNone as UartDbg,
#endif

#ifdef LPL_LED_DEBUG  
    LedsC;
#else
    NoLeds as LedsC;
#endif
   
  StdControl = LplM;
  MacMsg = LplM;
  LplControl = LplM;
  LplActivity = LplM;
  LplPollTimer = LplM;
  RadioTxPower = PhyRadio;
  RadioEnergy = PhyRadio;
   
  // wiring to lower layers
   
  LplM.CsmaStdControl -> Csma;
  LplM.CsmaMacMsg -> Csma;
  LplM.CsmaControl -> Csma;
  LplM.CsmaActivity -> Csma;
  LplM.RadioState -> PhyRadio;
  LplM.CarrierSense -> PhyRadio;
  LplM.PhyNotify -> PhyRadio;
  LplM.LocalTime -> LocalTimeC;
  LplM.PollTimer -> TimerC.TimerAsync[unique("Timer")];
  LplM.WaitTimer -> TimerC.Timer[unique("Timer")];
  LplM.Leds -> LedsC;
  LplM.UartDebug -> UartDbg;
}

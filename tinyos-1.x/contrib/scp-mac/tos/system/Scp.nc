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
 * This configuration wires for SCP-MAC
 */

configuration Scp
{
  provides {
    interface StdControl;
    interface MacMsg;
    interface GetSetU8 as RadioTxPower;
    interface RadioEnergy;
  }
}

implementation
{
  components ScpM, Lpl, PhyRadio, RandomLFSR, LocalTimeC, TimerC,

#if defined SCP_UART_DEBUG_STATE_EVENT
    UartDebugStateEvent as UartDbg,
#elif defined SCP_UART_DEBUG_BYTE
    UartDebugByte as UartDbg,
#else
    UartDebugNone as UartDbg,
#endif

#ifdef SCP_LED_DEBUG
    LedsC;
#else
    NoLeds as LedsC;
#endif

  StdControl = ScpM;
  MacMsg = ScpM;
  RadioTxPower = PhyRadio;
  RadioEnergy = PhyRadio;

  // wiring to lower layers

  ScpM.LplStdControl -> Lpl;
  ScpM.LplMacMsg -> Lpl;
  ScpM.LplControl -> Lpl;
  ScpM.LplActivity -> Lpl;
  ScpM.LplPollTimer -> Lpl;
  ScpM.RadioState -> PhyRadio;
  ScpM.Random -> RandomLFSR;
  ScpM.CarrierSense -> PhyRadio;
  ScpM.CsThreshold -> PhyRadio;
  ScpM.TxPreamble -> PhyRadio;
  ScpM.PhyNotify -> PhyRadio;
  ScpM.LocalTime -> LocalTimeC;
  ScpM.SyncTimer -> TimerC.Timer[unique("Timer")]; 
  ScpM.NeighDiscTimer -> TimerC.Timer[unique("Timer")];
  ScpM.TxTimer -> TimerC.TimerAsync[unique("Timer")];
  ScpM.AdapTxTimer -> TimerC.TimerAsync[unique("Timer")];
  ScpM.AdapPollTimer -> TimerC.TimerAsync[unique("Timer")];
  ScpM.bootTimer -> TimerC.TimerAsync[unique("Timer")];
  ScpM.Leds -> LedsC;
  ScpM.UartDebug -> UartDbg;
}

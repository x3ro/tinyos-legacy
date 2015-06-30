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
 * This is the physical layer that sends and receives a packet
 *   - accept any type and length (<= PHY_MAX_PKT_LEN in phy_radio_msg.h) of packet
 *   - sending a packet: encoding and byte spooling
 *   - receiving a packet: decoding, byte buffering
 *   - Optional CRC check
 *   - interface to radio control and physical carrier sense
 */

configuration PhyRadio
{
   provides {
      interface SplitControl;
      interface StdControl as PhyControl;
      interface RadioState;
      interface PhyPkt;
      interface PhyNotify;
      interface TxPreamble as PhyTxPreamble;
      interface CarrierSense;
      interface CsThreshold;
      interface GetSetU8 as RadioTxPower;
      interface PhyStreamByte;
      interface RadioEnergy;
   }
}

implementation
{
  components
    PhyRadioM,
    HPLCC2420C,
    CC2420ControlM,
    ClockSCPM,
    TimerC,
    LocalTimeC,
    HPLPowerManagementM,
#if defined PHY_UART_DEBUG_STATE_EVENT
    UartDebugStateEvent as UartDbg,
#elif defined PHY_UART_DEBUG_BYTE
    UartDebugByte as UartDbg,
#else
    UartDebugNone as UartDbg,
#endif
#ifdef PHY_LED_DEBUG  
    LedsC;
#else
    NoLeds as LedsC;
#endif
   
  // Implemented in this module

  SplitControl = PhyRadioM; 
  PhyControl = PhyRadioM;
  RadioState = PhyRadioM;
  PhyPkt = PhyRadioM;
  PhyNotify = PhyRadioM;
  PhyTxPreamble = PhyRadioM;
  PhyStreamByte = PhyRadioM;
  CarrierSense = PhyRadioM;
  CsThreshold = PhyRadioM;
  RadioTxPower = PhyRadioM;
  RadioEnergy = PhyRadioM;
  
  // wiring to lower layers
  
  PhyRadioM.LTimeControl -> LocalTimeC.TimeControl;
  PhyRadioM.LocalTime -> LocalTimeC;
  PhyRadioM.RxTimer -> TimerC.Timer[unique("Timer")];
  PhyRadioM.Leds -> LedsC;
  PhyRadioM.UartDebug -> UartDbg;

  PhyRadioM.CC2420SplitControl -> CC2420ControlM;
  PhyRadioM.CC2420Control -> CC2420ControlM;

  PhyRadioM.CSMAClock -> ClockSCPM.Clock;

  PhyRadioM.PowerEnable -> HPLPowerManagementM.Enable;
  PhyRadioM.PowerManagement -> HPLPowerManagementM;

  PhyRadioM.HPLChipcon -> HPLCC2420C.HPLCC2420;
  PhyRadioM.HPLChipconFIFO -> HPLCC2420C.HPLCC2420FIFO;
  PhyRadioM.FIFOP -> HPLCC2420C.InterruptFIFOP;
  PhyRadioM.SFD -> HPLCC2420C.CaptureSFD;

  CC2420ControlM.HPLChipconControl -> HPLCC2420C.StdControl;
  CC2420ControlM.HPLChipcon -> HPLCC2420C.HPLCC2420;
  CC2420ControlM.HPLChipconRAM -> HPLCC2420C.HPLCC2420RAM;
  CC2420ControlM.CCA -> HPLCC2420C.InterruptCCA;
}

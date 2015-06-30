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
   components PhyRadioM, RadioControl, CodecNone, LocalTimeC,

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
   
  PhyControl = PhyRadioM;
  RadioState = PhyRadioM;
  PhyPkt = PhyRadioM;
  PhyNotify = PhyRadioM;
  PhyTxPreamble = PhyRadioM;
  PhyStreamByte = PhyRadioM;
  CarrierSense = RadioControl;
  CsThreshold = RadioControl;
  RadioTxPower = RadioControl;
  RadioEnergy = RadioControl;
  
  // wiring to lower layers
  
  PhyRadioM.RadControl -> RadioControl;
  PhyRadioM.RadioState -> RadioControl;
  PhyRadioM.RadioByte -> RadioControl;
  PhyRadioM.RadioTxPreamble -> RadioControl;
  PhyRadioM.RadioCsThresh -> RadioControl;
  PhyRadioM.CodecControl -> CodecNone;
  PhyRadioM.Codec -> CodecNone;
  PhyRadioM.RSSISample -> RadioControl;
  PhyRadioM.LTimeControl -> LocalTimeC.TimeControl;
  PhyRadioM.LocalTime -> LocalTimeC;
  PhyRadioM.Leds -> LedsC;
  PhyRadioM.UartDebug -> UartDbg;

}

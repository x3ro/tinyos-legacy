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
 * The radio for Mica consists of 3 parts:
 *   1) RFM; 2) SPI; 3) Timer/counter 2
 *
 * This module implements the radio control functions:
 *   1) Put radio into different states:
 *   	a) idle; b) sleep; c) receive; d) transmit
 *   2) Physical carrier sense
 *   3) Tx and Rx of bytes
 */

configuration RadioControl
{
   provides {
      interface StdControl;
      interface RadioState;
      interface CarrierSense;
      interface CsThreshold;
      interface RadioByte;
      interface TxPreamble as RadioTxPreamble;
      interface GetSetU8 as RadioTxPower;
      interface RSSISample;
      interface RadioEnergy;
   }
}

implementation
{
   components RadioControlM, CC1000ControlM, HPLCC1000M, ADCC, TimerC,
      HPLPowerManagementM, LocalTimeC;
   
   StdControl = RadioControlM;
   RadioState = RadioControlM;
   CarrierSense = RadioControlM;
   CsThreshold = RadioControlM;
   RadioByte = RadioControlM;
   RadioTxPreamble = RadioControlM;
   RadioTxPower = RadioControlM;
   RSSISample = RadioControlM;
   RadioEnergy = RadioControlM;
   
   RadioControlM.CC1000StdControl -> CC1000ControlM;
   RadioControlM.CC1000Control -> CC1000ControlM;
   RadioControlM.ADCControl -> ADCC;
   RadioControlM.RSSIADC -> ADCC.ADC[TOS_ADC_CC_RSSI_PORT];
   RadioControlM.WakeupTimer -> TimerC.TimerAsync[unique("Timer")];
   RadioControlM.PowerManagement -> HPLPowerManagementM;
   RadioControlM.LocalTime -> LocalTimeC;
   
   CC1000ControlM.HPLChipcon -> HPLCC1000M.HPLCC1000;
}

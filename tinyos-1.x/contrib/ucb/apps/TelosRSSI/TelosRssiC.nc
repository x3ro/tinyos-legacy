/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* Authors:   Kamin Whitehouse
 *
 */

includes TelosRssi;

configuration TelosRssiC {
}

implementation {
  components Main
	, TelosRssiM
	, GenericComm
    	, DelugeC
//	, ClockC we use TimerC now -mpm
	, TimerC 
//	, ADCC not needed on telos -mpm
//	, ChannelMonEccC
//	, CC1000RadioC make this switch based on PLATFORM
	, CC2420RadioC
//	, ChipconM
	, LedsC;
//	, ByteEEPROM; // -mpm

  Main.StdControl -> TelosRssiM.StdControl;
  Main.StdControl -> GenericComm.Control;
  Main.StdControl -> DelugeC;
//  Main.StdControl -> ByteEEPROM; // -mpm

  TelosRssiM.SendChirpMsg ->GenericComm.SendMsg[118];
  TelosRssiM.SendDataMsg ->GenericComm.SendMsg[117];
  TelosRssiM.SendDataOverviewMsg ->GenericComm.SendMsg[120];
  TelosRssiM.ReceiveChirpMsg ->GenericComm.ReceiveMsg[118];
  TelosRssiM.ReceiveDataRequestMsg ->GenericComm.ReceiveMsg[121];
  TelosRssiM.ReceiveChirpCommandMsg ->GenericComm.ReceiveMsg[119];
  //TelosRssiM.RadioCoordinator->CC1000RadioC.RadioReceiveCoordinator; // not needed b/c we read RSSI off the msg 
  //TelosRssiM.CC1000Control->CC1000RadioC; // make this switch based on PLATFORM
  TelosRssiM.CCControl->CC2420RadioC;	
  // TelosRssiM.ADC->ADCC.ADC[0]; not needed on telos -mpm
  TelosRssiM.Leds->LedsC;
//  TelosRssiM.Clock -> ClockC; we use Timer instead -mpm
//  TelosRssiM.Chipcon -> ChipconM;
  TelosRssiM.Timer->TimerC.Timer[unique("Timer")]; // we use this instead of Clock -mpm
  TelosRssiM.TimerControl -> TimerC.StdControl;

  // these guys are for the data logging -mpm
//  TelosRssiM.AllocationReq -> ByteEEPROM.AllocationReq[MY_FLASH_REGION_ID]; 
//  TelosRssiM.WriteData -> ByteEEPROM.WriteData[MY_FLASH_REGION_ID];
//  TelosRssiM.ReadData -> ByteEEPROM.ReadData[MY_FLASH_REGION_ID];
}






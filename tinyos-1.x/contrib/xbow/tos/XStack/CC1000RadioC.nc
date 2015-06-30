// $Id: CC1000RadioC.nc,v 1.1 2004/11/23 23:23:45 jdprabhu Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/*
 * Authors: Philip Buonadonna
 * Date last modified: $Revision: 1.1 $
 *
 */

/**
 * @author Philip Buonadonna
 */

configuration CC1000RadioC
{
  provides {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface CC1000Control;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioPower;
  }
}
implementation
{
  components CC1000RadioIntM as CC1000RadioM, CC1000ControlM, HPLCC1000M, 
    RandomLFSR, ADCC, HPLSpiM, TimerC, HPLPowerManagementM, LedsC, TimeSyncService;

  StdControl = CC1000RadioM;
  Send = CC1000RadioM;
  RadioPower = CC1000RadioM;
  Receive = CC1000RadioM;
  CC1000Control = CC1000ControlM;
  RadioReceiveCoordinator = CC1000RadioM.RadioReceiveCoordinator;
  RadioSendCoordinator = CC1000RadioM.RadioSendCoordinator;

  CC1000RadioM.CC1000StdControl -> CC1000ControlM;
  CC1000RadioM.TimeStart -> TimeSyncService;
  CC1000RadioM.CC1000Control -> CC1000ControlM;
  CC1000RadioM.Random -> RandomLFSR;
  CC1000RadioM.ADCControl -> ADCC;
  CC1000RadioM.RSSIADC -> ADCC.ADC[TOS_ADC_CC_RSSI_PORT];
  CC1000RadioM.SpiByteFifo -> HPLSpiM;

  CC1000RadioM.Time -> TimeSyncService;
  CC1000RadioM.TimerControl -> TimerC.StdControl;
  CC1000RadioM.SquelchTimer -> TimerC.Timer[unique("Timer")];
  CC1000RadioM.WakeupTimer -> TimerC.RadioTimer;
  CC1000RadioM.Leds -> LedsC;
  //  CC1000RadioM.SysTime->SysTimeC;

  CC1000ControlM.HPLChipcon -> HPLCC1000M;
  CC1000RadioM.PowerManagement ->HPLPowerManagementM.PowerManagement;
  HPLSpiM.PowerManagement ->HPLPowerManagementM.PowerManagement;
  CC1000RadioM.EnableLowPower ->HPLPowerManagementM.Enable;
}

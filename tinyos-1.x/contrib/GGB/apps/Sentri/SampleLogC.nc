// $Id: SampleLogC.nc,v 1.1 2006/12/01 00:09:07 binetude Exp $

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
/*
 *
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

configuration SampleLogC
{
  provides {
    interface StdControl;
    interface SampleLog;
  }
}
implementation
{
  components
    TimerC,
    GenericComm, GenericCommPromiscuous,
    QueuedSend,
    Bcast,
    WMEWMAMultiHopRouter as multihopM, StrawM,
    SysTimeM, TimeSyncC,

    MicroTimerM, Accel, Temp, ByteEEPROM, BufferedLog,
    SampleLogM;

  StdControl = Accel;
  StdControl = Temp;
  StdControl = ByteEEPROM;
  StdControl = SampleLogM;

  SampleLog = SampleLogM;

  SampleLogM.ExternalShutdown -> TimerC;
  SampleLogM.ExternalShutdown -> GenericComm;
  SampleLogM.ExternalShutdown -> GenericCommPromiscuous;
  SampleLogM.ExternalShutdown -> QueuedSend;
  SampleLogM.ExternalShutdown -> Bcast;
  SampleLogM.ExternalShutdown -> multihopM;
  SampleLogM.ExternalShutdown -> StrawM;
  SampleLogM.ExternalShutdown -> SysTimeM;
  SampleLogM.ExternalShutdown -> TimeSyncC;

  SampleLogM.MicroTimer -> MicroTimerM;

  SampleLogM.mADC -> Accel;
  SampleLogM.ADC -> Temp;

  SampleLogM.DataAllocReq -> ByteEEPROM.AllocationReq[DATA_EEPROM_ID];
  SampleLogM.LogData -> BufferedLog;
  SampleLogM.fastAppend -> BufferedLog;
  BufferedLog.Logger -> ByteEEPROM.LogData[DATA_EEPROM_ID];
}


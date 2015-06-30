// $Id: MicaHWVerify.nc,v 1.3 2003/10/07 21:44:53 idgay Exp $

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
/* Authors:  Su Ping,  Jason Hill 
 * Revision:  $Id: MicaHWVerify.nc,v 1.3 2003/10/07 21:44:53 idgay Exp $
 *
 */

/**
 * @author Su Ping
 * @author Jason Hill 
 */

includes HardwareId;
includes HWVerifyMsg;

configuration MicaHWVerify { 
}
implementation
{
  components Main, GenericComm as Comm, HPLFlash, LedsC, TimerC, SerialId;

#ifdef PLATFORM_MICA
  components MicaHWVerifyM;

  Main.StdControl -> MicaHWVerifyM;
  Main.StdControl -> TimerC;

  MicaHWVerifyM.CommControl->Comm;
  MicaHWVerifyM.ReceiveMsg->Comm.ReceiveMsg[AM_RXTESTMSG];
  MicaHWVerifyM.Send->Comm.SendMsg[AM_DIAGMSG];

  MicaHWVerifyM.Timer -> TimerC.Timer[unique("Timer")];
  MicaHWVerifyM.Leds -> LedsC;

  MicaHWVerifyM.HwIdControl -> SerialId;
  MicaHWVerifyM.HardwareId -> SerialId;

  MicaHWVerifyM.FlashControl -> HPLFlash;
  MicaHWVerifyM.FlashSelect -> HPLFlash;
  MicaHWVerifyM.FlashSPI -> HPLFlash;
#else
  components Mica2HWVerifyM;

  Main.StdControl -> Mica2HWVerifyM;
  Main.StdControl -> TimerC;
  Main.StdControl -> SerialId;
  Main.StdControl -> HPLFlash;
  Main.StdControl -> Comm;

  Mica2HWVerifyM.ReceiveMsg->Comm.ReceiveMsg[AM_RXTESTMSG];
  Mica2HWVerifyM.Send->Comm.SendMsg[AM_DIAGMSG];

  Mica2HWVerifyM.Timer -> TimerC.Timer[unique("Timer")];
  Mica2HWVerifyM.Leds -> LedsC;
  Mica2HWVerifyM.HardwareId -> SerialId;
  Mica2HWVerifyM.FlashSelect -> HPLFlash;
  Mica2HWVerifyM.FlashSPI -> HPLFlash;
#endif 

}


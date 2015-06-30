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

/* Authors:             Joe Polastre
 * 
 * $Id: GDI2SoftB.nc,v 1.2 2003/10/07 21:45:31 idgay Exp $
 */

/**
 * Platforms:
 * <p>
 * Mica2DOT platform
 *
 **/

includes GDI2SoftMsg;

configuration GDI2SoftB {
}
implementation {
  components Main, GDI2SoftBM, VirtualComm as Comm, LedsC, TimerC, ResetC, \
             Melexis, SensirionHumidity, \
             RandomLFSR, ADCC, CC1000RadioIntM, CC1000ControlM, \
             HPLPowerManagementM, 
             MHSender, ParentSelection, Bcast, BcastM, RouteHelper;


  Main.StdControl -> TimerC;
  Main.StdControl -> Bcast;
  Main.StdControl -> Comm;
  Main.StdControl -> MHSender;
  Main.StdControl -> GDI2SoftBM;

  GDI2SoftBM.RouteState -> RouteHelper.RouteState;

  GDI2SoftBM.Send -> MHSender.MultiHopSend[AM_GDI2SOFT_B_REV2_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_B_REV2_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_WS_REV2_MSG];

  // GDI2SoftBM.Send -> Comm.SendMsg[AM_GDI2SOFT_WS_MSG];
  // GDI2SoftBM.SendCalib -> Comm.SendMsg[AM_GDI2SOFT_CALIB_MSG];
  // GDI2SoftBM.SendAck -> Comm.SendMsg[AM_GDI2SOFT_ACK_MSG];

  GDI2SoftBM.SendCalib -> MHSender.MultiHopSend[AM_GDI2SOFT_CALIB_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_CALIB_MSG];
  GDI2SoftBM.SendAck -> MHSender.MultiHopSend[AM_GDI2SOFT_ACK_REV2_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_ACK_REV2_MSG];

  GDI2SoftBM.ReceiveCalibLocal -> Comm.ReceiveMsg[AM_GDI2SOFT_CALIB_IN_LOCAL_MSG];
  GDI2SoftBM.ReceiveCalib -> Bcast.Receive[AM_GDI2SOFT_CALIB_IN_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_CALIB_IN_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_CALIB_IN_MSG];
  GDI2SoftBM.ReceiveRate -> Bcast.Receive[AM_GDI2SOFT_RATE_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_RATE_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_RATE_MSG];
  GDI2SoftBM.ReceiveReset -> Bcast.Receive[AM_GDI2SOFT_RESET_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_RESET_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_RESET_MSG];
  GDI2SoftBM.ReceiveQuery -> Bcast.Receive[AM_GDI2SOFT_QUERY_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_QUERY_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_QUERY_MSG];
  GDI2SoftBM.ReceiveNetwork -> Bcast.Receive[AM_GDI2SOFT_NETWORK_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_NETWORK_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_NETWORK_MSG];

  GDI2SoftBM.ForwardDone <- BcastM.ForwardDone;

  GDI2SoftBM.Reset -> ResetC;
 
  GDI2SoftBM.PowerEnable -> HPLPowerManagementM.Enable;
  GDI2SoftBM.PowerDisable -> HPLPowerManagementM.Disable;

  GDI2SoftBM.SetListeningMode -> CC1000RadioIntM.SetListeningMode;
  GDI2SoftBM.GetListeningMode -> CC1000RadioIntM.GetListeningMode;
  GDI2SoftBM.SetTransmitMode -> CC1000RadioIntM.SetTransmitMode;
  GDI2SoftBM.GetTransmitMode -> CC1000RadioIntM.GetTransmitMode;

  GDI2SoftBM.setRouteUpdateInterval -> ParentSelection.setRouteUpdateInterval;

  GDI2SoftBM.CC1000Control -> CC1000ControlM;

  GDI2SoftBM.Leds -> LedsC;

  GDI2SoftBM.HumidityControl -> SensirionHumidity;
  GDI2SoftBM.Humidity -> SensirionHumidity.Humidity;
  GDI2SoftBM.HumidityTemp -> SensirionHumidity.Temperature;
  GDI2SoftBM.HumidityError -> SensirionHumidity.HumidityError;
  GDI2SoftBM.HumidTempError -> SensirionHumidity.TemperatureError;

  GDI2SoftBM.MelexisControl -> Melexis;
  GDI2SoftBM.Thermopile -> Melexis.Thermopile;
  GDI2SoftBM.Temperature -> Melexis.Temperature;
  GDI2SoftBM.Calibration -> Melexis;

  GDI2SoftBM.Timer -> TimerC.Timer[unique("Timer")];
  GDI2SoftBM.WaitTimer -> TimerC.Timer[unique("Timer")];
  GDI2SoftBM.BackoffTimer -> TimerC.Timer[unique("Timer")];
  GDI2SoftBM.NetworkTimer -> TimerC.Timer[unique("Timer")];

  GDI2SoftBM.Random -> RandomLFSR;

  GDI2SoftBM.Voltage -> ADCC.ADC[TOS_ADC_VOLTAGE_PORT];
  GDI2SoftBM.VoltageControl -> ADCC.ADCControl;

}

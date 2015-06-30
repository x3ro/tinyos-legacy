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
 * $Id: GDI2SoftWS.nc,v 1.2 2003/10/07 21:45:32 idgay Exp $
 */

/**
 * Platforms:
 * <p>
 * Mica2DOT platform
 *
 **/

includes GDI2SoftMsg;

configuration GDI2SoftWS {
}
implementation {
  components Main, GDI2SoftWSM, VirtualComm as Comm, LedsC, TimerC, ResetC, \
             Hamamatsu, SensirionHumidity, IntersemaPressure, TaosPhoto, \
             RandomLFSR, ADCC, CC1000RadioIntM, CC1000ControlM, \
             HPLPowerManagementM, 
             MHSender, ParentSelection, Bcast, BcastM, RouteHelper;


  Main.StdControl -> TimerC;
  Main.StdControl -> Bcast;
  Main.StdControl -> Comm;
  Main.StdControl -> MHSender;
  Main.StdControl -> GDI2SoftWSM;

  GDI2SoftWSM.RouteState -> RouteHelper.RouteState;

  GDI2SoftWSM.Send -> MHSender.MultiHopSend[AM_GDI2SOFT_WS_REV2_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_WS_REV2_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_B_REV2_MSG];

  // GDI2SoftWSM.Send -> Comm.SendMsg[AM_GDI2SOFT_WS_MSG];
  // GDI2SoftWSM.SendCalib -> Comm.SendMsg[AM_GDI2SOFT_CALIB_MSG];
  // GDI2SoftWSM.SendAck -> Comm.SendMsg[AM_GDI2SOFT_ACK_MSG];

  GDI2SoftWSM.SendCalib -> MHSender.MultiHopSend[AM_GDI2SOFT_CALIB_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_CALIB_MSG];
  GDI2SoftWSM.SendAck -> MHSender.MultiHopSend[AM_GDI2SOFT_ACK_REV2_MSG];
  ParentSelection.InForwardReceive -> Comm.ReceiveMsg[AM_GDI2SOFT_ACK_REV2_MSG];

  GDI2SoftWSM.ReceiveCalibLocal -> Comm.ReceiveMsg[AM_GDI2SOFT_CALIB_IN_LOCAL_MSG];
  GDI2SoftWSM.ReceiveCalib -> Bcast.Receive[AM_GDI2SOFT_CALIB_IN_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_CALIB_IN_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_CALIB_IN_MSG];
  GDI2SoftWSM.ReceiveRate -> Bcast.Receive[AM_GDI2SOFT_RATE_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_RATE_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_RATE_MSG];
  GDI2SoftWSM.ReceiveReset -> Bcast.Receive[AM_GDI2SOFT_RESET_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_RESET_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_RESET_MSG];
  GDI2SoftWSM.ReceiveQuery -> Bcast.Receive[AM_GDI2SOFT_QUERY_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_QUERY_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_QUERY_MSG];
  GDI2SoftWSM.ReceiveNetwork -> Bcast.Receive[AM_GDI2SOFT_NETWORK_MSG];
  Bcast.ReceiveMsg[AM_GDI2SOFT_NETWORK_MSG] -> Comm.ReceiveMsg[AM_GDI2SOFT_NETWORK_MSG];

  GDI2SoftWSM.ForwardDone <- BcastM.ForwardDone;

  GDI2SoftWSM.Reset -> ResetC;
 
  GDI2SoftWSM.PowerEnable -> HPLPowerManagementM.Enable;
  GDI2SoftWSM.PowerDisable -> HPLPowerManagementM.Disable;

  GDI2SoftWSM.SetListeningMode -> CC1000RadioIntM.SetListeningMode;
  GDI2SoftWSM.GetListeningMode -> CC1000RadioIntM.GetListeningMode;
  GDI2SoftWSM.SetTransmitMode -> CC1000RadioIntM.SetTransmitMode;
  GDI2SoftWSM.GetTransmitMode -> CC1000RadioIntM.GetTransmitMode;

  GDI2SoftWSM.setRouteUpdateInterval -> ParentSelection.setRouteUpdateInterval;

  GDI2SoftWSM.CC1000Control -> CC1000ControlM;

  GDI2SoftWSM.Leds -> LedsC;

  GDI2SoftWSM.HamamatsuControl -> Hamamatsu;
  GDI2SoftWSM.HamamatsuCh1 -> Hamamatsu.ADC[1];
  GDI2SoftWSM.HamamatsuCh2 -> Hamamatsu.ADC[2];

  GDI2SoftWSM.HumidityControl -> SensirionHumidity;
  GDI2SoftWSM.Humidity -> SensirionHumidity.Humidity;
  GDI2SoftWSM.HumidityTemp -> SensirionHumidity.Temperature;
  GDI2SoftWSM.HumidityError -> SensirionHumidity.HumidityError;
  GDI2SoftWSM.HumidTempError -> SensirionHumidity.TemperatureError;

  GDI2SoftWSM.PressureControl -> IntersemaPressure;
  GDI2SoftWSM.Pressure -> IntersemaPressure.Pressure;
  GDI2SoftWSM.PressureTemp -> IntersemaPressure.Temperature;
  GDI2SoftWSM.PressureError -> IntersemaPressure.PressureError;
  GDI2SoftWSM.PressTempError -> IntersemaPressure.TemperatureError;
  GDI2SoftWSM.Calibration -> IntersemaPressure;

  GDI2SoftWSM.TaosControl -> TaosPhoto;
  GDI2SoftWSM.TaosCh0 -> TaosPhoto.ADC[0];
  GDI2SoftWSM.TaosCh1 -> TaosPhoto.ADC[1];
  GDI2SoftWSM.TaosCh0Error -> TaosPhoto.ADCError[0];
  GDI2SoftWSM.TaosCh1Error -> TaosPhoto.ADCError[1];

  GDI2SoftWSM.Timer -> TimerC.Timer[unique("Timer")];
  GDI2SoftWSM.WaitTimer -> TimerC.Timer[unique("Timer")];
  GDI2SoftWSM.BackoffTimer -> TimerC.Timer[unique("Timer")];
  GDI2SoftWSM.NetworkTimer -> TimerC.Timer[unique("Timer")];

  GDI2SoftWSM.Random -> RandomLFSR;

  GDI2SoftWSM.Voltage -> ADCC.ADC[TOS_ADC_VOLTAGE_PORT];
  GDI2SoftWSM.VoltageControl -> ADCC.ADCControl;

}

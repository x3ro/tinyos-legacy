/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     Nithya Ramanathan
 *
 */

includes AppSleepMsg;
includes IntMsg;

configuration AppSleep
{
  provides {
    interface StdControl;
  }
}

implementation
{
  components Main, AppSleepM, TimerC, SysTimeC, GenericComm as Comm, LedsC, 
#ifdef MEASURE_STATS
	StatisticsC, 
#endif
	SysTimeStampingC;

  StdControl = AppSleepM;

#ifdef MEASURE_STATS
  AppSleepM -> StatisticsC.RetreiveStatistics;
  Main.StdControl -> StatisticsC.StdControl;
  AppSleepM.ReportPacketEvent -> StatisticsC;
#endif

  Main.StdControl -> AppSleepM.StdControl;
  Main.StdControl -> TimerC.StdControl;

#ifdef USE_LPL
  AppSleepM.LowPowerListening -> Comm.LowPowerListening;
#endif

  AppSleepM.Send -> Comm.SendMsg[AM_INTMSG];
  AppSleepM.Recv -> Comm.ReceiveMsg[AM_INTMSG];
  AppSleepM.RadioControl -> Comm.Control;
  AppSleepM.Leds -> LedsC;
  AppSleepM.SysTime -> SysTimeC;
  AppSleepM.TimeStamping -> SysTimeStampingC.TimeStamping;

  AppSleepM.WakeUpTimer -> TimerC.Timer[unique("Timer")];
  AppSleepM.SendPkt -> TimerC.Timer[unique("Timer")];
  AppSleepM.SendStats -> TimerC.Timer[unique("Timer")];
  AppSleepM.StayAwakeTimer -> TimerC.Timer[unique("Timer")];
  AppSleepM.TimeSynch -> TimerC.Timer[unique("Timer")];
  AppSleepM.CalculateSD -> TimerC.Timer[unique("Timer")];
  AppSleepM.ExpectTimeSynch -> TimerC.Timer[unique("Timer")];
}


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
                                                                                
includes fabAppMsg;
includes IntMsg;

configuration fabApp
{
  provides {
    interface StdControl;
  }
}

implementation
{
  components Main, fabAppM, TimerC, SysTimeC, GenericComm as Comm, LedsC, 
#ifdef MEASURE_STATS
	StatisticsC, 
#endif
	SysTimeStampingC;

  StdControl = fabAppM;
  fabAppM.TimeStamping -> SysTimeStampingC.TimeStamping;
  fabAppM.LowPowerListening -> Comm.LowPowerListening;

#ifdef MEASURE_STATS
  fabAppM -> StatisticsC.RetreiveStatistics;
  fabAppM.ReportPacketEvent -> StatisticsC.ReportPacketEvent;
#endif

  Main.StdControl -> fabAppM.StdControl;
  Main.StdControl -> TimerC.StdControl;
  fabAppM.Send -> Comm.SendMsg[AM_INTMSG];
  fabAppM.Recv -> Comm.ReceiveMsg[AM_INTMSG];
  fabAppM.RadioControl -> Comm.Control;

  fabAppM.WakeUpTimer -> TimerC.Timer[unique("Timer")];
  fabAppM.TimeSynch -> TimerC.Timer[unique("Timer")];
  fabAppM.Leds -> LedsC;
  fabAppM.SysTime -> SysTimeC;
}


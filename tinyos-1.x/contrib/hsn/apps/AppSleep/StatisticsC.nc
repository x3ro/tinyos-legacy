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
                                                                                
configuration StatisticsC
{
  provides {
    interface StdControl;
    interface RetreiveStatistics;
    interface ReportPacketEvent;
    interface SysTime as SysClock;
  }
}

implementation
{
  components SysTimeC, msClockM, StatisticsM, Main, TimerC;

  StdControl = StatisticsM;
  RetreiveStatistics = StatisticsM;
  ReportPacketEvent = StatisticsM;
  SysClock = msClockM.SysTime;

  msClockM.Timer -> TimerC.Timer[unique("Timer")];
  msClockM.SysClock -> SysTimeC.SysTime;
  Main.StdControl -> msClockM.StdControl;
  StatisticsM.SysTime -> msClockM;
}

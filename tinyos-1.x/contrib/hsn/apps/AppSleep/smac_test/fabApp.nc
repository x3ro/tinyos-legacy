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
includes config;     // include config.h first
                                                                                
configuration fabApp
{
  provides {
    interface StdControl;
  }
}

implementation
{
  components Main, fabAppM, TimerC, SysTimeC, SMAC, 
#ifdef MEASURE_STATS
	StatisticsC, 
#endif
   LedsC;

// SMAC
  fabAppM.MACControl -> SMAC;
  fabAppM.MACComm -> SMAC;
//  fabAppM.LinkState -> SMAC
  fabAppM.MACTest -> SMAC;

// End SMAC
  StdControl = fabAppM;

#ifdef MEASURE_STATS
  fabAppM -> StatisticsC.RetreiveStatistics;
  fabAppM.ReportPacketEvent -> StatisticsC.ReportPacketEvent;
#endif

  Main.StdControl -> fabAppM.StdControl;
  fabAppM.WakeUpTimer -> TimerC.Timer[unique("Timer")];
  fabAppM.TimeSynch -> TimerC.Timer[unique("Timer")];
  fabAppM.Leds -> LedsC;
  fabAppM.SysTime -> SysTimeC;
}


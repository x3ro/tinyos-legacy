/*
 * Copyright (c) 2009, Shimmer Research, Ltd.
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of Shimmer Research, Ltd. nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors: Steve Ayer
 *          September, 2009
 */

includes FatFs;

configuration JustFATLogging {
}
implementation {
  components 
    Main, 
    JustFATLoggingM, 
    FatFsM,
    DMA_M, 
    diskIOC,
    AccelC,
    TimerC, 
    LedsC, 	
    PowerSupplyMonitorC,
    TimeM,
    ID_CHIP;



  Main.StdControl->JustFATLoggingM;
  Main.StdControl->TimerC;
  Main.StdControl->TimeM;

  /* have to fix compile time channel limitation */
  JustFATLoggingM.DMA0         -> DMA_M.DMA[0];
  JustFATLoggingM.Leds         -> LedsC;
  JustFATLoggingM.sampleTimer       -> TimerC.Timer[unique("Timer")];
  JustFATLoggingM.warningTimer       -> TimerC.Timer[unique("Timer")];
 
  JustFATLoggingM.AccelStdControl   -> AccelC;
  JustFATLoggingM.Accel             -> AccelC;

  JustFATLoggingM.FatFs     -> FatFsM;
  FatFsM.diskIO             -> diskIOC;
  FatFsM.diskIOStdControl   -> diskIOC;

  JustFATLoggingM.PSMStdControl -> PowerSupplyMonitorC;
  JustFATLoggingM.PowerSupplyMonitor -> PowerSupplyMonitorC;

  JustFATLoggingM.Time          -> TimeM;
  
  // we're writing this for shimmer*, so skipping the ifdef...
  JustFATLoggingM.IDChip     -> ID_CHIP;

  TimeM.Timer                -> TimerC.Timer[unique("Timer")];
  TimeM.LocalTime            -> TimerC;
}

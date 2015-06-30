/*
 * Copyright (C) 2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye
 *
 * TimerTest tests the basic functions of the timer with CPU sleep
 */

includes config;     // include config.h first

configuration TimerTest {
}
implementation {
  components Main, TimerTestM, TimerC, LocalTimeC, PhyRadio, RandomLFSR, 
             HPLPowerManagementM, LedsC;

  Main.StdControl -> TimerTestM.StdControl;
  TimerTestM.TimerControl -> TimerC;
  TimerTestM.TimerRepeat -> TimerC.Timer[unique("Timer")];
  TimerTestM.TimerAsyncRepeat -> TimerC.TimerAsync[unique("Timer")];
  TimerTestM.TimerAry -> TimerC.Timer;
  TimerTestM.TimerAsyncAry -> TimerC.TimerAsync;
  TimerTestM.LocalTime -> LocalTimeC;
  TimerTestM.PhyControl -> PhyRadio;
  TimerTestM.Leds -> LedsC;
  TimerTestM.Random -> RandomLFSR;
}


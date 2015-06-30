// $Id: TinySchedulerC.nc,v 1.1.1.1 2007/11/05 19:11:28 jpolastre Exp $
/*
 * "Copyright (c) 2005 The Regents of the University  of California.
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
 */

/**
 * The TinyOS scheduler. It provides two interfaces: Scheduler,
 * for TinyOS to initialize and run tasks, and TaskBasic, the simplext
 * class of TinyOS tasks (reserved always at-most-once posting,
 * FIFO, parameter-free). For details and information on how to
 * replace the scheduler, refer to TEP 106.
 *
 * @author  Phil Levis
 * @date    August 7 2005
 */

#include "TinyScheduler.h"

configuration TinySchedulerC {
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
#ifdef MEASURE_MCU_ACTIVE_TIME
  provides interface Counter<T32khz,uint32_t> as McuActiveTime;
#endif//MEASURE_MCU_ACTIVE_TIME
}
implementation {
  components SchedulerBasicP as Sched;
#ifdef MEASURE_MCU_ACTIVE_TIME
  components Counter32khzC;
#endif//MEASURE_MCU_ACTIVE_TIME

  Scheduler = Sched;
  TaskBasic = Sched;
#ifdef MEASURE_MCU_ACTIVE_TIME
  McuActiveTime = Sched;
  Sched.LocalTime -> Counter32khzC;
#endif//MEASURE_MCU_ACTIVE_TIME
}


/*
 * Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
/*
 * Signals instead of callbacks from the BTTaskScheduler
 */


includes bt; /* Various structs, etc. */
includes BTTaskScheduler;

/**
 * TaskSchedulerSig interface.
 *
 * <p>The purpose of a TaskScheduler is to have events that handles
 * TaskScheduled tasks.</p> */
interface BTTaskSchedulerSig {
  /**
   * Called when a task is ready to run.
   * 
   * <p>Any actions that needs to take place when the task starts
   * running should be performed as a result of this event.</p>
   *
   * @param ev the event that was scheduled
   * @param currentTick the current tick
   * @param handled set this to true, if you handle this event */
  event void beginTask(TopoEvent * ev, int currentTick, bool * handled); 

  /**
   * Called when a task is done running.
   *
   * <p>Any actions that needs to take place when the task ends
   * running should be performed as a result of this event.</p>
   *
   * @param ev the event that was scheduled
   * @param currentTick the current tick
   * @param handled set this to true, if you handle this event. NB, if you 
   *        handle this event, you are responsible for freeing it. If not, leave
   *        it be. */
  event void endTask(TopoEvent * ev, int currentTick, bool * handled); 
}


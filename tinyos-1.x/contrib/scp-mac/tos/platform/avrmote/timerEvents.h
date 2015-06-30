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
 * this file defines the events in timer for debugging
 */

#ifndef TIMER_EVENTS
#define TIMER_EVENTS

#define INIT_EVENT_NO 5

#define NEW_TIMER_STARTED (INIT_EVENT_NO)
#define ONE_TIMER_STOPPED (NEW_TIMER_STARTED + 1)
#define ALL_TIMERS_STOPPED (ONE_TIMER_STOPPED + 1)
#define ONE_TIMER_CHANGED_REMAINING_TIME (ALL_TIMERS_STOPPED + 1)
#define ONE_ASYNC_TIMER_FIRED (ONE_TIMER_CHANGED_REMAINING_TIME + 1)
#define TIMER_FIRED_TASK_QUEUE_FULL (ONE_ASYNC_TIMER_FIRED + 1)
#define ONE_TASK_TIMER_FIRED (TIMER_FIRED_TASK_QUEUE_FULL + 1)

#endif // LPL_EVENTS

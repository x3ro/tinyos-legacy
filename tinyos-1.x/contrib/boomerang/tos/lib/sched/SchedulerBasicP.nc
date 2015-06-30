// $Id: SchedulerBasicP.nc,v 1.1.1.1 2007/11/05 19:11:28 jpolastre Exp $

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
/*
 *
 * Authors:		Philip Levis
 * Date last modified:  $Id: SchedulerBasicP.nc,v 1.1.1.1 2007/11/05 19:11:28 jpolastre Exp $
 *
 */

/**
 * SchedulerBasic implements the default TinyOS scheduler sequence, as
 * documented in TEP 106.
 *
 * @author Philip Levis
 * @author Cory Sharp
 * @date   January 19 2005
 */

#include "hardware.h"

module SchedulerBasicP {
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
#ifdef MEASURE_MCU_ACTIVE_TIME
  provides interface Counter<T32khz,uint32_t> as McuActiveTime;
  uses interface LocalTime<T32khz>;
#endif//MEASURE_MCU_ACTIVE_TIME
}
implementation {
  enum {
    NUM_TASKS = uniqueCount("TinySchedulerC.TaskBasic"),
    NONE = 255,
  };

  uint8_t m_head;
  uint8_t m_tail;
  uint8_t m_next[NUM_TASKS];

#ifdef MEASURE_MCU_ACTIVE_TIME
  bool m_isactive;
  uint32_t m_laston;
  uint32_t m_activetime;

  // Keep track of how long the microcontroller/scheduler is active for power
  // management purposes.  Uses the Counter interface to provide overflow
  // events.

  async command uint32_t McuActiveTime.get() {
    return m_activetime;
  }

  async command bool McuActiveTime.isOverflowPending() {
    return FALSE;
  }

  async command void McuActiveTime.clearOverflow() {
  }

  default async event void McuActiveTime.overflow() {
  }
#endif//MEASURE_MCU_ACTIVE_TIME


  // Helper functions (internal functions) intentionally do not have atomic
  // sections.  It is left as the duty of the exported interface functions to
  // manage atomicity to minimize chances for binary code bloat.

  bool isQueued( uint8_t id ) {
    return (m_next[id] != NONE) || (m_tail == id);
  }

  // move the head forward
  // if the head is at the end, mark the tail at the end, too
  // mark the task as not in the queue
  uint8_t popTask() {
    uint8_t id = m_head;
    if( id != NONE ) {
      m_head = m_next[id];
      if( m_head == NONE )
	m_tail = NONE;
      m_next[id] = NONE;
    }
    return id;
  }
  
  bool pushTask( uint8_t id ) {
    if( (m_next[id] == NONE) && (m_tail != id) ) {
      if( m_head == NONE ) {
	m_head = id;
	m_tail = id;
      }
      else {
	m_next[m_tail] = id;
	m_tail = id;
      }
      return TRUE;
    }
    else {
      return FALSE;
    }
  }
  
  bool pushFront( uint8_t id ) {
    if( !isQueued(id) ) {
      m_next[id] = m_head;
      m_head = id;
      if( m_tail == NONE )
        m_tail = id;
      return TRUE;
    }
    else {
      return FALSE;
    }
  }


  command void Scheduler.init() {
    atomic {
      uint8_t* n = m_next;
      while( n != (m_next+sizeof(m_next)) )
        *n++ = NONE;
      m_head = NONE;
      m_tail = NONE;
    }
  }

  command bool Scheduler.runNextTask( bool sleep ) {
    uint8_t nextTask;
    atomic {
#ifdef MEASURE_MCU_ACTIVE_TIME
      // increment the active time with each task, check for overflow
      uint32_t now = call LocalTime.get();
      if( m_isactive ) {
        uint32_t oldactivetime = m_activetime;
        m_activetime += now - m_laston;
        if( m_activetime < oldactivetime )
          signal McuActiveTime.overflow();
      }
      else {
        m_isactive = TRUE;
      }
      m_laston = now;
#endif//MEASURE_MCU_ACTIVE_TIME
        
      nextTask = popTask();
      if( nextTask == NONE ) {
	if( sleep ) {
#ifdef MEASURE_MCU_ACTIVE_TIME
          m_isactive = FALSE;
#endif//MEASURE_MCU_ACTIVE_TIME
	  __nesc_atomic_sleep();
	}
	return FALSE;
      }
    }
    signal TaskBasic.runTask[nextTask]();
    return TRUE;
  }

  /**
   * The task will always be enqueued after postTask, return SUCCESS.
   */
  async command result_t TaskBasic.postTask[uint8_t id]() {
    atomic pushTask(id);
    return SUCCESS;
  }

  async command result_t TaskBasic.postUrgentTask[uint8_t id]() {
    atomic pushFront(id);
    return SUCCESS;
  }

  default event void TaskBasic.runTask[uint8_t id]() {
  }
}


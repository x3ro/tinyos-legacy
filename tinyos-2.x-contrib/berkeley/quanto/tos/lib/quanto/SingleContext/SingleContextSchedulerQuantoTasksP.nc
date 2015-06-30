// $Id: SingleContextSchedulerQuantoTasksP.nc,v 1.1 2009/02/14 00:13:36 rfonseca76 Exp $

/*                                                                        tab:4
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

/**
 * This is a modification of SingleContextSchedulerBasicP to add a
 * low priority task queue, that only gets executed once the normal
 * priority task queue is empty. This is primarily used for logging.
 * Low priority tasks will execute in FIFO order, only when the
 * processor would be idle otherwise.
 */

 /* This is a modification of SchedulerBasicP to keep track of execution
 * activities across task postings and executions. We create an
 * array of activities of the same size as the array of tasks. For
 * each task posted we keep the activity that was active in the
 * CPUContext at the time of posting, and restore it at the time of
 * calling the task.
 *
 * SchedulerBasicP implements the default TinyOS scheduler sequence, as
 * documented in TEP 106.
 *
 * @author Philip Levis
 * @author Cory Sharp
 * @author Rodrigo Fonseca (quanto activity tracking)
 * @date   February 3 2008
 */

#include "hardware.h"
#include "activity.h"

module SingleContextSchedulerQuantoTasksP @safe() {
  provides interface Scheduler;
  provides interface TaskBasic[uint8_t id];
  provides interface TaskQuanto[uint8_t id];
  uses interface McuSleep;

  uses interface Init as InitContext;
  uses interface Init as InitPowerState;
  uses interface SingleContext as CPUContext;
}
implementation
{
  enum
  {
    NUM_TASKS = uniqueCount("TinySchedulerC.TaskBasic"),
    NUM_TASKS_Q = uniqueCount("TinySchedulerC.TaskQuanto"),
    NO_TASK = 255,
  };


  volatile uint8_t m_head;
  volatile uint8_t m_tail;
  volatile uint8_t m_next[NUM_TASKS];
  volatile act_t m_act[NUM_TASKS];  //Quanto: activity of each task

  volatile uint8_t m_q_head;
  volatile uint8_t m_q_tail;
  volatile uint8_t m_q_next[NUM_TASKS_Q];
  volatile act_t m_q_act[NUM_TASKS_Q]; //Quanto: activity of each task

  volatile bool m_wokeup;         //have we just woken up from an interrupt?

  // Helper functions (internal functions) intentionally do not have atomic
  // sections.  It is left as the duty of the exported interface functions to
  // manage atomicity to minimize chances for binary code bloat.

  // move the head forward
  // if the head is at the end, mark the tail at the end, too
  // mark the task as not in the queue
  inline uint8_t popTask()
  {
    if( m_head != NO_TASK )
    {
      uint8_t id = m_head;
      m_head = m_next[m_head];
      if( m_head == NO_TASK )
      {
        m_tail = NO_TASK;
      }
      m_next[id] = NO_TASK;

      // If this is the first time after a wakeup, then
      // we wokeup from idle. If the interrupt scheduled a
      // task, then we should exit the interrupt to the task,
      // and not to idle. m_wokeup will be false if this is
      // not waking up, but rather walking the task queue.
      if (m_wokeup) {
        call CPUContext.exitInterrupt(m_act[id]);
        m_wokeup = FALSE;
      }
      else {
        call CPUContext.set(m_act[id]);
      }
      m_act[id] = ACT_INVALID;

      return id;
    }
    else
    {
      //If nothing else to do, don't set the idle activity here
      //as we have yet to check the low priority queue
      //if (m_wokeup) {
      //  call CPUContext.exitInterruptIdle();
      //  m_wokeup = FALSE;
      //} else {
      //  call CPUContext.setIdle();
      //}
      return NO_TASK;
    }
  }
  
  bool isWaiting( uint8_t id )
  {
    return (m_next[id] != NO_TASK) || (m_tail == id);
  }

  bool pushTask( uint8_t id )
  {
    if( !isWaiting(id) )
    {
      if( m_head == NO_TASK )
      {
        m_head = id;
        m_tail = id;
      }
      else
      {
        m_next[m_tail] = id;
        m_tail = id;
      }
      m_act[id] = call CPUContext.get();
      return TRUE;
    }
    else
    {
      return FALSE;
    }
  }
  
  // Queue functions for the low priority queue: note that they
  // share m_wokeup

  // move the head forward
  // if the head is at the end, mark the tail at the end, too
  // mark the task as not in the queue
  inline uint8_t popQTask()
  {
    if( m_q_head != NO_TASK )
    {
      uint8_t id = m_q_head;
      m_q_head = m_q_next[m_q_head];
      if( m_q_head == NO_TASK )
      {
        m_q_tail = NO_TASK;
      }
      m_q_next[id] = NO_TASK;

      // If this is the first time after a wakeup, then
      // we wokeup from idle. If the interrupt scheduled a
      // task, then we should exit the interrupt to the task,
      // and not to idle. m_wokeup will be false if this is
      // not waking up, but rather walking the task queue.
      if (m_wokeup) {
        call CPUContext.exitInterrupt(m_q_act[id]);
        m_wokeup = FALSE;
      }
      else {
        call CPUContext.set(m_q_act[id]);
      }
      m_q_act[id] = ACT_INVALID;

      return id;
    }
    else
    {
      //If we have nothing left to do here, then we should
      //set the CPU activity to idle
      if (m_wokeup) {
        call CPUContext.exitInterruptIdle();
        m_wokeup = FALSE;
      } else {
        call CPUContext.setIdle();
      }
      return NO_TASK;
    }
  }
  
  bool isQWaiting( uint8_t id )
  {
    return (m_q_next[id] != NO_TASK) || (m_q_tail == id);
  }

  bool pushQTask( uint8_t id , act_t act)
  {
    if( !isQWaiting(id) )
    {
      if( m_q_head == NO_TASK )
      {
        m_q_head = id;
        m_q_tail = id;
      }
      else
      {
        m_q_next[m_q_tail] = id;
        m_q_tail = id;
      }
      m_q_act[id] = act;
      return TRUE;
    }
    else
    {
      return FALSE;
    }
  }
 

  command void Scheduler.init()
  {
    int i;
    atomic
    {
      memset( (void *)m_next, NO_TASK, sizeof(m_next) );
      m_head = NO_TASK;
      m_tail = NO_TASK;
      
      for (i = 0; i < NUM_TASKS; i++)
        m_act[i] = ACT_INVALID;

      memset( (void *)m_q_next, NO_TASK, sizeof(m_q_next) );
      m_q_head = NO_TASK;
      m_q_tail = NO_TASK;
 
      for (i = 0; i < NUM_TASKS_Q; i++)
        m_q_act[i] = ACT_INVALID;
    }
    call InitContext.init();
    call InitPowerState.init();
  }
  
  command bool Scheduler.runNextTask()
  {
    uint8_t nextTask;
    act_t c = call CPUContext.get();
    m_wokeup = FALSE;
    atomic
    {
      nextTask = popTask();
      if( nextTask == NO_TASK )
      {
        nextTask = popQTask();
        if (nextTask == NO_TASK) {
          call CPUContext.set(c);
          return FALSE;
        }

        signal TaskQuanto.runTask[nextTask]();
        call CPUContext.set(c);
        return TRUE;       
      }
    }
    signal TaskBasic.runTask[nextTask]();
    call CPUContext.set(c);
    return TRUE;
  }

  command void Scheduler.taskLoop()
  {
    for (;;)
    {
      uint8_t nextTask = NO_TASK;
      uint8_t nextQTask = NO_TASK;

      atomic
      {
        while ((nextTask = popTask()) == NO_TASK &&
               (nextQTask = popQTask()) == NO_TASK)
        {
          call McuSleep.sleep();
          m_wokeup = TRUE;
        }
      }
      if (nextTask != NO_TASK) {
        signal TaskBasic.runTask[nextTask]();
      } else if (nextQTask != NO_TASK) {
        signal TaskQuanto.runTask[nextQTask]();
      }
    }
  }

  /**
   * Return SUCCESS if the post succeeded, EBUSY if it was already posted.
   */
  
  async command error_t TaskBasic.postTask[uint8_t id]()
  {
    atomic { return pushTask(id) ? SUCCESS : EBUSY; }
  }

  async command error_t TaskQuanto.postTask[uint8_t id](act_t act)
  {
    atomic { return pushQTask(id, act) ? SUCCESS : EBUSY; }
  }

  default event void TaskBasic.runTask[uint8_t id]()
  {
  }
  
  default event void TaskQuanto.runTask[uint8_t id]()
  {
  }

}


// $Id: TaskSchedM.nc,v 1.3 2004/10/14 08:39:31 cssharp Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// @author Cory Sharp <cssharp@eecs.berkeley.edu>

includes TaskControl;

module TaskSchedM
{
  provides interface TaskControl;
  provides interface TaskSched[uint8_t id];
}
implementation
{
  enum
  {
    NUM_TASKS = uniqueCount("TaskSched"),
    END_TASK = 255,
  };

  uint8_t m_head;
  uint8_t m_tail;
  uint8_t m_next[NUM_TASKS];

  void flushTasks()
  {
    uint8_t* ii;
    for( ii = m_next; ii != m_next+NUM_TASKS; ii++ )
      *ii = END_TASK;
    m_head = END_TASK;
    m_tail = END_TASK;
  }


  bool isWaiting( uint8_t id )
  {
    return (m_next[id] != END_TASK) || (m_tail == id);
  }


  uint8_t popTask()
  {
    if( m_head != END_TASK )
    {
      uint8_t id = m_head;

      // move the head forward
      // if the head is at the end, mark the tail at the end, too
      // mark the task as not in the queue

      m_head = m_next[m_head];

      if( m_head == END_TASK )
	m_tail = END_TASK;

      m_next[id] = END_TASK;

      return id;
    }

    return END_TASK;
  }

  void pushTask( uint8_t id )
  {
    if( !isWaiting(id) )
    {
      if( m_head == END_TASK )
      {
	m_head = id;
	m_tail = id;
      }
      else
      {
	m_next[m_tail] = id;
	m_tail = id;
      }
    }
  }

  async command bool TaskSched.isWaiting[uint8_t id]()
  {
    bool b;
    atomic { b = isWaiting(id); }
    return b;
  }

  async command void TaskSched.queue[uint8_t id]()
  {
    atomic { pushTask(id); }
  }

  default event void TaskSched.fired[uint8_t id]()
  {
  }


  command void TaskControl.init()
  {
    atomic { flushTasks(); }
  }

  command tasksched_t TaskControl.runOneTask()
  {
    uint8_t id;
    atomic { id = popTask(); }

    if( id != END_TASK )
    {
      signal TaskSched.fired[id]();
      return RAN_TASK;
    }

    return NO_TASKS;
  }

/*
  command void TaskControl.flushTasks()
  {
    atomic { flushTasks(); }
  }
*/
}


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
 * Based on the Blueware file bt-taskscheduler.cc. Heavily modified. 
 */
includes bt;
includes BTTaskScheduler;
/**
 * This module provides an implementation of the BTTaskScheduler interface. */
module BTTaskSchedulerM {
  uses {
    interface BTHost; /* To get access to hciGetBdAddr() and friends - 
			 this will probably be supplied by the HCICore module. */
    interface BTBaseband; /* Ditto */
  }
  provides {
    interface BTTaskScheduler;
    interface BTTaskSchedulerSig;
  }
  // TODO: Provide a task scheduler interface???
  
} /* module */
implementation {
  /** All the tasks. Used to be a map <int, HostTask>. These are
      apparently supposed to be sorted after the first field, which is
      a duplicate(?) of second->start_. I am not sure if there is a
      deeper meaning with using a map? After all, this code was
      written by folks at IBM, then MIT...? */
  tasks_t tasks_;
  
  /** The current task? TODO! */
  HostTask * curr_task;

  /** Initalize the TaskScheduler */
  command result_t BTTaskScheduler.init() {
    dbg(DBG_USR1, "TaskScheduler::init()\n");
    list_init(&tasks_.link);
    curr_task = NULL;
    return SUCCESS;
  }

  /* **********************************************************************
   * adjustTimer
   * *********************************************************************/
  void adjustTimer() {
#ifdef NEVER
    Scheduler& s = Scheduler::instance();
    s.cancel(&intr_);
    if(tasks_.begin() != tasks_.end()) {
      HostTask* tsk = tasks_.begin()->second;
      double delay = (tsk->start_ - host_->lm()->clkn()) * ClockTick;
      TRACE_BT(LEVEL_SCHED, "_%d_ adjustTimer CLKN %d %s %4.4f\n",
	       host_->hciGetBdAddr(),  host_->lm()->clkn(), tsk->toString(), delay);
      s.schedule(this, &intr_, max(0.0, delay));
    }
#endif
    dbg(DBG_USR1, "BTTaskSchedulerM.adjustTimer called - unimplemented\n");
  } 
  
  /* **********************************************************************
   * schedule
   * *********************************************************************/
  /** Schedule a task */

  /* Note to anybody reading this code: As most other code in the PC
  bluetooth support, this was adapted from the Bluehoc/Blueware c++
  sources. There are so many things I do not understand about this
  code. E.g. the split between locating the start time, and inserting
  it in order, etc, etc. I have tried to make the code correct,
  without trying to "improve" it. Although I think there is plenty of
  room for improvement. (MBD, Sep. 2003) */

  command HostTask * 
    BTTaskScheduler.schedule(task_type type, int  duration, /* Handler* h, */
			     TopoEvent* e, int offset, int minDur, int slack) { 
    /* Variables used for iteration */
    list_link_t * begin;
    list_link_t * mylink;
    tasks_t * foo;
    // int prevFinish = host_->lm()->clkn();
    int prevFinish = call BTBaseband.clkn();
    int start = prevFinish + offset;
    //  map<int, HostTask*>::iterator it, begin;

    /* Allocate and set up a new HostTask */
    // HostTask* tsk = new HostTask();
    HostTask* tsk = new_HostTask();

    TRACE_BT(LEVEL_FUNCTION, 
	     "%s(type=%d, dur=%d, ev=%p, offset=%d, mindur=%d, slack=%d)\n", 
	     __FUNCTION__, type, duration, e, offset, minDur, slack);

    // tsk->handler_ = h;
    tsk->ev_      = e; 
    tsk->type_    = type;
    // tsk->sched_   = this; <<- TODO
    
    /* Hmm. I think you can supply a minimum duration ? */
    if(minDur == -1)
      minDur = duration;
    
    // TRACE_BT(LEVEL_SCHED, "_%d_ SCHEDULE: NUM TASKS %-6d CLKN %-6d\n", 
    // host_->hciGetBdAddr(), tasks_.size(), host_->lm()->clkn());
    TRACE_BT(LEVEL_SCHED, "_%d_ SCHEDULE: NUM TASKS %-6d CLKN %-6d\n", 
	     call BTHost.hciGetBdAddr(), list_size(&tasks_.link), 
	     call BTBaseband.clkn());
#ifdef NEVER
    for(begin = it = tasks_.begin(); it != tasks_.end(); it++) {
      TRACE_BT(LEVEL_SCHED, "_%d_ %s\n", host_->hciGetBdAddr(), 
	       it->second->toString());
      if(it->second->start_ - start >= minDur) {
	break;
      }
      
      if(start < it->second->finish_) // to cater for offset
	start = it->second->finish_;
      prevFinish = it->second->finish_;;
    }
#endif
    /* Iterate over the task list, to find the correct place to insert
       this task */
    begin = tasks_.link.l_next;
    for (mylink = tasks_.link.l_next; 
	 mylink != &(tasks_.link); 
	 mylink = mylink->l_next) {
      foo = (tasks_t *) mylink;
      // TRACE_BT(LEVEL_SCHED, "_%d_ %s\n", call
      // BTHost.hciGetBdAddr(), link->second->toString());
      TRACE_BT(LEVEL_SCHED, "_%d_ %s\n", call BTHost.hciGetBdAddr(), 
	       HostTask_toString(((tasks_t*)mylink)->second));
      if( foo->second->start_ - start >= minDur) {
	break;
      }
      
      if(start < foo->second->finish_) // to cater for offset
	start = foo->second->finish_;
      prevFinish = foo->second->finish_;
    }
    

    /* move it forward if the gap between the previous task and this
       one is <= slack */
    if(prevFinish != start && start - prevFinish <= slack) {
      TRACE_BT(LEVEL_HIGH, 
	       "_%d_ MOVING FORWARD TASK TO CLOSE THE GAP: OLD %d NEW %d\n", 
	       call BTHost.hciGetBdAddr(), start, prevFinish);
      start = prevFinish;
    }
    tsk->start_ = start;
    //tsk->finish_ = prevFinish + duration;

#ifdef NEVER
    tsk->finish_ = start 
      + min(duration, (it == tasks_.end()) ? duration : it->second->start_ 
	    - start);

    if(tsk->finish_ < tsk->start_)
      ASSERT(0);

    tasks_.insert(make_pair(start, tsk));
    if(tasks_.begin() != begin)
      adjustTimer();
    TRACE_BT(LEVEL_SCHED, "_%d_ SCHED TASK: CLKN %-6d %s\n",
	     host_->hciGetBdAddr(), host_->lm()->clkn(), tsk->toString());
    return tsk;
#endif
    /* TODO: This may break (== test) */
    /* Set the finish time of the task. If it is the last task, set it
       to start + duration. Otherwise, if there is less ticks than
       duration to the start of the task following this task, set
       finish to the start of the following task. */
    // tsk->finish_ = start + min(duration, (mylink == &(tasks_.link)) ? duration 
    //: link->second->start_ - start);
    // if (mylink == &(tasks_.link) && // end
    // !list_empty(&(tasks_.link))) { 
    if (mylink == &(tasks_.link)) { // end OR empty list. (I hope).
      tsk->finish_ = start + duration;
    } else {
      tsk->finish_ = start 
	+ min(duration, 
	      // ((tasks_t *) mylink->l_prev)->second->start_);
	      ((tasks_t *) mylink)->second->start_ - start);
    }
    
    
    if(tsk->finish_ < tsk->start_)
      assert(0);

    /* Insert the task at the right place in the task list */
    tasks_t_insert_sorted(&tasks_, start, tsk);
    
    /* If the first element to be posted have changed, adjust the timer */
    if(tasks_.link.l_next != begin)
      adjustTimer(); 
    TRACE_BT(LEVEL_SCHED, "_%d_ SCHED TASK: CLKN %-6d %s\n",
	     call BTHost.hciGetBdAddr(), call BTBaseband.clkn(), 
	     HostTask_toString(tsk));
    return tsk;
  } /* schedule */



  /* **********************************************************************
   * handleFirstTask
   * *********************************************************************/
  /**
   * Handle the first task in the queue.
   *
   * <p>Handle the first task in the task queue. That is, runs the
   * event handler, etc. Also sets the curr_task to this task.</p>
   *
   * @param currentTick the current tick */
  void handleFirstTask(int currentTick) {
    bool handled = FALSE;
    dbg(DBG_BT, "BTTaskScheduler.handleFirstTask\n");
    assert(curr_task == NULL);
    assert(list_size(&(tasks_.link)) > 0);
    curr_task               = ((tasks_t *) tasks_.link.l_next)->second;
    curr_task->ev_->status_ = TASK_BEGIN;
    signal BTTaskSchedulerSig.beginTask(curr_task->ev_, currentTick, &handled);
    if (!handled) {
      dbg(DBG_BT, "Error: BTTaskScheduler: Unhandled task after beginTask\n");
      assert(0);
    }
  }

  /* **********************************************************************
   * removeTask
   * *********************************************************************/
  /**
   * removeTask.
   *
   * <p>Remove the task tsk, setting its status to status. The event
   * handler, if present, is called. If curr_task is == tsk, then
   * curr_task is set to NULL.</p>
   *
   * @param currentTick the current tick
   * @param tsk the task to remove. Nb, caller must deallocate (with
   *            <code>delete_tasks_t</code>)
   * @param status the status of the task, set before calling the handler */
  void removeTask(int currentTick, tasks_t * tsk, task_status status) {
    bool bAdjust = FALSE;
    bool handled = FALSE;
    TRACE_BT(LEVEL_SCHED, "_%d_ REMOV TASK: CLKN %-6d %s STATUS %d\n",
	     call BTHost.hciGetBdAddr(), call BTBaseband.clkn(), 
	     HostTask_toString(tsk->second), status);

    /* Signals the endTask event */
    signal BTTaskSchedulerSig.endTask(tsk->second->ev_, currentTick, &handled);
    if (handled == TRUE) {
      tsk->second->ev_ = NULL;
    } else {
      dbg(DBG_BT, "Error: BTTaskScheduler: Unhandled task after endTask\n");
      assert(0);
    }

    /* If this is the first task... */
    if(tsk == (tasks_t*)tasks_.link.l_next) {
      bAdjust = TRUE;
    }

    
    list_remove(&(tsk->link));
    
    if(bAdjust) {
      curr_task = NULL;
      adjustTimer();
    }
  };

  /* **********************************************************************
   * checkTasks
   * *********************************************************************/
  /**
   * Check any running task, and the task queue.
   *
   * @todo This could probably be an event from the HCICore...
   *
   * <p>Checks if we have a running task, in that case, checks if it is done.
   * Then checks if we can schedule a new one.</p>
   *
   * @param currentTick the current global tick count */
  command void BTTaskScheduler.checkTasks(int currentTick) {
    dbg(DBG_USR2, "BTTaskScheduler.checkTasks(%d)\n", currentTick);
    
    /* Check if the running task is done... */
    if (curr_task) {
      if (curr_task->finish_ <= currentTick) {
	assert(!list_empty(&(tasks_.link)));
	removeTask(currentTick, (tasks_t *) (tasks_.link.l_next), TASK_END);
	// curr_task = NULL; /* Done in removeTasks */
      }
    }
    
    /* Check if we need to schedule a new task */
    if (!curr_task) {
      if (list_empty(&(tasks_.link))) {
	dbg(DBG_USR2, "No tasks\n");
      } else {
	int first = ((tasks_t *) (tasks_.link.l_next))->first;
	dbg(DBG_USR2, "Next schedule ready in %d\n", first - currentTick);
	if (first < currentTick) { /* TODO: We miss the first tick. Does
				      it matter? */
	  handleFirstTask(currentTick);
	}
      }
    }
  } /* checkTasks */
  
} /* implementation */





























#ifdef NEVER
#include <bt-core.h>


char TaskScheduler::buf[BUF_LEN];
char HostTask::buf[BUF_LEN];
char TaskEvent::buf[BUF_LEN];


static class TaskSchedulerClass : public TclClass 
{
 public:
	TaskSchedulerClass() : TclClass("TaskScheduler"){}
	TclObject* create( int, const char*const*) {
	 	return ( new TaskScheduler );
	}
} class_taskscheduler;


TaskScheduler::TaskScheduler() : curr_task_(NULL)
{
}

int
TaskScheduler::lastFinishTime() const
{
	if(tasks_.rbegin() == tasks_.rend())
		return host_->lm()->clkn();
	return tasks_.rbegin()->second->finish_;
}

/* Schedule a new task of TYPE type for DURATION ticks. The task is scheduled at 
 * the earliest possible time after OFFSET ticks have passed. If MINDUR != -1, the duration of the 
 * task is between DURATION and MINDUR.*/
HostTask*  
TaskScheduler::schedule(task_type type, int duration, Handler* h, TaskEvent* e, int offset = 0, 
			int minDur = -1, int slack = 0)
{
	int prevFinish = host_->lm()->clkn();
	int start = prevFinish + offset;
	map<int, HostTask*>::iterator it, begin;
	HostTask* tsk = new HostTask();
	tsk->handler_ = h;
	tsk->ev_ = e; 
	tsk->type_ = type;
	tsk->sched_ = this;

	if(minDur == -1)
		minDur = duration;

	TRACE_BT(LEVEL_SCHED, "_%d_ SCHEDULE: NUM TASKS %-6d CLKN %-6d\n", 
		  host_->hciGetBdAddr(), tasks_.size(), host_->lm()->clkn());

      	for(begin = it = tasks_.begin(); it != tasks_.end(); it++) {
		TRACE_BT(LEVEL_SCHED, "_%d_ %s\n", host_->hciGetBdAddr(), it->second->toString());
		if(it->second->start_ - start >= minDur) {
			break;
		}

		if(start < it->second->finish_) // to cater for offset
			start = it->second->finish_;
		prevFinish = it->second->finish_;;
	}

	
	//if(prev != tasks_.end() && prev->second->finish_ != start) {
	if(prevFinish != start && start - prevFinish <= slack) {
		// move it forward if the gap between the previous task and this one is <= slack
		TRACE_BT(LEVEL_HIGH, "_%d_ MOVING FORWARD TASK TO CLOSE THE GAP: OLD %d NEW %d\n", 
			 host_->hciGetBdAddr(), start, prevFinish);
		start = prevFinish;
	}
	tsk->start_ = start;
	//tsk->finish_ = prevFinish + duration;
	tsk->finish_ = start + min(duration, (it == tasks_.end()) ? duration : it->second->start_ - start);

	if(tsk->finish_ < tsk->start_)
		ASSERT(0);
	

	tasks_.insert(make_pair(start, tsk));
	if(tasks_.begin() != begin)
		adjustTimer();
	TRACE_BT(LEVEL_SCHED, "_%d_ SCHED TASK: CLKN %-6d %s\n",
		  host_->hciGetBdAddr(), host_->lm()->clkn(), tsk->toString());
	return tsk;
}

/* Find the earliest availabe longest slot between START and FINISH. The task must have at least
 * DUR in length. */
HostTask*
TaskScheduler::scheduleHard(task_type type, Handler* h, TaskEvent* e, int start, int finish, int minDur)
{
	//int prevFinish = start = max(host_->lm()->clkn(), start);;
	if(!(start >= host_->lm()->clkn())) {
		TRACE_BT(LEVEL_LCS, "_%d_ TYPE %d START %d FIN %d CLKN %d %s\n", 
			  host()->hciGetBdAddr(), type, start, finish, host_->lm()->clkn(), e->toString());
		ASSERT(0);
	}
	int prevFinish = start;
	map<int, HostTask*>::iterator it, begin;
	HostTask* tsk = NULL;

	TRACE_BT(LEVEL_SCHED, "_%d_ SCHEDULEHARD: NUM TASKS %-6d CLKN %-6d\n", 
		  host_->hciGetBdAddr(), tasks_.size(), host_->lm()->clkn());
      	for(begin = it = tasks_.begin(); it != tasks_.end(); it++) {
		TRACE_BT(LEVEL_SCHED, "_%d_ %s\n", host_->hciGetBdAddr(), it->second->toString());
		// if the task can start no earlier than START and last for at least MINDUR
		if(start >= prevFinish && it->second->start_ >= start + minDur) {
			finish = min(it->second->start_, finish);
			break;
		}
		if(prevFinish < it->second->finish_) {// to cater for offset
			prevFinish = it->second->finish_;
			start = max(prevFinish, start);
		}
	}

	if(prevFinish + minDur <= finish) {
		ASSERT(!tsk);
		tsk = new HostTask();
		tsk->handler_ = h;
		tsk->ev_ = e; 
		tsk->type_ = type;
		tsk->start_ = max(start, prevFinish);
		tsk->finish_ = finish;
		tsk->sched_ = this;

		if(tsk->finish_ < tsk->start_)
			ASSERT(0);
		tasks_.insert(make_pair(tsk->start_, tsk));
		TRACE_BT(LEVEL_SCHED, "_%d_ SCHED TASK: CLKN %-6d %s\n",
			  host_->hciGetBdAddr(), host_->lm()->clkn(), tsk->toString());
	}

	if(tasks_.begin() != begin)
		adjustTimer();
	return tsk;
}

bool
TaskScheduler::cancel(HostTask* tsk)
{
	bool bRemoved = false;
	map<int, HostTask*>::iterator it = tasks_.find(tsk->start_);
	if(it != tasks_.end()) {
		ASSERT(tsk->equal(it->second));
		removeTask(it, TASK_CANCEL);
		bRemoved = true;
	}
	return bRemoved;
}

bool
TaskScheduler::cancel(TaskEvent* e, bool bAll = false)
{
	return cancelT(this, e, bAll);
}

/* Remove the first task of TYPE type found in TASKS. 
 * Should later adapt to use CANCEL(TaskEvent*) instead. */
bool
TaskScheduler::cancel(task_type type, bool bAll = false)
{
	ASSERT(type >= INQ_TSK && type < NUM_TSK);
	TopoEvent* e = new TopoEvent(type);
	bool res = cancel(dynamic_cast<TaskEvent*>(e), bAll);
	delete e;
	return res;
}

HostTask*
TaskScheduler::find(TaskEvent* e)
{
	return findT(this, e);
}

void
TaskScheduler::removeTask(map<int, HostTask*>::iterator it, task_status status)
{
	TRACE_BT(LEVEL_SCHED, "_%d_ REMOV TASK: CLKN %-6d %s STATUS %d\n",
		  host_->hciGetBdAddr(), host_->lm()->clkn(), it->second->toString(), status);
	if(it->second->handler_) {
		it->second->ev_->status_ = status;
		it->second->handler_->handle(it->second->ev_);
		//Scheduler::instance().cancel(&intr_);
	}
	bool bAdjust = false;
	if(it == tasks_.begin())
		bAdjust = true;
	delete it->second;
	tasks_.erase(it);

	if(bAdjust) {
		curr_task_ = NULL;
		adjustTimer();
	}
}

void
TaskScheduler::currTaskFinished() 
{
	if(tasks_.begin() == tasks_.end())
		ASSERT(0);
	removeTask(tasks_.begin(), TASK_END); // GT may not be right
	//adjustTimer();
}

/* It is time to invoke the appropriate handler for the first event in the queue. */
void
TaskScheduler::handle(Event* e)
{
	ASSERT(e == &intr_);
	HostTask* tsk = tasks_.begin()->second;
	if(curr_task_ != NULL)
		ASSERT(0);
	curr_task_ = tsk;
	tsk->ev_->status_ = TASK_BEGIN;
	//TRACE_BT(LEVEL_SCHED, "_%d_ BEGIN TASK: CLKN %-6d %s\n",
	//	  host_->hciGetBdAddr(), host_->lm()->clkn(), tsk->toString());
	tsk->handler_->handle(tsk->ev_);
}

void
TaskScheduler::adjustTimer()
{
	Scheduler& s = Scheduler::instance();
	s.cancel(&intr_);
	if(tasks_.begin() != tasks_.end()) {
		HostTask* tsk = tasks_.begin()->second;
		double delay = (tsk->start_ - host_->lm()->clkn()) * ClockTick;
		TRACE_BT(LEVEL_SCHED, "_%d_ adjustTimer CLKN %d %s %4.4f\n",
			  host_->hciGetBdAddr(),  host_->lm()->clkn(), tsk->toString(), delay);
		s.schedule(this, &intr_, max(0.0, delay));
	}
} 

Packet*
TaskScheduler::send(uchar ch)
{
  return NULL;
}

/* Begin firstTask() if it hasn't begun yet. currTask() must be NULL. 
 * This routine is used to sync THIS and other timers. */
void
TaskScheduler::beginFirstTask() 
{
	ASSERT(firstTask());
	ASSERT(currTask() == NULL);
	Scheduler::instance().cancel(&intr_);
	handle(&intr_); // begin task right away
}

HostTask*
TaskScheduler::firstTask() const
{
	if(tasks_.begin() == tasks_.end())
		return NULL;
	return tasks_.begin()->second;
}

HostTask*
TaskScheduler::getTask(int i) 
{
	map<int, HostTask*>::iterator it;
	unsigned int cnt = 0;
	for(it = tasks_.begin(); it != tasks_.end(); it++) {
		if((int)cnt == i)
			break;
		cnt++;
	}
	if(cnt >= tasks_.size())
		return NULL;
	return it->second;
}

/* Get the index of TSK in the list. -1 if TSK does not exist. */
int
TaskScheduler::getIndexOf(HostTask* tsk) 
{
	map<int, HostTask*>::iterator it;
	int ind = 0;
	for(it = tasks_.begin(); it != tasks_.end(); it++) {
		if(it->second == tsk)
			return ind;
		ind++;
	}
	return -1;
}

void
TaskScheduler::pollMissed(uchar ch)
{
}

const char*
TaskScheduler::toString() const 
{
	map<int, HostTask*>::const_iterator it; 
	int written = 0;
      	for(it = tasks_.begin(); it != tasks_.end(); it++) {
		written += snprintf(buf + written, BUF_LEN - written, "%s\n", it->second->toString());
	}
	return buf;
}

/* Return the gap between TSK and its preceding task, if bBegin == TRUE, or its
 * succeeding task, otherwise. -1 indicates that there is no task behind this task. */
int
TaskScheduler::gapBetweenTasks(HostTask* tsk, bool bBegin) 
{
	map<int, HostTask*>::iterator it = tasks_.find(tsk->start_);
	ASSERT(it != tasks_.end());
	if(bBegin) 
		it--;
	else
		it++;
	int gap = -1;
	if(it != tasks_.end()) {
		if(bBegin)
			gap = tsk->start_ - it->second->finish_;
		else
			gap = it->second->start_ - tsk->finish_;
	}
	return gap;
}

const char*
HostTask::toString(bool bNative = true) const
{
	if(bNative) {
		snprintf(buf, BUF_LEN, "[%13s %-6d (%-6d, %-6d) %-6s]", 
			 typeString(type_), mclkn_, start_, finish_, ev_->toString());
	}
	else {
	        Baseband* lm = sched_->host()->lm();
		snprintf(buf, BUF_LEN, "[%13s (%-6d, %-6d, %-3d) %-6s]", 
			 typeString(type_), (int)((start_ - lm->startClkn()) / 2.0), (int)((finish_ - lm->startClkn()) / 2.0), 
			 (int)((finish_-start_)/2.0), ev_->toString());
	}
	return buf;
}
#endif

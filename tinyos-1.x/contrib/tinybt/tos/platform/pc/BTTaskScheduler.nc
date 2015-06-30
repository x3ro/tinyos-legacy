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
 * Based on the Blueware file bt-taskscheduler.h. Heavily modified. 
 */


includes bt; /* Various structs, etc. */
includes BTTaskScheduler;

/**
 * TaskScheduler interface.
 *
 * <p>The purpose of a TaskScheduler is to schedule tasks that the
 * various components (baseband, LMP, etc) need to perform. In general
 * a task is registered with the TaskScheduler, which creates an
 * ordering based on the parameters passed when registering the
 * task.</p>
 *
 * <p>When a tasks arrival time occurs, the TaskScheduler signals on
 * the BTTaskSchedulerSig interface.</p>
 *
 * \todo I will need to update this ... */
interface BTTaskScheduler {
  // friend bool cancelT<TaskEvent>(TaskScheduler* tss, TaskEvent* e, bool bAll);
  // friend HostTask* findT<HostTask>(TaskScheduler* tss, HostTask* e);
  // friend HostTask* findT<TaskEvent>(TaskScheduler* tss, TaskEvent* e);
  
  // public:
  // const static int MinTaskLen = 4;
  
  // TaskScheduler();
  /** Initalize the TaskScheduler */
  command result_t init();
  // virtual HostTask*  schedule(task_type type, int duration, Handler* h, TaskEvent* e, int offset = 0, 
  // int minDur = -1, int slack = 0);
  /** Schecule a new task.
   * 
   * <p>Schedule a new task \a e of type \a type at the earliest
   * possible time after \a offset ticks have passed. The task have a
   * duration of \a duration ticks. If \a mindur != -1 the duration of
   * the task is between \a duration and \a mindur ticks.</p>
   * 
   * \param type the type of task to schedule
   * \param duration this is the upper limit for the tasks duration
   * \param h the handler??? TODO: What is this. It appears it is a
   *          class that supports a single "void handle(Event * e)" function.
   * \param e the event to schedule (this is the task, really).
   * \param offset do not schedule the task to run before offset ticks
   *               have passed. Use a default of 0.
   * \param minDur this is the lower limit for the tasks duration. Use
   *               -1 for unknown (duration will be assumed)
   * \param slack TODO: No clue... (default: 0)
   * \return a pointer to the HostTask that was allocted */
  command HostTask * schedule(task_type type, int duration, TopoEvent * e, 
			      int offset, int minDur, int slack);


  /**
   * Check any running task, and the task queue.
   *
   * @todo This could probably be an event from the HCICore...
   *
   * <p>Checks if we have a running task, in that case, checks if it is done.
   * Then checks if we can schedule a new one.</p>
   *
   * @param currentTick the current global tick count (tick == 312.5 usec)*/
  command void checkTasks(int currentTick);
}



#ifdef NEVER
	// virtual HostTask*  scheduleHard(task_type type, Handler* h, TaskEvent* e, int start, int finish, int minDur);
	/** Perform a hard schedule */
	HostTask * scheduleHard(task_type type, Handler* h, TaskEvent* e, int start, int finish, int minDur);

	virtual bool       cancel(HostTask* tsk);
	virtual bool       cancel(TaskEvent* ev, bool bAll = false);
	virtual bool       cancel(task_type ty, bool bAll = false);

	virtual HostTask*  find(TaskEvent* ev);

	virtual Packet*    send(uchar ch);
	virtual void       pollMissed(uchar ch);

	virtual void       handle(Event* e);
	void               beginFirstTask();
	int                lastFinishTime() const;
	int                gapBetweenTasks(HostTask* tsk, bool bBegin);
        virtual void       currTaskFinished();

	HostTask*          currTask() const { return curr_task_; }
	HostTask*          firstTask() const;
	HostTask*          getTask(int i);
	int                getIndexOf(HostTask* tsk);

	virtual const char* toString() const;
	virtual void       stop(bool bStop = true) {}
	virtual void       queueFull(char outLid, char inLid) {}

protected:
	void               adjustTimer();
	void               removeTask(map<int, HostTask*>::iterator it, task_status status);

protected:

	map<int, HostTask*> tasks_;
	HostTask*         curr_task_;
	Event intr_;

	static char buf[BUF_LEN];

};
#endif


#ifdef NEVER
#include <map>
#include <scheduler.h>
#include <bt-def.h>
#include <bt-host.h>

class TaskScheduler;


class TaskEvent : public Event {
public:
	TaskEvent() { status_ = TASK_CANCEL; type_ = NUM_TSK; }
	task_status status_; // status of this event 
	task_type   type_;
	virtual bool equal(TaskEvent* e) { return this == e; }
	virtual const char*   toString() const {
		snprintf(buf, BUF_LEN, "%-6d", (int)status_);
		return buf;
	}
 
	static char buf[BUF_LEN];
};


class HostTask {

public:
	task_type type_;
	int       start_;
	int       finish_;
	int       mclkn_;  // aux field which helps implementation; only applies to COMM task
	int       data_in_;
	int       data_out_;
	Handler*  handler_;
	TaskEvent*    ev_;
	TaskScheduler* sched_;

	HostTask() : type_(NUM_TSK), start_(0), finish_(0), mclkn_(0), 
		data_in_(0), data_out_(0), handler_(NULL), ev_(NULL), sched_(NULL) {}

	virtual const char* toString(bool bNative = true) const;
	task_type type() const { return type_; }
	
	static char*  typeString(task_type type) {
		if(type == INQ_TSK)
			return "INQ_TSK";
		else if(type == INQ_SCAN_TSK)
			return "INQ_SCAN_TSK";
		else if(type == PAGE_TSK)
			return "PAGE_TSK";
		else if(type == PAGE_SCAN_TSK)
			return "PAGE_SCAN_TSK";
		else if(type == COMM_TSK)
			return "COMM_TSK";
		else {
			ASSERT(0);
		}
	}

	virtual bool equal(HostTask* t) { 
		return (this == t);
			//(type_ == e->type_ && start_ == e->start_ && finish_ == e->finish_);
	}

	int       duration() { return finish_ - start_; }

protected:
	static char buf[BUF_LEN];
};


// run time: O(n^2) if bAll is set! @TODO
template<class T> inline bool 
cancelT(TaskScheduler* tss, T* e, bool bAll) 
{
	map<int, HostTask*>::iterator it;
	bool bRemoved = false, bEq = false;

      	for(it = tss->tasks_.begin(); it != tss->tasks_.end();) {
		bEq = false;
		if(dynamic_cast<TaskEvent*>(e))
			bEq = dynamic_cast<TaskEvent*>(e)->equal(it->second->ev_);
		if(bEq) {
			bRemoved = true;
			tss->removeTask(it, TASK_CANCEL); 
			if(!bAll)
				break;
			else {
				it = tss->tasks_.begin(); // The STL implementation distributed with linux
				// does not return an iter upon erase! Some commerical impl. does. 
				continue; // do not incr it
			}
		}
		it++;
	}
	return bRemoved;
}


template<class T> inline HostTask*
findT(TaskScheduler* tss, T* e) 
{
	map<int, HostTask*>::iterator it;
	bool bEq = false;
      	for(it = tss->tasks_.begin(); it != tss->tasks_.end(); it++) {
		if(dynamic_cast<TaskEvent*>(e))
			bEq = dynamic_cast<TaskEvent*>(e)->equal(it->second->ev_);
		else if(dynamic_cast<HostTask*>(e))
			bEq = dynamic_cast<HostTask*>(e)->equal(it->second);
		if(bEq) {
			return it->second;
		}
	}
	return NULL;
}


class TaskScheduler : virtual public HCIEventsHandler {

	friend bool cancelT<TaskEvent>(TaskScheduler* tss, TaskEvent* e, bool bAll);
	friend HostTask* findT<HostTask>(TaskScheduler* tss, HostTask* e);
	friend HostTask* findT<TaskEvent>(TaskScheduler* tss, TaskEvent* e);
	
public:
	const static int MinTaskLen = 4;

	TaskScheduler();
	virtual HostTask*  scheduleHard(task_type type, Handler* h, TaskEvent* e, int start, int finish, int minDur);
	virtual HostTask*  schedule(task_type type, int duration, Handler* h, TaskEvent* e, int offset = 0, 
				    int minDur = -1, int slack = 0);
	virtual bool       cancel(HostTask* tsk);
	virtual bool       cancel(TaskEvent* ev, bool bAll = false);
	virtual bool       cancel(task_type ty, bool bAll = false);

	virtual HostTask*  find(TaskEvent* ev);

	virtual Packet*    send(uchar ch);
	virtual void       pollMissed(uchar ch);

	virtual void       handle(Event* e);
	void               beginFirstTask();
	int                lastFinishTime() const;
	int                gapBetweenTasks(HostTask* tsk, bool bBegin);
        virtual void       currTaskFinished();

	HostTask*          currTask() const { return curr_task_; }
	HostTask*          firstTask() const;
	HostTask*          getTask(int i);
	int                getIndexOf(HostTask* tsk);

	virtual const char* toString() const;
	virtual void       stop(bool bStop = true) {}
	virtual void       queueFull(char outLid, char inLid) {}

protected:
	void               adjustTimer();
	void               removeTask(map<int, HostTask*>::iterator it, task_status status);

protected:

	map<int, HostTask*> tasks_;
	HostTask*         curr_task_;
	Event intr_;

	static char buf[BUF_LEN];
};


#endif // NEVER

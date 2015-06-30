/** .h file for BTTaskScheduler */
#ifndef __BTTASKSCHEDULER_H__
#define __BTTASKSCHEDULER_H__
#include <stdlib.h>


#include "bt_enums.h"


/* **********************************************************************
 * Conversion functions
 * *********************************************************************/
/**
 * Convert a timer enum value to a task enum value. 
 *
 * \param tm The timer enum value (one of INQ_TM, INQ_SCAN_TM,
 * PAGE_TM or PAGE_SCAN_TM)
 * \return The corresponding task enum value (one of INQ_TSK,
 * INQ_SCAN_TSK, PAGE_TSK, PAGE_SCAN_TSK or NUM_TSK) */
// task_type timer2task(timer_type tm)
task_type timer2task(timer_t tm)
{
  switch(tm) {
  case INQ_TM:
    return INQ_TSK;
  case INQ_SCAN_TM:
    return INQ_SCAN_TSK;
  case PAGE_TM:
    return PAGE_TSK;
  case PAGE_SCAN_TM:
    return PAGE_SCAN_TSK;
  default:
    return NUM_TSK;
  }
};

/**
 * Convert a task enum value to a timer enum value. 
 *
 * \param task The corresponding task enum value (one of INQ_TSK,
 * INQ_SCAN_TSK, PAGE_TSK, PAGE_SCAN_TSK or NUM_TSK) 
 * \return The timer enum value (one of INQ_TM, INQ_SCAN_TM,
 * PAGE_TM or PAGE_SCAN_TM) */
timer_t tskToTimer(task_type tsk)
{
  switch(tsk) {
  case INQ_TSK:
    return INQ_TM;
  case INQ_SCAN_TSK:
    return INQ_SCAN_TM;
  case PAGE_TSK:
    return PAGE_TM;
  case PAGE_SCAN_TSK:
    return PAGE_SCAN_TM;
  default:
    assert(0);
  }
};

/* **********************************************************************
 * Task type. Used to indicate what the status of a given task is... 
 * *********************************************************************/



/* **********************************************************************
 * Handler
 * *********************************************************************/
/**
 * This is a temporary type. */
// typedef int Handler;


/* **********************************************************************
 * TopoEvent implementation.
 * *********************************************************************/
/**
 * TopoEvent - a rewrite of the TopoEvent class from bt-topo.h.
 *
 * <p>This is used by the TaskScheduler.</p>
 *
 * <p>In the Blueware/Bluehoc code, this is inherited from a
 * TaskEvent, and we have _some_ of the TaskEvent fields in here.</p> */
typedef struct TopoEvent {
  task_type   type_;
  bool        first_;
  int         data[5];
  int         duration_;
  //  Handler*    handler_;
  int         start_;
  task_status status_;
} TopoEvent;

/**
 * Allocate a new TopoEvent.
 *
 * <p>Sets up the varios fields.</p>
 * 
 * \param type the type of task to schedule.
 * \return a newly allocated TopoEvent, or NULL. */
TopoEvent * new_TopoEvent(task_type type) {
  TopoEvent * res = (TopoEvent *) malloc (sizeof(TopoEvent));
  if (res) {
    res->start_    = 0;
    // res->handler_  = NULL;
    res->duration_ = 0;
    res->type_     = type;
    res->first_    = TRUE;
    memset((void *)&(res->data), 0, sizeof(int)*5);
  } else {
    dbg(DBG_USR1, "Failed to allocate a TopoEvent\n");
  }
  return res;
}

/** 
 * Return a textual representation of a TopoEvent.
 *
 * <p>This function uses a global buffer, is not threadsafe, and you
 * can count on the return value to change if you call the function
 * again...</p>
 *
 * @param ev the TopoEvent to turn into a string
 * @return a string that is statically allocated */
char * TopoEvent_toString(TopoEvent * ev) {
  static char buf[512];
  snprintf(buf, 512, "%-6d", (int)ev->status_);
  return buf;
}

/**
 * Delete a TopoEvent. */
void delete_TopoEvent(TopoEvent * ev) {
  free(ev);
}

/** Based on... : */
#ifdef NEVER
class TopoEvent : public TaskEvent {
public:
	bool      first_;
	int       data[5];
	int       duration_;
	Handler*  handler_;
	int       start_;

	TopoEvent(task_type type) { 
	        start_ = 0; handler_ = NULL; duration_ = 0; type_ = type; first_ = true; 
		memset((void*)&data, 0, sizeof(int)*5); 
	}

	TopoEvent(const TopoEvent& ev) { 
		duration_ = ev.duration_;
		type_ = ev.type_;
		first_ = ev.first_;
		start_ = ev.start_;
		memcpy((void*)&ev.data, (void*)data, sizeof(int)*5);
	}

	virtual bool equal(TaskEvent* e) 
	{ 
		if(dynamic_cast<TopoEvent*>(e) == NULL) 
			return false;
		return type_ == dynamic_cast<TopoEvent*>(e)->type_; 
	}
};
#endif

/* **********************************************************************
 * HostTask
 * *********************************************************************/
/**
 * The HostTask structure used internally by the TaskScheduler? */
typedef struct HostTask {
  task_type type_;
  int       start_;
  int       finish_;
  int       mclkn_;  // aux field which helps implementation; only applies to COMM task
  int       data_in_;
  int       data_out_;
  // Handler*  handler_;
  // TaskEvent*    ev_;
  TopoEvent*    ev_;
  //  TaskScheduler* sched_; <<-- TODO
  //  protected:
  // static char buf[BUF_LEN];
} HostTask;

/**
 * Allocate a new HostTask.
 *
 * <p>Sets up the varios fields.</p>
 * 
 * \return a newly allocated HostTask, or NULL. */
HostTask * new_HostTask() {
  HostTask * res = (HostTask *) malloc(sizeof(HostTask));
  if (res) {
    res->type_     = NUM_TSK;
    res->start_    = 0;
    res->finish_   = 0;
    res->mclkn_    = 0;
    res->data_in_  = 0;
    res->data_out_ = 0;
    // res->handler_  = NULL;
    res->ev_       = NULL;
    // res->sched_    = NULL;
  }
  return res;
};

/**
 * Delete a HostTask.
 * 
 * <p>Also deletes the TopoEvent, if != NULL.</p>
 *
 * @param tsk the HostTask to delete.
 * @return NULL */
void * delete_HostTask(HostTask * tsk) {
  if (tsk->ev_) {
    delete_TopoEvent(tsk->ev_);
  }
  free(tsk);
  return NULL;
}

/**
 * Return a textual representation of a task_type.
 *
 * @param type the task_type
 * @return a string representation of the task_type */
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
    assert(0);
  }
}


/** 
 * Return a textual representation of a HostTask.
 *
 * <p>This function uses a global buffer, is not threadsafe, and you
 * can count on the return value to change if you call the function again...</p>
 *
 * @param tsk the HostTask to turn into a string
 * @return a string that is statically allocated */
char * HostTask_toString(HostTask * tsk) {
  static char buf[512];
  snprintf(buf, 512, "[%13s %-6d (%-6d, %-6d) %-6s]", 
	   typeString(tsk->type_), tsk->mclkn_, tsk->start_, tsk->finish_, 
	   TopoEvent_toString(tsk->ev_));
  return buf;
}

#ifdef NEVER
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
#endif /* NEVER */


#ifdef NEVER
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
#endif /* HostTask */

/* **********************************************************************
 * Task list data structures and operations
 * *********************************************************************/
/**
 * The list of task.
 *
 * <p>This is a map in the Blueware/Bluehoc implementation. But, for now, this is a list. */
typedef struct {
  list_link_t link;    /* Generic list support - must be first! */
  int first;           /* int element used as first */
  HostTask * second;   /* The actual element contained */
} tasks_t;


/**
 * Delete a tasks_t structure.
 * 
 * @param a tasks_t structure
 * @return NULL */
void * delete_tasks_t(tasks_t * tsk) {
  delete_HostTask(tsk->second);
  free(tsk);
  return NULL;
}

/** 
 * Insert a tasks_t sorted after the first field.
 *
 * \param list the list to insert into.
 * \param first_ the sort key
 * \param second_ the element to insert */
void tasks_t_insert_sorted(tasks_t * tasklist, int first_, HostTask * second_) {
  list_link_t *mylink;
  tasks_t * foo = (tasks_t *) malloc(sizeof(tasks_t));
  foo->first    = first_;
  foo->second   = second_;
  for (mylink = tasklist->link.l_next; 
       mylink != &(tasklist->link); 
       mylink = mylink->l_next) {
    /* If the listelemtent is bigger than this first, insert it before the list */
    dbg(DBG_USR1, "tasks_t_insert_sorted: checking element\n");
    if (((tasks_t *) mylink)->first > first_) {
      break; /* Easy way to handle empty list */
    }
  }
  dbg(DBG_USR1, "tasks_t_insert_sorted: inserting element\n");
  /* Insert the element before the current list */
  list_insert_before(mylink, &(foo->link));
}

/* **********************************************************************
 * min
 * *********************************************************************/
/**
 * Minimum of two ints.
 *
 * \param a a value
 * \param b a value
 * \return minimum of the arguments. */
int min(int a, int b) {
  return (a < b)?a:b;
}


#endif

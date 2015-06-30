/**
 *  @file EventQueue.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/private.hh>
#include <tossim/EventQueue.hh>
#include <tossim/Event.hh>
#include <tossim/util/Heap.hh>

namespace tos {
namespace sim {

namespace impl {

EventQueue::EventQueue(int pause_frequency)
  : _pause_frequency(pause_frequency)
  , _heap()
  , _lock()
{
}

EventQueue::~EventQueue()
{
}

Event *
EventQueue::pop()
{
  Event::Time time;
  Event * event;

  {
    Mutex::scoped_lock lock(_lock);
    event = _heap.pop(time);
  }

//   if(dbg_active(DBG_QUEUE)) {
//     char time_string[128];
//     time_string[0] = 0;
//     printOtherTime(time_string, 128, time);
//     dbg(DBG_QUEUE, "Popping event for mote %i with time %s.\n", event->mote, time_string);
//   }
 
  if ((_pause_frequency > 0) && event->pause())
  {
    sleep(_pause_frequency);
    // dbg(DBG_ALL, "\n");
  }

  return event;
}

void
EventQueue::push(Event * event)
{
  Mutex::scoped_lock lock(_lock);
  _heap.push(event->time(), event);
}

void
EventQueue::handle_next()
{
  Event * event = pop();
  if (event != NULL)
  {
    
  }
}

bool
EventQueue::is_empty() const
{
  bool result;
  Mutex::scoped_lock lock(_lock);

  result = _heap.is_empty();

  return result;
}

} // namespace impl

} // namespace sim
} // namespace tos

/**
 *  @file EventQueue.hh
 *
 *  @author Phil Levis
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_EVENTQUEUE_HH
#define TOS_SIM_EVENTQUEUE_HH

#include <tossim/public.hh>
#include <tossim/util/Heap.hh>
#include <boost/thread/mutex.hpp>

namespace tos {
namespace sim {

namespace impl {

using util::Heap;
using util::ArrayHeap;
typedef boost::mutex Mutex;

/** 
 */

class EventQueue
{
public:                         // Types

public:                         // Constructors
  EventQueue(int pause_frequency);
 ~EventQueue();

public:                         // Methods
  void    push(Event * event);
  Event * pop();
  const Event * peek() const;
  void    handle_next();
  bool    is_empty() const;

private:                        // Types
  typedef Heap<Event, ArrayHeap> Heap;

private:                        // Fields
  int  _pause_frequency;
  Heap _heap;
  mutable Mutex _lock;
}; // class EventQueue

} // namespace impl

using impl::EventQueue;

} // namespace sim
} // namespace tos

#endif // TOS_SIM_EVENTQUEUE_HH

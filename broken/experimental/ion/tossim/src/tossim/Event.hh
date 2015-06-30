/**
 *  @file Event.hh
 *
 *  @author Phil Levis
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_EVENT_HH
#define TOS_SIM_EVENT_HH

#include <tossim/public.hh>
#include <tossim/Event.hh>

namespace tos {
namespace sim {

namespace impl {

/** 
 */

class Event
{
public:                         // Types
  typedef long long Time;

public:                         // Constructors
  Event(const Time& time, const Mote& mote, bool pause, bool force, void * data);
  virtual ~Event();

public:                         // Methods
  virtual void handle(StateModel& state);
  virtual void cleanup();

public:                         // Properties
  Time time() const;
  void time(Time time);
  Mote mote() const;
  void mote(Mote& mote);
  bool pause() const;
  bool force() const;
  void * data() const;

private:                        // Fields
  Time _time;
  int  _mote;
  bool _pause;                  // Whether this event causes the event queue to pause
  bool _force;                  // Whether this event type should always be executed
                                // even if a mote is turned off.
  void * _data;                 // Data associated with the event.  Such data is 
                                // defined in various *Msg message structures.
}; // class Event

} // namespace impl

using impl::Event;

} // namespace sim
} // namespace tos

#endif // TOS_SIM_EVENT_HH

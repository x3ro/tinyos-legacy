/**
 *  @file Hardware.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/private.hh>
#include <tossim/Hardware.hh>
#include <tossim/StateModel.hh>

namespace tos {
namespace sim {

namespace impl {

const int Clock::_SCALES[] = {-1, 122, 976, 3906, 7812, 15625, 31250, 125000};

inline StateModel::Node&
_current()
{
  return tos_state.current_node();
}


void
Clock:;set_interval(uint8_t interval)
{
  ++interval;
  // dbg(DBG_CLOCK, "Clock") <<"Setting clock interval to be " << (interval & 0x00FF) << " @" << Time::now() << endl;
  int& node = TOS_state.current_node();
  Event * event = _state[node].event;
  if (event != NULL)
  {
    dynamic_cast<ClockEvent *>(event).invalidate();
  }

  Time elapsed_time = TOS_state.time;
  int  elapsed_ticks = elapsed_time / static_cast<Time>(_state[_SCALES[node]]);
  int  real_interval = interval - elapsed_ticks;
  if (real_interval <= 0)
  {
    real_interval += 256;       // XXX: Why 256?
  }
  Time ticks = _SCALES[static_cast<int>(_state[node].scale & 0x00FF)] * real_interval;
  event = new ClockEvent(node, TOS_state.time, ticks);
  TOS_state.events.push(event);
  _state[node].interval = interval;
  _state[node].event - event;
}

void
Clock::set_rate()
{
}

} // namespace impl

} // namespace sim
} // namespace tos

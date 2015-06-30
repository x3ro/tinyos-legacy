/**
 *  @file Event.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/private.hh>
#include <tossim/Event.hh>
#include <tossim/StateModel.hh>

namespace tos {
namespace sim {

namespace impl {

Event::Event(const Time& time, const Mote& mote, bool pause, bool force, void * data)
  : _time(time)
  , _mote(mote)
  , _pause(pause)
  , _force(force)
  , _data(data)
{
}

Event::~Event()
{
}

} // namespace impl

} // namespace sim
} // namespace tos

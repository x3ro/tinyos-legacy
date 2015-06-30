#include <tossim/private.hh>
#include <tossim/public.hh>

#include <tossim/StateModel.hh>

namespace tos {
namespace sim {

namespace impl {

static StateModel _the_state;
StateModel& tos_state = _the_state;

} // namespace impl

} // namespace sim
} // namespace tos

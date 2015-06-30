#include <tossim/private.hh>
#include <tossim/PageEeprom.hh>

namespace tos {
namespace sim {

namespace impl {

PageEeprom::PageEeprom(int n_motes, int mote_size)
  : Eeprom(n_motes, mote_size)
{
}

PageEeprom::~PageEeprom()
{
}

} // namespace impl

} // namespace sim
} // namespace tos

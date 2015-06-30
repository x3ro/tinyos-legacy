#ifndef TOS_SIM_PUBLIC_HH
#define TOS_SIM_PUBLIC_HH

#include <boost/noncopyable.hpp> // Most stuff is noncopyable
#include <stdint.h>              // Everything uses uint*_t

// FIXME:
// This variable is defined by NesC.  Figure out later how
// to integrate NesC with C++.  Right now just give it the
// same value the NesC compiler does.
#ifndef TOSH_NUM_NODES
#define TOSH_NUM_NODES 1000
#endif

namespace tos {
namespace sim {

namespace impl {

// Imports
using boost::noncopyable;

// System constants

const unsigned TOS_N_NODES = TOSH_NUM_NODES;
const unsigned DEFAULT_EEPROM_SIZE = 512 * 1024; // 512 Kb

// Types

class AdcModel;
  class RandomAdcModel;
  class GenericAdcModel;
class Event;
class EventQueue;
class EEProm;
  class PageEEProm;
class RfmModel;
  class LosslessRfmModel;
  class LossyRfmModel;
class SpatialModel;
class StateModel;

typedef int32_t Mote;

// Variables
extern StateModel& tos_state;

} // namespace impl


using impl::AdcModel;
using impl::RandomAdcModel;
using impl::GenericAdcModel;
using impl::Event;
using impl::EventQueue;
using impl::EEProm;
using impl::PageEEProm;
using impl::RfmModel;
using impl::LosslessRfmModel;
using impl::LossyRfmModel;
using impl::SpatialModel;
using impl::StateModel;

} // namespace sim
} // namespace tos


// C definitions
extern "C" void __nesc_nido_initialize(int mote);

#endif // TOS_SIM_PUBLIC_HH

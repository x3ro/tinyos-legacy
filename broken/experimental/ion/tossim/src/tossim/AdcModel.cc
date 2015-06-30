/**
 *  @file AdcModel.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/private.hh>
#include <tossim/AdcModel.hh>

//+ #include <algorithm>
#include <cstdlib>
#include <limits>

namespace tos {
namespace sim {

namespace impl {

// Types
using boost::extents;
//+ using std::fill;
using std::numeric_limits;
using std::rand;
using std::size_t;

// Constants
static const unsigned _N_PORTS_PER_NODE = 256;

// ---------------------------------------------------------------------
// AdcModel

AdcModel::AdcModel()
{
}


AdcModel::~AdcModel()
{
}


// ---------------------------------------------------------------------
// RandomAdcModel

RandomAdcModel::RandomAdcModel()
  : AdcModel()
{
}


AdcModel::Value
RandomAdcModel::read(const Mote& mote, const Port& port, const Time& time)
{
  return static_cast<Value>(rand() & 0x03ff); // 10-bit random number
}


// ---------------------------------------------------------------------
// GenericAdcModel

const AdcModel::Value GenericAdcModel::_INVALID = numeric_limits<Value>::max();

GenericAdcModel::GenericAdcModel()
  : _values(extents[TOS_N_NODES][_N_PORTS_PER_NODE])
  , _values_lock()
{
  // FIXME: There's a better way to do this than just loops
  // but I don't understand Boost.MultiArray well enough yet.
  // (We don't really need to care about "better" with
  // only 2 dimensions.  But with more, these loops get ugly.)
  //
  // There's also a more correct way to get the column size.

  for (unsigned mote = 0; mote < _values.size(); ++mote)
    for (unsigned port = 0; port < _values[0].size(); ++port)
    {
      _values[mote][port] = _INVALID;
    }
}


AdcModel::Value
GenericAdcModel::read(const Mote& mote, const Port& port, const Time& time)
{
  Value result = _INVALID;

  if (_valid_mote(mote))
  {
    Mutex::scoped_lock lock(_values_lock);

    result = _values[mote][port];
  }
  else
  {
    // dbg(DBG_ERROR, "GENERIC_ADC_MODEL: trying to read value with invalid parameters: [mote # = %d] [port # = %d]", mote, port);    
  }

  return result;
}


void
GenericAdcModel::set_value(const Mote& mote, const Port& port, const Value value)
{
  if (_valid_mote(mote))
  {
    Mutex::scoped_lock lock(_values_lock);

    _values[mote][port] = value;
  }
  else
  {
    // dbg(DBG_ERROR, "GENERIC_ADC_MODEL: trying to set value with invalid parameters: [mote # = %d] [port # = %d]", mote, port);
  }
}


bool
GenericAdcModel::_valid_mote(const Mote& mote)
{
  return ((mote >= _values.size()) || (mote < 0));
}


} // namespace impl

} // namespace sim
} // namespace tos

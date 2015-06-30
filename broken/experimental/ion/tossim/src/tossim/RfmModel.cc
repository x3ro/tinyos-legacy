#include <tossim/private.hh>
#include <tossim/RfmModel.hh>

#include <cstdlib>
#include <fstream>
#include <string>

namespace tos {
namespace sim {

namespace impl {

using                           std::ifstream;
using                           std::rand;
using                           std::string;


// ---------------------------------------------------------------------
// RfmModel

RfmModel::RfmModel(const unsigned count)
  : _motes(count)
  , _noise_probability(0.0)
  , _radio_connectivity_lock()
{
}

RfmModel::~RfmModel()
{
}


RfmModel::Link::Link()
  : mote(0)
  , data(0.0)
  , bit(0)
{
}

RfmModel::Link::Link(const Mote& mote, double data, uint8_t bit)
  : mote(mote)
  , data(data)
  , bit(bit)
{
}


// ---------------------------------------------------------------------
// LosslessRfmModel

const char * LosslessRfmModel::FILENAME = "lossy.nss";

LosslessRfmModel::LosslessRfmModel(const unsigned count)
  : RfmModel(count)
{
  
}

LosslessRfmModel::~LosslessRfmModel()
{
}


void
LosslessRfmModel::transmit(const Mote& id, int8_t bit)
{
  MoteState& mote = _motes[id];

  mote.transmitting = bit;
  for (MoteStates::iterator at = _motes.begin(); at != _motes.end(); ++at)
  {
    at->radio_active--;
  }
}


void
LosslessRfmModel::stop_transmit(const Mote& id)
{
  MoteState& mote = _motes[id];

  if (mote.transmitting)
  {
    mote.transmitting = 0;
    for (MoteStates::iterator at = _motes.begin(); at != _motes.end(); ++at)
    {
      at->radio_active--;
    }
  }
}


bool
LosslessRfmModel::hears(const Mote& id)
{
  MoteState& mote = _motes[id];
  bool result = mote.radio_active > 0 ? true : false;

  // Uncomment these lines to erroneous 1s (XXX: What's "1s"?)
  // The probability can be adjusted by changing the constants.
  // int value = random();
  // if ((value & static_cast<int>(0xF)) == 0xF)
  //   result = true;

  return result;
}


RfmModel::AdjacencyList&
LosslessRfmModel::neighbors(const Mote& id)
{
  Mutex::scoped_lock lock(_radio_connectivity_lock);
  MoteState& mote = _motes[id];

  AdjacencyList& result = mote.radio_connectivity;

  return result;
}


bool
LosslessRfmModel::is_connected(const Mote& one, const Mote& two)
{
  return true;
}


bool
LosslessRfmModel::_read_entry(ifstream& file, Mote& sender, Mote& receiver, double& lossrate)
{
  bool result = true;
  int ii = 0;

  // Read in first mote id
  file >> ii;
  if (!file)
  {
    result = false;
    goto end;
  }
  sender = ii;

  // Read in second mote id
  file >> ii;
  if (!file)
  {
    result = false;
    goto end;
  }
  receiver = ii;

 end:
  return result;  
}


LosslessRfmModel::MoteState::MoteState()
  : transmitting(0)
  , radio_active(0)
  , radio_connectivity()
  , send_probability(0)
  , receive_probability(0)
  , radio_heard(0)
  , radio_idle(false)
{
}


// ---------------------------------------------------------------------
// LossyRfmModel

LossyRfmModel::LossyRfmModel(const char * filename, const unsigned count)
  : RfmModel(count)
{
  ifstream file(filename);

  // dbg_clear(DBG::SIM, "Initializing lossy model from 5s.\n", filename)
  Mutex::scoped_lock lock(_radio_connectivity_lock);
  
  if (!file)
  {
    // dbg(DBG::SIM, "Cannot open %s - assuming single radio cell.\n", filename)
    // XXX: Implement Static RFM model
  }
  else
  {
    for(MoteStates::iterator at = _motes.begin(); at != _motes.end(); ++at)
    {
      at->radio_idle = false;
      at->radio_heard = 0;
    }

    bool entry_read = true;
    while (entry_read)
    {
      Mote sender, receiver;
      double lossrate;
      if (_read_entry(file, sender, receiver, lossrate))
      {
        if (sender != receiver)
        {
          Link link(receiver, lossrate);
          _motes[sender].radio_connectivity.push_front(link);
        }
      }
      else
      {
        entry_read = false;
      }
    }
  }
  // dbg(DBG_BOOT, ("RFM connectivity graph constructed.\n"));
}


LossyRfmModel::~LossyRfmModel()
{
}


void
LossyRfmModel::transmit(const Mote& id, int8_t bit)
{
  Mutex::scoped_lock lock(_radio_connectivity_lock);
  MoteState& mote = _motes[id];
  
  mote.transmitting = bit;

  AdjacencyList& neighbors = mote.radio_connectivity;
  for (AdjacencyList::iterator at = neighbors.begin(); at != neighbors.end(); ++at)
  {
    int value = rand() % 100000;
    double probability = static_cast<double>(value) / 100000.0;

    // A bit error.  Rever the bit
    if (probability < at->data)
    {
      bit = bit ? 0 : 1;
    }
    _motes[at->mote].radio_active += bit;
    _motes[at->mote].radio_idle = 0;
    at->bit = bit;
  }
}


void
LossyRfmModel::stop_transmit(const Mote& id)
{
  Mutex::scoped_lock lock(_radio_connectivity_lock);
  MoteState& mote = _motes[id];

  mote.transmitting = 0;

  AdjacencyList& neighbors = mote.radio_connectivity;
  for (AdjacencyList::iterator at = neighbors.begin(); at != neighbors.end(); ++at)
  {
    _motes[at->mote].radio_active -= at->bit;
    at->bit = 0;
  }  
}


// XXX: Clean this up.  Do bits need to be full bytes?
bool
LossyRfmModel::hears(const Mote& id)
{
  MoteState& mote = _motes[id];
  int8_t bit_heard = mote.radio_active > 0 ? 1 : 0;

  if (mote.radio_idle)
  {
    int value = rand() % 100000;
    double probability = static_cast<double>(value) / 100000.0;
    // Noise has caused this bit to be inverted
    if (probability < _noise_probability)
    {
      bit_heard = (bit_heard) ? 0 : 1;
    }
  }
  else
  {
    short heard = mote.radio_heard;
    heard <<= 1;
    heard |= bit_heard;
    mote.radio_heard = heard;
    if ((mote.radio_heard & IDLE_STATE_MASK) == 0)
    {
      mote.radio_heard = 1;
    }
  }
  return bit_heard ? true : false;
}


RfmModel::AdjacencyList&
LossyRfmModel::neighbors(const Mote& id)
{
  Mutex::scoped_lock lock(_radio_connectivity_lock);
  MoteState& mote = _motes[id];

  AdjacencyList& result = mote.radio_connectivity;

  return result;
}


/**
 *
 *  This method is rather slow, and runs on the order of the number
 *  of links attached to mote 'one' because it traverses one's
 *  adjacency list.
 *  To make this a constant time operation, the adjacency list
 *  should be hash table.
 */
bool
LossyRfmModel::is_connected(const Mote& one, const Mote& two)
{
  Mutex::scoped_lock lock(_radio_connectivity_lock);
  bool result = false;

  AdjacencyList& neighbors = _motes[one].radio_connectivity;
  for (AdjacencyList::iterator at = neighbors.begin(); at != neighbors.end(); ++at)
  {
    if ((at->mote == two) && at->data < 1.0)
    {
      // dbg(DBG_TEMP,"connected to %d\n", two);
      result = true;
      break;
    }
  }
  //  current = statesradio_connectivity
  return result;
}


double
LossyRfmModel::get_link_probability(const Mote& one, const Mote& two)
{
  Mutex::scoped_lock lock(_radio_connectivity_lock);
  double result = 1.0;

  AdjacencyList& neighbors = _motes[one].radio_connectivity;
  for (AdjacencyList::iterator at = neighbors.begin(); at != neighbors.end(); ++at)
  {
    if (at->mote == two)
    {
      result = at->data;
      break;
    }
  }

  return result;
}


void
LossyRfmModel::set_link_probability(const Mote& one, const Mote& two, double probability)
{
  Mutex::scoped_lock lock(_radio_connectivity_lock);

  AdjacencyList& neighbors = _motes[one].radio_connectivity;
  for (AdjacencyList::iterator at = neighbors.begin(); at != neighbors.end(); ++at)
  {
    if (at->mote == two)
    {
      at->data = probability;
      break;
    }
  }  
  Link new_link(two, probability);
  _motes[one].radio_connectivity.push_front(new_link);
}


// XXX: These are not defined in rfm_model.h, only in rfm_model.c.  Are they old?

/*
uint8_t
LossyRfmModel::get_wait_length_before_idle()
{
  uint8_t count = 0;
  short mask = IDLE_STATE_MASK;
  while (mask != 0)
  {
    count++;
    mask >>= 1;
    mask &= 0x7fff;
  }
  return count;
}


void
LossyRfmModel::set_wait_length_before_idle(uint8_t count)
{
  short mask = IDLE_STATE_MASK;
  while (mask != 0)
  {
    count--;
    mask <<= 1;
    mask |= 0x0001;
  }
}
*/




/**
 *  @brief Read in the information on a lossy connection.
 *
 *  The connection format is made up of three items:
 *  (XXX, verify this is correct with Phil Levis)
 *    - The id of the sender
 *    - The id of the receiver.
 *    - The lossiness of the connection.
 */
bool
LossyRfmModel::_read_entry(ifstream& file, Mote& sender, Mote& receiver, double& lossrate)
{
  bool result = true;
  int ii = 0;
  double dd = 0.0;

  // Read in first mote id
  file >> ii;
  if (!file)
  {
    result = false;
    goto end;
  }
  sender = ii;

  // Read in second mote id
  file >> ii;
  if (!file)
  {
    result = false;
    goto end;
  }
  receiver = ii;

  // Read in loss rate
  file >> dd;
  if (!file)
  {
    result = false;
    goto end;
  }
  lossrate = dd;

 end:
  return result;
}

} // namespace impl

} // namespace sim
} // namespace tos

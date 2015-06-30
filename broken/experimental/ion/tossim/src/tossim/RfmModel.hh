/**
 *  @brief Radio simulation models
 *
 */

#ifndef TOS_SIM_RFMMODEL_HH
#define TOS_SIM_RFMMODEL_HH

#include <tossim/public.hh>
#include <tossim/AdjacencyList.hh>
#include <boost/thread/mutex.hpp>
#include <ext/slist>
#include <iosfwd>
#include <vector>
#include <stdint.h>

namespace tos {
namespace sim {

namespace impl {

using __gnu_cxx::slist;
using std::ifstream;
using std::vector;
typedef boost::mutex Mutex;


// FIXME: Is there a better place to put these constants?
struct RadioModel
{
  enum Type
  {
    SIMPLE, LOSSY, PACKET
  };

  // FIXME: We dont want instances of RadioModel -- but GCC
  // prints a warning if we just hide the destructor.
  //+ private:                        // Prevent construction
  //+  ~RadioModel();
};


/**
 * @brief The interface used by TOS SIM for radio simulation.
 *
 * There are currently three implementations:
 *   - Simple:
 *   - Static:
 *   - Space:
 */

class RfmModel
{
public:                         // Types
  struct Link
  {
    Link();
    Link(const Mote& mote, double data, uint8_t bit = 0);
                                                                                                
    Mote mote;
    double data;
    uint8_t bit;    
  };
  typedef slist<Link> AdjacencyList;

public:                         // Methods
  virtual void transmit(const Mote& mote, int8_t bit) = 0;
  virtual void stop_transmit(const Mote& mote) = 0;
  virtual bool hears(const Mote& mote) = 0;
  virtual bool is_connected(const Mote& one, const Mote& two) = 0;
  virtual AdjacencyList& neighbors(const Mote& mote) = 0;

protected:                      // Constructors
  RfmModel(const unsigned count);
  virtual ~RfmModel();

protected:                      // Constants
  static const short IDLE_STATE_MASK = 0xFFFF;

protected:                      // Types
  /** Data associated with individual motes (nodes in the graph) */
  // XXX: Any way to handle some of these fields as bitset<>s?
  struct MoteState
  {
    MoteState();

    int8_t transmitting;
    int    radio_active;
    AdjacencyList radio_connectivity;
    int8_t send_probability;
    int8_t receive_probability;
    short  radio_heard;         // Idle detection over the network
    bool   radio_idle;          // Whether the channel is idle
  };
  typedef vector<MoteState> MoteStates;

protected:                     // Methods
  virtual bool _read_entry(ifstream& file, Mote& mote, Mote&, double& lossrate) = 0;

protected:                     // Fields
  MoteStates _motes;
  double     _noise_probability;
  Mutex      _radio_connectivity_lock;
}; // class RfmModel


/** 
 *  @brief In the simple model, all motes are able to hear each other perfectly.
 *
 *  The simple RFM model simulates every mote being in a single cell
 *  (they can all hear one another). Bit transmission is error-free.
 *  Simulation is achieved by storing the radio activity for each
 *  mote, which starts at 0.  Every time a mote transmits, it
 *  increments the radio activity for every other mote. When a
 *  mote listens, it hears a bit if the radio activity is one or
 *  greater. When a mote finishes transmitting, it decrements the
 *  radio activity of every other mote. Although very simple, this
 *  simulation mechanism allows for extremely accurate network timing
 *  simulation.
 */

class LosslessRfmModel : public RfmModel
{
public:                         // Methods
  LosslessRfmModel(const unsigned count = TOS_N_NODES);
 ~LosslessRfmModel();

  virtual void transmit(const Mote& mote, int8_t bit);
  virtual void stop_transmit(const Mote& mote);
  virtual bool hears(const Mote& mote);
  virtual bool is_connected(const Mote& one, const Mote& two);
  virtual AdjacencyList& neighbors(const Mote& mote);

protected:
  virtual bool _read_entry(ifstream& file, Mote& mote, Mote&, double& lossrate);

private:                        // Fields
  static const char * FILENAME;

}; // class LosslessRfmModel


/** 
 *  In the lossy model the connectivity graph is determined at
 *  simulator boot time and can be changed over the control channel;
 *  each link has a bit error rate.
 */

class LossyRfmModel : public RfmModel
{
public:                         // Types

public:                         // Methods
  LossyRfmModel(const char * filename, const unsigned count = TOS_N_NODES);
 ~LossyRfmModel();

  virtual void transmit(const Mote& mote, int8_t bit);
  virtual void stop_transmit(const Mote& mote);
  virtual bool hears(const Mote& mote);
  virtual bool is_connected(const Mote& one, const Mote& two);
  virtual AdjacencyList& neighbors(const Mote& mote);

  double get_link_probability(const Mote& one, const Mote& two);
  void set_link_probability(const Mote& one, const Mote& two, double value);
  double get_noise_probability();
  void set_noise_probability(double value);  

protected:                      // Methods
  virtual bool _read_entry(ifstream& file, Mote& mote, Mote&, double& lossrate);

private:                        // Fields
  bool _read_entry();
}; // class LossyRfmModel


} // namespace impl

using impl::RfmModel;
using impl::LosslessRfmModel;
using impl::LossyRfmModel;

} // namespace sim
} // namespace tos

#include <tossim/RfmModel.ii>

#endif // TOS_SIM_RFMMODEL_HH

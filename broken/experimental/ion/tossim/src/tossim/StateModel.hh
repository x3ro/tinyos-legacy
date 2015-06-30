/**
 *  @file StateModel.hh
 *
 *  @author Philip Levis
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_STATEMODEL_HH
#define TOS_SIM_STATEMODEL_HH

#include <tossim/public.hh>
#include <boost/thread/condition.hpp>
#include <boost/thread/mutex.hpp>
#include <vector>
#include <stdint.h>

namespace tos {
namespace sim {

namespace impl {

using std::vector;

typedef boost::mutex Mutex;
typedef boost::condition Condition;


/** 
 */

class StateModel
{
public:                         // Types
  struct Node
  {
    long long time;             // Boot time of mote
    int pot_setting;            // FIXME: No idea what "pot" is
  };

public:                         // Methods
  StateModel();
 ~StateModel();

  short current_id();
  Node& current();
  //  void insert_event(const Event& event);
  int notify_command_called(const char * name);
  int notify_event_signalled(const char * name);
  int notify_task_posted(const char * name);
  uint32_t get_rate();
  void set_rate(uint32_t rate);

public:                         // Fields
  long long time;               // FIXME: Time simulator has been running?
  int radio_rate_kb;            // Radio rate in Kb
  short n_nodes;
  short current_node;
  vector<Node> nodes;
  // EventQueue events;
  // RadioModel::Type radio_model; // Simple, lossy (bit) or packet
  RfmModel * rfm;
  AdcModel * adc;
  SpatialModel * space;
  bool mote_on[TOS_N_NODES];
  bool cancel_boot[TOS_N_NODES];

  bool paused;
  Mutex pause_lock;
  Condition pause_condition;
  Condition pause_ack_condition;
  
}; // class StateModel

} // namespace impl

using impl::StateModel;

} // namespace sim
} // namespace tos

#endif // TOS_SIM_STATEMODEL_HH

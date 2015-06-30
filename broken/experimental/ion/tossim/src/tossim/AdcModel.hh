/**
 *  @file AdcModel.hh
 *
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_XXX_HH
#define TOS_SIM_XXX_HH

#include <tossim/public.hh>
#include <boost/multi_array.hpp>
#include <boost/thread/mutex.hpp>
#include <stdint.h>

namespace tos {
namespace sim {

namespace impl {

using boost::multi_array;
typedef boost::mutex Mutex;


/** 
 *  @brief The interface used by TOS SIM for sensor simulation.
 */

class AdcModel
{
public:                         // Types
  typedef uint16_t Value;
  typedef uint8_t Port;
  typedef long long Time;

public:                         // Methods
  /** @brief Read a value from the sensor */
  virtual Value read(const Mote& mote, const Port& port, const Time& time) = 0;

protected:                      // Constructors
  AdcModel();
  virtual ~AdcModel();
}; // class AdcModel


/**
 *  @brief
 */

class RandomAdcModel : public AdcModel
{
public:                         // Constructors
  RandomAdcModel();
 ~RandomAdcModel();

public:                         // Methods
  virtual Value read(const Mote& mote, const Port& port, const Time& time);
};


/**
 *  @brief
 */

class GenericAdcModel : public AdcModel
{
public:                         // Constructors
  GenericAdcModel();
 ~GenericAdcModel();

public:                         // Methods
  virtual Value read(const Mote& mote, const Port& port, const Time& time);

  void set_value(const Mote& mote, const Port& port, const Value value);

private:                        // Types
  // Indexed by mote id, and by port id
  typedef multi_array<Value, 2> Values;

private:                        // Methods
  bool _valid_mote(const Mote& mote);

private:                        // Constants
  static const Value _INVALID;

private:                        // Fields
  Values _values;
  Mutex _values_lock;
};

} // namespace impl

using impl::AdcModel;

} // namespace sim
} // namespace tos

#endif // TOS_SIM_XXX_HH

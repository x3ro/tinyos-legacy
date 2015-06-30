/**
 *  @file Hardware.hh
 *
 *  @author Phil Levis
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_HARDWARE_HH
#define TOS_SIM_HARDWARE_HH

#include <tossim/public.hh>
#include <vector>

namespace tos {
namespace sim {

namespace impl {

using std::vector;

/** 
 */

class Adc
{
public:                         // Types

public:                         // Constructors
  Adc();
 ~Adc();

public:                         // Methods
  void set_sampling_rate(uint8_t rate);
  void sample_port(uint8_t port);
  void sample_again();
  void sample_stop();
  void data_ready(uint16_t data);

private:                        // Fields
}; // class Adc


/** 
 */

class Clock
{
public:                         // Types

public:                         // Constructors
  Clock();
 ~Clock();

public:                         // Methods
  void set_interval(uint8_t interval);
  void set_rate(int8_t rate, int8_t scale);
  void enable_interrupts();
  void disable_interrupts();

private:                        // Types
  struct _State
  {
    Event * event;              // clockEvents
    uint8_t interval;           // intervals
    uint8_t scales;             // scales
    Time    set_time;          // setTime
    uint8_t interrupt_pending   // interruptPending
  };

private:                        // Fields
  static const int _SCALES[];

  vector<State> _state;
}; // class Clock


/** 
 */

class Rfm
{
public:                         // Types

public:                         // Constructors
  Rfm();
 ~Rfm();

public:                         // Methods
  void set_bit_rate(uint8_t rate);
  void power_off();
  void enable_timer();
  void disable_timer();
  void rx_mode();
  void tx_mode();
  void rx_bit();
  void tx_bit();

private:                        // Fields
  
}; // class Rfm


/** 
 */

class Uart
{
public:                         // Types

public:                         // Constructors
  Uart();
 ~Uart();

public:                         // Methods
  void put_done();

private:                        // Fields
  
}; // class Uart

} // namespace impl

using impl::Clock;
using impl::Adc;

} // namespace sim
} // namespace tos

#endif // TOS_SIM_HARDWARE_HH

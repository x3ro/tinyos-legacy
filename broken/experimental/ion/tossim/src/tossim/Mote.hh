#ifndef TOS_SIM_MOTE_HH
#define TOS_SIM_MOTE_HH

#include <tossim/public.hh>

namespace tos {
namespace sim {

namespace impl {

/** 
 */

class Mote
{
public:                         // Constants
  static const unsigned UNINITIALIZED = -1U;

public:                         // Methods
  Mote();
  Mote(unsigned id);
  Mote(const Mote& other);
 ~Mote();

  Mote& operator=(const Mote& other);

  operator unsigned();

private:                        // Fields
  unsigned _id;
}; // class Mote

} // namespace impl

using impl::Mote;

} // namespace sim
} // namespace tos

#include <tossim/Mote.ii>

#endif // TOS_SIM_MOTE_HH

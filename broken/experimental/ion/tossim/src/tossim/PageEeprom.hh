#ifndef TOS_SIM_PAGEEEPROM_HH
#define TOS_SIM_PAGEEEPROM_HH

#include <tossim/public.hh>
#include <tossim/Eeprom.hh>
#include <stdint.h>

namespace tos {
namespace sim {

namespace impl {

/** 
 */

class PageEeprom : public Eeprom
{
public:                         // Constants
  static const unsigned MAX_PAGES      = 2048;
  static const unsigned PAGE_SIZE      = 264;
  static const unsigned PAGE_SIZE_LOG2 = 8; // For those who want to ignore the last 8 bytes

public:                         // Types
  typedef uint16_t Page;
  typedef uint16_t PageOffset;  // Ranges from (0, PAGE_SIZE - 1)

public:                         // Methods
  PageEeprom(int n_motes, int mote_size);
 ~PageEeprom();

private:                        // Fields
  
}; // class PageEeprom

} // namespace impl

} // namespace sim
} // namespace tos

#endif // TOS_SIM_PAGEEEPROM_HH

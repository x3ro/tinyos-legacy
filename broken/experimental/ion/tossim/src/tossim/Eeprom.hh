/**
 *  @file Eeprom.hh
 *  @brief A flat segmented address space for LOGGER(XXX) emulation. 
 *
 *  @author Philip Levis
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_EEPROM_HH
#define TOS_SIM_EEPROM_HH

#include <tossim/public.hh>
#include <tossim/util/public.hh>

#include <sys/types.h>          // For ssize_t (it's not in <cstdlib>)

namespace tos {
namespace sim {

namespace impl {

using util::File;

/** 
 */

class Eeprom
{
public:                         // Constants
  // Characteristics
  static const unsigned LOG2_LINE_SIZE      = 4;
  static const unsigned LINE_SIZE           = 1 << LOG2_LINE_SIZE;
  static const unsigned MAX_LINES           = DEFAULT_EEPROM_SIZE >> LOG2_LINE_SIZE;
  static const unsigned BYTE_ADDR_BYTE_MASK = 0xf;

  // Allocations
  static const unsigned LOGGER_APPEND_START = 16;
  static const unsigned LOGGER_APPEND_END   = MAX_LINES;

  // Reading and Writing
  static const int SUCCESS = 0;
  static const int FAILURE = -1;

public:                         // Types
  typedef int Word;

  enum ComponentID
  {
    BYTE_EEPROM_ID
  };

public:                         // Constructors
  // Create an EEPROM tied to a file
  Eeprom(const char * filename, int n_motes, int mote_size);
  // Create an anonymous EEPROM
  Eeprom(int n_motes, int mote_size);
 ~Eeprom();

public:                         // Methods
  // XXX: The buffer should be int8_t *, not char *.  Somehow though
  // XXX: G++ 3.3.3 thinks these types don't match (???)
  int read(const Mote& mote, char * buffer, ssize_t length, ssize_t offset);
  int write(const Mote& mote, const char * buffer, ssize_t length, ssize_t offset);
  int sync();

protected:                      // Fields
  File * _file;
  int _n_motes;
  int _mote_size;

private:                        // Methods
  bool _initialize(const char * filename);
  bool _sanity_check(const char *, const Mote& mote, ssize_t length, ssize_t offset);
}; // class Eeprom

} // namespace impl

using impl::Eeprom;

} // namespace sim
} // namespace tos

#endif // TOS_SIM_EEPROM_HH

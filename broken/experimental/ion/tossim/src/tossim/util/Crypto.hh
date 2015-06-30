/**
 *  @file Xxx.hh
 *
 *  @author Naveen Sastry
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_CRYPTO_HH
#define TOS_SIM_CRYPTO_HH

#include <tossim/public.hh>
#include <stdint.h>

namespace tos {
namespace sim {

namespace impl {

/** 
 *  Cryptographic routines
 */

// XXX: This isn't implemented.  Does it need to be?
// FIXME: There must be standard ways to implement these functions
class Crypto
{
public:
  uint32_t rotate_left(uint32_t& a, uint32_t n)
  {
    a= ((a << n) | (a >> (32 - n)));
  }

  uint32_t rotate_right(uint32_t& a, uint32_t n)
  {
    a= ((a << n) | (a >> (32 - n)));
  }

private:                         // Methods
  Crypto();
 ~Crypto();
}; // class Crypto

} // namespace impl

using impl::Crypto;

} // namespace sim
} // namespace tos

#endif // TOS_SIM_CRYPTO_HH

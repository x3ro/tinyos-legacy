#ifndef TOS_SIM_UTIL_PUBLIC_HH
#define TOS_SIM_UTIL_PUBLIC_HH

#include <boost/noncopyable.hpp> // Most stuff is noncopyable

namespace tos {
namespace sim {
namespace util {

namespace impl {

// Imports
using boost::noncopyable;

// System constants

// Types

class File;
template <typename T, typename Impl> class Heap;
template <typename T> class TreeHeap;
template <typename T> class ArrayHeap;
template <typename T> class StandardHeap;


} // namespace impl

using impl::File;
using impl::Heap;
using impl::TreeHeap;
using impl::ArrayHeap;
using impl::StandardHeap;

} // namespace util
} // namespace sim
} // namespace tos


// C definitions
extern "C" void __nesc_nido_initialize(int mote);

#endif // TOS_SIM_UTIL_PUBLIC_HH

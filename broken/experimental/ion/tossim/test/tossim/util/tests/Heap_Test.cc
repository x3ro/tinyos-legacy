/**
 *  @file Heap_Test.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/util/tests/private.hh>
#include <tossim/util/tests/Heap_Test.hh>

#include <tossim/util/Heap.hh>

#include <boost/array.hpp>

#include <ext/algorithm>
#include <ext/numeric>
#include <algorithm>

namespace tinyos {
namespace sim {
namespace util {
namespace test {

using boost::array;
using __gnu_cxx::iota;
using __gnu_cxx::random_sample;
using std::reverse_copy;
using std::size_t;
using ::tos::sim::util::Heap;
using ::tos::sim::util::ArrayHeap;
using ::tos::sim::util::StandardHeap;
using ::tos::sim::util::TreeHeap;

CPPUNIT_TEST_SUITE_REGISTRATION( TreeHeap_Test );

// Data samples to feed to the heaps
const size_t _DEFAULT_HEAP_SIZE = 10;
static array<int, _DEFAULT_HEAP_SIZE> _ordered, _reversed, _scrambled;

// ---------------------------------------------------------------------
// _Heap_Test (test implementation)

template <typename Heap_T, typename _T>
class _Heap_Test
{
  
};

// ---------------------------------------------------------------------
// Heap_Test

Heap_Test::Heap_Test(void * heap)
  : _heap(heap)
{
}

Heap_Test::~Heap_Test()
{
  // The subclass that provides the heap is the one that deletes it.
}

void
Heap_Test::setUp()
{
  // In-order increasing numbers
  iota(_ordered.begin(), _ordered.end(), 0);
  // In-order decreasing numbers
  reverse_copy(_ordered.begin(), _ordered.end(), _reversed.begin());
  // Randomly scrambled numbers
  // Note: the order should be random but deterministic.  If it is not,
  // use another random-number generator: we need reproducable results.
  random_sample(_ordered.begin(), _ordered.end(), _scrambled.begin(), _scrambled.end());
}

void
Heap_Test::tearDown()
{
}

void
Heap_Test::testCreate()
{
  //  Heap * heap = new Heap();

  //  delete heap;
}

// ---------------------------------------------------------------------
// TreeHeap_Test

inline
TreeHeap_Test::TreeHeap_Test()
  : Heap_Test(new TreeHeap())
{
}


inline
TreeHeap_Test::~TreeHeap_Test()
{
  TreeHeap * heap = _heap;

  delete heap;
}

// ---------------------------------------------------------------------
// ArrayHeap_Test

inline
ArrayHeap_Test::ArrayHeap_Test()
  : Heap_Test(new ArrayHeap())
{
}


inline
ArrayHeap_Test::~ArrayHeap_Test()
{
}

// ---------------------------------------------------------------------
// StandardHeap_Test

inline
StandardHeap_Test::StandardHeap_Test()
  : Heap_Test(new StandardHeap())
{
}


inline
StandardHeap_Test::~StandardHeap_Test()
{
}

} // namespace test
} // namespace util
} // namespace sim
} // namespace tinyos

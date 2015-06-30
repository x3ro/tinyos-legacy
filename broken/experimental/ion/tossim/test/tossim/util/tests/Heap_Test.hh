/**
 *  @file Heap_Test.hh
 *
 *  @note The various types of heap tests could, like the heaps themselves,
 *  be template instances (i.e. Heap_Test<typename Heap_T>.  This means
 *  exposing the implementation details of the test in a .ii file however,
 *  and I really don't like opening the tests to compilation dependencies.
 *  So subclasses are the way to go.  The base class will never be
 *  instantiated however, and exists only to provide common functionality.
 *
 *  @author Ion Yannopoulos
 */

#ifndef TESTS_TOSSIM_UTIL_HEAP_TEST_HH
#define TESTS_TOSSIM_UTIL_HEAP_TEST_HH

#include <tossim/util/tests/public.hh>
#include <tossim/util/Heap.hh>

namespace tinyos {
namespace sim {
namespace util {
namespace test {

using ::tos::sim::util::TreeHeap;
using ::tos::sim::util::ArrayHeap;
using ::tos::sim::util::StandardHeap;

/** @brief Base class for testing heaps.
 */

class Heap_Test : public TestCase
{
protected:                      // Constructors
  Heap_Test(void * heap);
 ~Heap_Test();

public:                         // TestCase methods
  virtual void setUp();
  virtual void tearDown();

public:                         // Methods
  virtual void testCreate() = 0;
  virtual void testPeek() = 0;
  virtual void testPush() = 0;
  virtual void testPop() = 0;
  virtual void testPopEmpty() = 0;
  virtual void testIsEmpty() = 0;
  virtual void testSize() = 0;
  virtual void testInOrderSequence() = 0;
  virtual void testReversedSequence() = 0;

protected:                        // Fields
  void * _heap;
}; // class _Heap_Test


/** @brief Tree heap tests.
 */

class TreeHeap_Test : public Heap_Test
{
public:                         // Constructors
  TreeHeap_Test();
 ~TreeHeap_Test();

public:                         // TestSuite setup
  CPPUNIT_TEST_SUITE( TreeHeap_Test );
//   CPPUNIT_TEST( testCreate );
//   CPPUNIT_TEST( testPeek );
//   CPPUNIT_TEST( testPush );
//   CPPUNIT_TEST( testPop );
//   CPPUNIT_TEST( testPopEmpty );
//   CPPUNIT_TEST( testIsEmpty );
//   CPPUNIT_TEST( testSize );
//   CPPUNIT_TEST( testInOrderSequence );
//   CPPUNIT_TEST( testReversedSequence );
  CPPUNIT_TEST_SUITE_END();
};


/** @brief Array heap tests.
 */

class ArrayHeap_Test : public Heap_Test
{
public:                         // Constructors
  ArrayHeap_Test();
 ~ArrayHeap_Test();

public:                         // TestSuite setup
  CPPUNIT_TEST_SUITE( ArrayHeap_Test );
//   CPPUNIT_TEST( testCreate );
//   CPPUNIT_TEST( testPeek );
//   CPPUNIT_TEST( testPush );
//   CPPUNIT_TEST( testPop );
//   CPPUNIT_TEST( testPopEmpty );
//   CPPUNIT_TEST( testIsEmpty );
//   CPPUNIT_TEST( testSize );
//   CPPUNIT_TEST( testInOrderSequence );
//   CPPUNIT_TEST( testReversedSequence );
  CPPUNIT_TEST_SUITE_END();

};


/** @brief Standard heap tests.
 */

class StandardHeap_Test : public Heap_Test
{
public:                         // Constructors
  StandardHeap_Test();
 ~StandardHeap_Test();

public:                         // TestSuite setup
  CPPUNIT_TEST_SUITE( StandardHeap_Test );
//   CPPUNIT_TEST( testCreate );
//   CPPUNIT_TEST( testPeek );
//   CPPUNIT_TEST( testPush );
//   CPPUNIT_TEST( testPop );
//   CPPUNIT_TEST( testPopEmpty );
//   CPPUNIT_TEST( testIsEmpty );
//   CPPUNIT_TEST( testSize );
//   CPPUNIT_TEST( testInOrderSequence );
//   CPPUNIT_TEST( testReversedSequence );
  CPPUNIT_TEST_SUITE_END();
};

#include <tossim/util/tests/Heap_Test.ii>

} // namespace test
} // namespace util
} // namespace sim
} // namespace tinyos

#endif // TESTS_TOSSIM_UTIL_HEAP_TEST_HH


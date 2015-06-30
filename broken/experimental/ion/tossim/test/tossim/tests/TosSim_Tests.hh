/**
 *  @file TosSim_Tests.hh
 *
 *  @author Ion Yannopoulos
 */

#ifndef TESTS_TOSSIM_TESTS_TOSSIM_HH
#define TESTS_TOSSIM_TESTS_TOSSIM_HH

#include <tossim/test/public.hh>
#include <cppunit/TestSuite.h>

namespace tinyos {
namespace sim {

namespace test {

using CppUnit::TestSuite;

/** 
 */

class TosSim_Tests : public TestSuite
{
public:                         // Types

public:                         // Constructors
  TosSim_Tests();
 ~TosSim_Tests();

public:                         // TestSuite methods
  virtual void setUp();
  virtual void tearDown();
  // Override to call all the individual tests for the suite
  virtual void runTest();

private:                        // Fields
  
}; // class TosSim_Tests

} // namespace test

} // namespace sim
} // namespace tinyos

#endif // TESTS_TOSSIM_TESTS_TOSSIM_HH



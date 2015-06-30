/**
 *  @file Util_Tests.hh
 *
 *  @author Ion Yannopoulos
 */

#ifndef TESTS_TOSSIM_UTIL_TESTS_HH
#define TESTS_TOSSIM_UTIL_TESTS_HH

#include <tossim/util/tests/public.hh>
#include <cppunit/TestSuite.h>

namespace tinyos {
namespace sim {
namespace util {
namespace test {

using CppUnit::TestSuite;

/** 
 */

class Util_Tests : public TestSuite
{
public:                         // Types

public:                         // Constructors
  Util_Tests();
 ~Util_Tests();
}; // class Util_Tests

} // namespace test
} // namespace util
} // namespace sim
} // namespace tinyos


#endif // TESTS_TOSSIM_UTIL_TESTS_HH


/*
 *  @file tossim_util_tests.cc
 *
 *  @author Ion Yannopoulos
 */

#include "Util_Tests.hh"        // Registry should make this unnecessary -- but it doesn't work.
#include <cppunit/ui/text/TextTestRunner.h>

using namespace tinyos::sim::util::test;
using namespace CppUnit;

int main()
{
  //  TestRegistry& registry = TestRegistry::getRegistry();
  TextTestRunner runner;

  runner.addTest(new Util_Tests());
  runner.run();

  return 0;
}

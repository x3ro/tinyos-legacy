/**
 *  @file tossim_tests.cc
 *
 *  Driver for TosSim tests.
 *
 *  @author Ion Yannopoulos
 */

#include <cppunit/extensions/TestFactoryRegistry.h>
#include <cppunit/ui/text/TestRunner.h>

using CppUnit::TestFactoryRegistry;
typedef CppUnit::TextTestRunner TestRunner;

int main()
{
  TestFactoryRegistry& registry = TestFactoryRegistry::getRegistry();
  TestRunner runner;

  runner.addTest(registry.makeTest());
  runner.run();
}

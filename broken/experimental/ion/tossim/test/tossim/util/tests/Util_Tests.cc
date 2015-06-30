/**
 *  @file Util_Tests.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/util/tests/private.hh>
#include <tossim/util/tests/Util_Tests.hh>
#include "File_Test.hh"
#include "Heap_Test.hh"


namespace tinyos {
namespace sim {
namespace util {
namespace test {


Util_Tests::Util_Tests()
{
  addTest(File_Test::suite());
  addTest(TreeHeap_Test::suite());
}

Util_Tests::~Util_Tests()
{
}


} // namespace test
} // namespace util
} // namespace sim
} // namespace tinyos

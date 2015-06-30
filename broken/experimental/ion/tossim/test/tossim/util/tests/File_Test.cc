/**
 *  @file File_Test.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/util/tests/private.hh>
#include <tossim/util/tests/File_Test.hh>

#include <tossim/util/File.hh>

#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>

#include <iostream>
using std::cerr;


namespace tinyos {

namespace sim {
namespace util {
namespace test {

using ::tos::sim::util::File;
using boost::filesystem;
using boost::filesystem::path;
using std::endl;

CPPUNIT_TEST_SUITE_REGISTRATION( File_Test );

const char * TEST_FILENAME = "tossim_file_test.out";


File_Test::File_Test()
{
}

File_Test::~File_Test()
{
}

void
File_Test::setUp()
{
  _test_filename = TEST_FILENAME;
  _test_file.open(_test_filename.c_str());

  _test_file << "Test line 1\n"
             << "Test line 2\n"
             << "." << endl;
}

void
File_Test::tearDown()
{
  _test_file.close();

  path filepath(_test_filename);
  filesystem::remove(filepath);
}

void
File_Test::testCreate()
{
  // We don't want to use the existing file: the point is to create a new file.
  string filename("tossim_file_testcreate.out");
  path filepath(filename);

  CPPUNIT_ASSERT(!filesystem::exists(filepath));

  {
    File file(filename);

    CPPUNIT_ASSERT(filesystem::exists(filepath));
  }

  // File still exists after destructor is called: this isn't a temporary,
  CPPUNIT_ASSERT(filesystem::exists(filepath));

  filesystem::remove(filepath);

  CPPUNIT_ASSERT(filesystem::exists(filepath));
}

void
File_Test::testCreateAnonymous()
{
}

void
File_Test::testOpenExisting()
{
  path filepath(_test_filename);

  CPPUNIT_ASSERT(filesystem::exists(filepath));

  File file(_test_filename);

  // FIXME: What next?
}

void
File_Test::testSeekBegin()
{
}

void
File_Test::testSeekCurrent()
{
}

void
File_Test::testSeekEnd()
{
}

void
File_Test::testRead()
{
}

void
File_Test::testWrite()
{
}

void
File_Test::testGetAccess()
{
}

void
File_Test::testSetAccess()
{
}

} // namespace test
} // namespace util
} // namespace sim

} // namespace tinyos

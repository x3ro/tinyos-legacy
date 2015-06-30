/**
 *  @file File_Test.hh
 *
 *  @author Ion Yannopoulos
 */

#ifndef TESTS_TOSSIM_UTIL_FILE_TEST_HH
#define TESTS_TOSSIM_UTIL_FILE_TEST_HH


#include <tossim/util/tests/public.hh>

#include <fstream>
#include <string>


namespace tinyos {

namespace sim {
namespace util {
namespace test {

using std::ofstream;
using std::string;


/** 
 */

class File_Test : public TestCase
{
public:                         // Types

public:                         // Constructors
  File_Test();
 ~File_Test();

public:                         // TestCase methods
  virtual void setUp();
  virtual void tearDown();

public:                         // TestSuite setup
  CPPUNIT_TEST_SUITE( File_Test );
  CPPUNIT_TEST( testCreate );
  CPPUNIT_TEST( testCreateAnonymous );
  CPPUNIT_TEST( testOpenExisting );
  // CPPUNIT_TEST( testOpen );
  // CPPUNIT_TEST( testClose );
  CPPUNIT_TEST( testSeekBegin );
  CPPUNIT_TEST( testSeekEnd );
  CPPUNIT_TEST( testSeekCurrent );
  CPPUNIT_TEST( testRead );
  CPPUNIT_TEST( testWrite );
  CPPUNIT_TEST( testGetAccess );
  CPPUNIT_TEST( testSetAccess );
  CPPUNIT_TEST_SUITE_END();

public:                         // Methods
  void testCreate();
  void testCreateAnonymous();
  void testOpenExisting();
  // void testOpen();
  // void testClose();
  void testSeekBegin();
  void testSeekEnd();
  void testSeekCurrent();
  void testRead();
  void testWrite();
  void testGetAccess();
  void testSetAccess();

private:                        // Fields
  ofstream _test_file;
  string _test_filename;
}; // class File_Test

} // namespace test
} // namespace util
} // namespace sim

} // namespace tinyos

#endif // TESTS_TOSSIM_UTIL_FILE_TEST_HH


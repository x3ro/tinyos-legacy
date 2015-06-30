/**
 *  @file File.hh
 *
 *  A wrapper around non-portable aspects of files.
 *
 *  This is necessary rather than simply using fstreams because
 *  fstreams and filebufs provide only iteration over the data
 *  contained in a file, not access to a file's permissions or
 *  or metadata.
 *
 *  It currently only is implemented for POSIX (and in fact likely,
 *  for Linux).  But it should encapsulate what would need to be
 *  ported if we move TinyOS to Windows, or somesuch.
 * 
 *  @note This class has been modified from Lite.Posix.Io, authored
 *    by ion.
 *
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_UTIL_FILE_HH
#define TOS_SIM_UTIL_FILE_HH

#include <tossim/util/public.hh>

#include <iosfwd>
#include <string>


namespace tos {
namespace sim {
namespace util {

namespace impl {

using std::fstream;
using std::string;


/** 
 */

class File : private noncopyable
{
public:                         // Types
  /** Type of file permissions */
  typedef int Access;

  /** Flags to reads and writes */
  typedef int Mode;

public:                         // Constants
  static const Access USER_READ;
  static const Access USER_WRITE;
  static const Access USER_EXECUTE;
  static const Access USER_ALL;
  static const Access GROUP_READ;
  static const Access GROUP_WRITE;
  static const Access GROUP_EXECUTE;
  static const Access GROUP_ALL;
  static const Access OTHER_READ;
  static const Access OTHER_WRITE;
  static const Access OTHER_EXECUTE;
  static const Access OTHER_ALL;
  static const Access ALL;

  static const Mode USE_EXISTING_FILE;
  static const Mode CREATE_NEW_FILE;

  static const int READ_FAILURE;
  static const int WRITE_FAILURE;
  static const int SEEK_FAILURE;

  /** A marker to the constructor for temporary filenames */
  enum Temporary
  {
    TEMPORARY
  };

  // XXX: This should be private, but g++ warns about that.
public:                         // Constructors
  // Don't have a clear semantic for the default constructor
  // yet, so it isn't defined.
  // File();
  File(const string& filename /*, Access access, Mode mode*/);
  // Make a copy of a file
  File(const string& existing_filename, const string& new_filename /*, Mode mode*/);

  /** @brief Create a temporary file.
   */
  File(const Temporary& temporary, const string& suffix = "");
 ~File();

public:                         // Methods
  bool create();
  bool remove();
  bool open();
  bool close();

  bool exists();
  bool is_open();

  int read(char *& buffer, int size) const;
  int write(const char * buffer, int size);
  bool sync();
  int seek_current(int offset) const;
  int seek_begin(int offset) const;
  int seek_end(int offset) const;

  bool get_access(int& mask) const;
  bool set_access(int mask);

private:                        // Fields
  mutable fstream * _file;
  string _filename;
  bool _temporary;
}; // class File

} // namespace impl

using impl::File;

} // namespace util
} // namespace sim
} // namespace tos

#endif // TOS_SIM_UTIL_FILE_HH

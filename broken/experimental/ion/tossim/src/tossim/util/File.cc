/**
 *  @file File.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/util/private.hh>
#include <tossim/util/File.hh>

#include <boost/filesystem/exception.hpp>
#include <boost/filesystem/operations.hpp>

// FIXME: What are the Windows equivalents?
#include <unistd.h>             // For chmod()
#include <sys/stat.h>           // For stat(), and mode flags

#include <cstdio>
#include <fstream>


namespace tos {
namespace sim {
namespace util {

namespace impl {


using boost::filesystem;
using std::filebuf;
using std::ios_base;
using std::tmpnam;              // Note that 'L_tmpnam' is a macro so isn't 'used'.

const File::Access File::USER_READ = S_IRUSR;
const File::Access File::USER_WRITE = S_IWUSR;
const File::Access File::USER_EXECUTE = S_IXUSR;
const File::Access File::USER_ALL = S_IRWXU;
const File::Access File::GROUP_READ = S_IRGRP;
const File::Access File::GROUP_WRITE = S_IWGRP;
const File::Access File::GROUP_EXECUTE = S_IXGRP;
const File::Access File::GROUP_ALL = S_IRWXG;
const File::Access File::OTHER_READ = S_IROTH;
const File::Access File::OTHER_WRITE = S_IWOTH;
const File::Access File::OTHER_EXECUTE = S_IXOTH;
const File::Access File::OTHER_ALL = S_IRWXO;
const File::Access File::ALL = File::USER_ALL | File::GROUP_ALL | File::OTHER_ALL;

const int File::READ_FAILURE = -1;
const int File::WRITE_FAILURE = -1;
const int File::SEEK_FAILURE = -1;


/**
 *  @brief Create a file, or open an existing file
 *
 *  The opened file is readable and writable, and will write to the end of an
 *  existing file.  The file remains open as long as the @c File object exists.
 *  The file will @b not be removed when the File object is destroyed.
 */

File::File(const string& filename)
  : _file()
  , _filename(filename)
  , _temporary(false)
{
  _file = new fstream(_filename.c_str(), ios_base::in | ios_base::app);
}


/**
 *  @brief Return the filename of a unique (or close enough) temporary file.
 *
 *  The opened file is readable and writable, and will write to the end of an
 *  existing file.  The file remains open as long as the @c File object exists.
 *  The file @will @b not be removed when the File object is destroyed.
 *
 *  @note @c tmpnam() is not recommened by the Linux man pages.  However the
 *    recommended function mkstemp() actually opens the file and returns
 *    a file descriptor.  Accessing it would require using the stdio_filebuf
 *    from libstdc++/ext.  While that is feasible, it would require extra
 *    work, and much worse, be non-portable to other C++ implementations.
 *    Seeking to limit the portability issues to operating systems rather
 *    than library implementations, we use @c std::tmpnam(), with it's potential
 *    security weakness.
 *
 *
 */

File::File(const Temporary& temporary, const string& suffix)
  : _file()
  , _filename()
  , _temporary(true)
{
  // NOTE: 'tmpnam' is not secure.  However, we don't care if someone
  // can see or modify the file after it's created.
  char buffer[L_tmpnam];
  
  _filename = tmpnam(buffer);
  _filename += suffix;
  _file = new fstream(_filename.c_str(), ios_base::in | ios_base::out | ios_base::app);
}


File::~File()
{
  // File should be closed
  if (_file)
  {
    _file->close();
    delete _file;
  }

  // Temporary files should be removed
  if (_temporary)
  {
    try
    {
      filesystem::path filepath(_filename);

      filesystem::remove(filepath);
    }
    catch(filesystem::filesystem_error& ex)
    {
      // dbg(DBG_ERROR, "Failed to remove temporary file '%s': %s [%d]", _filename.c_str(), ex.what(), ex.error());
    }
  }
}


int
File::read(char *& buffer, int size) const
{
  int result = READ_FAILURE;

  _file->read(buffer, size);
  if (_file)
  {
    result = _file->gcount();
  }

  return result;
}

int
File::write(const char * buffer, int size)
{
  // Sigh.  This ought to be symmetrical to File::read().
  // However ostreams have no counterpart to istream::gcount():
  // they literally forgot to put it in the standard.
  // So we have to dig into the stream buffer.
  int result = WRITE_FAILURE;
  int pcount = _file->rdbuf()->sputn(buffer, size);
  if (pcount == size)
  {
    result = pcount;
  }

  return result;
}

bool
File::sync()
{
  bool result = false;

  _file->flush();
  if (_file)
  {
    result = true;
  }

  return result;
}


int
File::seek_current(int offset) const
{
  int result = SEEK_FAILURE;

  _file->seekg(offset, ios_base::cur);
  if (_file)
  {
    result = _file->tellg();
  }  

  return result;
}


int
File::seek_begin(int offset) const
{
  int result = SEEK_FAILURE;

  _file->seekg(offset, ios_base::beg);
  if (_file)
  {
    result = _file->tellg();
  }  

  return result;
}


int
File::seek_end(int offset) const
{
  int result = SEEK_FAILURE;

  _file->seekg(offset, ios_base::end);
  if (_file)
  {
    result = _file->tellg();
  }  

  return result;
}


bool
File::get_access(int& mask) const
{
  bool result = false;
  struct stat status;
  int code = stat(_filename.c_str(), &status);

  if (code == 0)
  {
    mask = status.st_mode;
    result = true;
  }

  return result;
}


bool
File::set_access(int mask)
{
  bool result = false;
  int code = chmod(_filename.c_str(), mask);
  if (code == 0)
  {
    result = true;
  }

  return result;
}


} // namespace impl

} // namespace util
} // namespace sim
} // namespace tos

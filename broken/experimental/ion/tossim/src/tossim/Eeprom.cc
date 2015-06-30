/**
 *  @file Eeprom.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/private.hh>
#include <tossim/Eeprom.hh>
#include <tossim/util/File.hh>

#include <fstream>

namespace tos {
namespace sim {
namespace impl {

using util::File;

using std::ios_base;
using std::filebuf;


Eeprom::Eeprom(int n_motes, int mote_size)
  : _file()
  , _n_motes(n_motes)
  , _mote_size(mote_size)
{
  const char * filename = "XXX"; //_File::temporary();

  _initialize(filename);
}

Eeprom::Eeprom(const char * filename, int n_motes, int mote_size)
  : _file()
  , _n_motes(n_motes)
  , _mote_size(mote_size)
{
  _initialize(filename);
}


Eeprom::~Eeprom()
{
  if (_file != NULL)
  {
    delete _file;
  }
}

int
Eeprom::read(const Mote& mote, char * buffer, ssize_t length, ssize_t offset)
{
  int result = FAILURE;

  if(_sanity_check("read", mote, length, offset))
  {
    int base_offset = mote * _mote_size;
    int seek_offset = base_offset + offset;

    if (_file->seek_current(seek_offset) == File::SEEK_FAILURE)
    {
      // dbg(DBG_ERROR, "ERROR: Seek in EEPROM for read failed.\n");
    }
    // XXX: In the original code the read is attempted even if the
    // XXX: seek fails.  This doesn't seem right.
    else if (_file->read(buffer, length) == File::READ_FAILURE)
    {
      // dbg(DBG_ERROR, "ERROR: Read for %i from EEPROM failed: %s.\n", length, strerror(errno));
    }
    // XXX: SUCCESS _even if nothing is read_?  The old code does this.
    result = SUCCESS;
  }

  return result;
}

int
Eeprom::write(const Mote& mote, const char * buffer, ssize_t length, ssize_t offset)
{
  int result = FAILURE;

  if(_sanity_check("write", mote, length, offset))
  {
    int base_offset = mote * _mote_size;
    int seek_offset = base_offset + offset;
    
    if (_file->seek_current(seek_offset) == File::SEEK_FAILURE)
    {
      // dbg(DBG_ERROR, "ERROR: Seek in EEPROM for read failed.\n");
    }
    else
    {
      // XXX: In the original code the read is attempted even if the
      // XXX: seek fails.  This doesn't seem right.
      if (_file->write(buffer, length) == File::WRITE_FAILURE)
      {
        // dbg(DBG_ERROR, "ERROR: Read for %i from EEPROM failed: %s.\n", length, strerror(errno));
      }
    }
    // XXX: SUCCESS _even if nothing is written_?  The old code does this.
    result = SUCCESS;
  }

  return result;
}


int
Eeprom::sync()
{
  int result = (_file->sync()) ? SUCCESS : FAILURE;

  return result;
}


bool
Eeprom::_initialize(const char * filename)
{
  bool result = false;
  _file = new File(filename);

  if (!_file)
  {
    // dbg(DBG_ERROR, "ERROR: Unable to create EEPROM backing store file.\n");
  }
  else if (!_file->set_access(File::USER_ALL | File::GROUP_READ | File::OTHER_READ))
  {
    // dbg(DBG_ERROR, "ERROR: Unable to set permissions on EEPROM backing store.\n");
  }
  else
  {
    char value = 0;

    if (_file->seek_current(_mote_size * _n_motes) == File::SEEK_FAILURE)
    {
      // dbg(DBG_ERROR, "ERROR: Unable to establish EEPROM of correct size.\n");
    }
    else
    {
      if (_file->write(&value, sizeof (value)) == File::WRITE_FAILURE)
      {
        // dbg(DBG_ERROR, "ERROR: Unable to establish EEPROM of correct size.\n");      
      }
      else
      {
        result = true;
      }
    }
  }

  return result;
}

bool
Eeprom::_sanity_check(const char * action, const Mote& mote, ssize_t length, ssize_t offset)
{
  int result = false;

  // Sanity check arguments.
  if ((mote < 0) || (mote > _n_motes))
  {
    // dbg(DBG_ERROR, "ERROR: Tried to %s EEPROM of mote %i when it was initialized for only %i motes.\n", action, mote, _n_motes);
  }
  else if ((length + offset) > _mote_size)
  {
    // dbg(DBG_ERROR, "ERROR: Tried to %s EEPROM of mote %i when it was initialized for only %i motes.\n", action, mote, _n_motes);
  }
  else if ((length < 0) || (offset < 0))
  {
    // dbg(DBG_ERROR, "ERROR: Both length and offset for EEPROM %s must be > 0.\n", action);
  }
  else
  {
    result = true;
  }

  return result;
}

} // namespace impl

} // namespace sim
} // namespace tos

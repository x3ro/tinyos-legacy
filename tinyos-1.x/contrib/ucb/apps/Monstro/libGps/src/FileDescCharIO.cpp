// $Id: FileDescCharIO.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

/*                                                                      tab:2
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*
 * @author Cory Sharp
 */

#include "FileDescCharIO.h"

#include "FormStr.h"
#include "GetMicros.h"
#include "wait_for_fd.h"

#include <errno.h>
#include <string.h>

#include <sys/ioctl.h>
#include <sys/time.h>
#include <unistd.h>


//
// private members and data to FileDescCharIO
//
class FileDescCharIO::OpaqueMembers
{
  public:
   
    // input / output file descriptors
  
    int fd_in;
    int fd_out;

    bool wait_for_read( double timeout_seconds )
    {
      //try { return have_first_byte() || wait_for_fd( fd_in, wait_for_fd::Read, timeout_seconds ); }
      //catch( wait_for_fd_error e ) { set_eof(); return false; }
      return have_first_byte() || wait_for_fd( fd_in, wait_for_fd::Read, timeout_seconds );
    }

    bool wait_for_write( double timeout_seconds )
    {
      //try { return wait_for_fd( fd_out, POLLOUT, timeout_seconds, "FileDescCharIO::wait_for_write" ); }
      //catch( FDHUP_error e ) { throw error( "FileDescCharIO, could not wait for write, got HUP" ); }
      return wait_for_fd( fd_out, wait_for_fd::Write, timeout_seconds );
    }


    // for detecting an end of file and possibly returning the char that was consumed
    // to detect eof

    enum Eof_Enum { Eof_True = -1, Eof_False = -2 };
    int n_char_eof;

    void set_eof() { n_char_eof = Eof_True; }
    void clear_eof() { n_char_eof = Eof_False; }

    bool have_first_byte() { return n_char_eof >= 0; }
    char get_first_byte() { const char ch = n_char_eof; clear_eof(); return ch; }
    void put_first_byte( char ch ) { n_char_eof = static_cast<unsigned char>(ch); }

    //
    // test_for_eof
    // test the stream for end of file
    // throw eof if so
    //
    void test_for_eof()
    {
      if( n_char_eof == Eof_False )
      {
	char ch;
	int read_rv = ::read( fd_in, &ch, 1 );
	if( read_rv == 0 ) 
	  set_eof();
	else if( read_rv == 1 ) 
	  put_first_byte( ch );
	else if( (read_rv == -1) && !((errno == EAGAIN) || (errno == EINTR)) )
	  throw BlockIO_error( FormStr( "FileDescCharIO::test_for_eof, %s", strerror( errno ) ) );
      }

      if( n_char_eof == Eof_True )
	throw BlockIO_eof();
    }
};


//
// default constructor
//
FileDescCharIO::FileDescCharIO() 
  : m( new OpaqueMembers() )
{ 
  set_fd_io( -1, -1 ); 
}


//
// constructor given input and output file descriptors
//
FileDescCharIO::FileDescCharIO( int fd_in, int fd_out ) 
  : m( new OpaqueMembers() )
{ 
  set_fd_io( fd_in, fd_out ); 
}


//
// copy constructor 
// nearly simulating what would have otherwise been a shallow copy
//
FileDescCharIO::FileDescCharIO( const FileDescCharIO& a )
{ 
  *this = a;
  *(m = new OpaqueMembers()) = *a.m;
}

 
//
// destructor
//
FileDescCharIO::~FileDescCharIO()
{
  delete m;
}


//
// throw_BlockIO_error
//
void FileDescCharIO::throw_BlockIO_error( const char* funcname, const char* errmsg )
{
  throw BlockIO_error( FormStr( "%s, %s", funcname, errmsg ) );
}


//
// set_fd_io
// set the input and output file descriptors
//
void FileDescCharIO::set_fd_io( int fd_in, int fd_out )
{ 
  m->fd_in = fd_in; 
  m->fd_out = fd_out; 
  m->clear_eof();
}


//
// get_fd_in
// get the input file descriptor
//
int FileDescCharIO::get_fd_in() const 
{ 
  return m->fd_in;
}


//
// get_fd_out
// get the output file descriptor
//
int FileDescCharIO::get_fd_out() const 
{ 
  return m->fd_out; 
}


//
// wait_for_read
// return true if more than zero bytes exist to be read
//
bool FileDescCharIO::wait_for_read( double timeout_seconds /* = -1 */ ) 
{
  if( m->fd_in == -1 ) throw BlockIO_eof();
  m->test_for_eof();
  return m->wait_for_read( timeout_seconds );
}


//
// wait_for_write
// return true if more than zero can successfully be written
//
bool FileDescCharIO::wait_for_write( double timeout_seconds /* = -1 */ ) 
{
  //if( m->fd_out == -1 ) throw BlockIO_eof();
  if( m->fd_out == -1 ) return true;
  return m->wait_for_write( timeout_seconds );
}


//
// read
// read at most n characters from the input, block at most timeout_seconds
//
FileDescCharIO::size_type FileDescCharIO::read( data_type* buf, size_type n, double timeout_seconds /* = -1 */ ) 
{ 
  if( m->fd_in == -1 ) throw BlockIO_eof();

  double t0 = (timeout_seconds > 0) ? (1e-6 * GetMicros()) : 0;
  const char* funcname = "FileDescCharIO::read";

  m->test_for_eof();

  // if zero bytes are requested, return zero
  if( n == 0 )
    return 0;

  // test if we already have the first byte
  // if so, write it out right now, and adjust everyone appropriately
  size_type nread = 0;
  if( m->have_first_byte() ) 
  { 
    *buf = m->get_first_byte();
    nread = 1; 
  }

  // if there are more bytes to read, read them
  // a test for end-of-file as well
  // and throw an error if there's an problem with the read
  while( nread < n )
  {
    int read_rv = ::read( m->fd_in, buf + nread, n - nread ); 

    if( read_rv > 0 )
    {
      // if some bytes were read, count nread, if there's not enough, try again
      nread += read_rv;
    }
    else if( read_rv == 0 ) 
    {
      // if read returned 0, then we're at the end of file, mark it so, and return the bytes we've read
      m->set_eof();
      break;
    }
    else
    {
      // otherwise, read returned -1, if a legitimate error occured, throw it
      if( !((errno == EAGAIN) || (errno == EINTR) || (errno == EPIPE)) )
	throw_BlockIO_error( funcname, strerror( errno ) );

      // otherwise, wait for more data while obeying timeout_seconds
      if( timeout_seconds == 0 )
      {
	// if timeout is zero seconds, then just return with the number (0 or 1) of bytes read
	break;
      }
      else if( timeout_seconds > 0 )
      {
	// If timeout is finite and that amount of time has not elapsed since entering this
	// function, then wait for the for more data to appear.  In either case, if the 
	// timeout elapses, return what data we have.
	double dt = 1e-6 * GetMicros() - t0;
	if( (dt >= timeout_seconds) 
	    || (m->wait_for_read( timeout_seconds - dt ) == false) )
	  break;
      }
      else
      {
	// otherwise, we should wait indefinitely for more data
	if( m->wait_for_read( timeout_seconds ) == false )
	  break;
      }
    }
  }

  // return the number of bytes we're written to buf
  return nread;
}


//
// write
// write at most n characters from the buffer, block at most timeout_seconds
//
FileDescCharIO::size_type FileDescCharIO::write( const data_type* buf, size_type n, double timeout_seconds /* = -1 */ ) 
{ 
  //if( m->fd_out == -1 ) throw BlockIO_eof();
  if( m->fd_out == -1 ) return n;

  double t0 = (timeout_seconds > 0) ? (1e-6 * GetMicros()) : 0;
  const char* funcname = "FileDescCharIO::write";

  m->test_for_eof();

  // if zero bytes are requested, return zero
  if( n == 0 )
    return 0;

  // if there are more bytes to write, write them
  // a test for end-of-file as well
  // and throw an error if there's an problem with the write
  size_type nwrite = 0;
  while( nwrite < n )
  {
    int write_rv = ::write( m->fd_out, buf + nwrite, n - nwrite ); 

    if( write_rv > 0 )
    {
      // if some bytes were written, count nwrite, if there's not enough, try again
      nwrite += write_rv;
    }
    else if( write_rv == 0 ) 
    {
      // if write returned 0, well, huh, I don't know what to do... 
      // briefly sleep and try again I suppose
      ::usleep( 10 );
    }
    else
    {
      // otherwise, write returned -1, if a legitimate error occured, throw it
      if( !((errno == EAGAIN) || (errno == EINTR) || (errno == EPIPE)) )
	throw_BlockIO_error( funcname, strerror( errno ) );

      // otherwise, wait for write to become available again while obeying timeout_seconds
      if( timeout_seconds == 0 )
      {
	// if timeout is zero seconds, then just return with the number (0 or 1) of bytes written
	break;
      }
      else if( timeout_seconds > 0 )
      {
	// If timeout is finite and that amount of time has not elapsed since
	// entering this function, then wait.  In either case, if the timeout
	// elapses, we're done for this call.
	double dt = 1e-6 * GetMicros() - t0;
	if( (dt >= timeout_seconds) 
	    || (m->wait_for_write( timeout_seconds - dt ) == false) )
	  break;
      }
      else
      {
	// otherwise, we should wait indefinitely for more data
	if( m->wait_for_write( timeout_seconds ) == false )
	  break;
      }
    }
  }

  // return the number of bytes we've consumed from buf
  return nwrite;
}


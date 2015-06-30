// $Id: TcpServerCharIO.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#include "TcpServerCharIO.h"

#include "FormStr.h"
#include "GetMicros.h"
#include "StringScan.h"
#include "minmax.h"
#include "wait_for_fd.h"

#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>

#ifdef __CYGWIN32__
#define MSG_NOSIGNAL 0
#define MSG_DONTWAIT 0
#endif


class TcpServerCharIO::OpaqueMembers
{
  public:
    sockaddr_in sin;

    int fd_server;
    int fd_data;

    bool nodelay;

    OpaqueMembers(): fd_server(-1), fd_data(-1), nodelay(true) { }

    class client_data_eof { };

    bool wait_for_server_read( double timeout_seconds )
    {
      wait_for_fd w( fd_server, wait_for_fd::Read | wait_for_fd::Except, timeout_seconds );
      if( w.can_except() ) 
	throw_BlockIO_error( "wait_for_server_read", "I think the server died" );
      return w.can_read();
      return true;
    }

    void throw_BlockIO_error( const char* funcname, const char* errmsg )
    {
      throw BlockIO_error( FormStr( "%s, %s", funcname, errmsg ) );
    }

    bool wait_for_data_read_or_write( 
      TcpServerCharIO* self,
      int event, 
      double timeout_seconds
      );

    size_type do_data_read_or_write( 
      TcpServerCharIO* self,
      bool b_T_read_F_write,
      data_type* buf, 
      size_type n, 
      unsigned int flags,
      double timeout_seconds,
      const char* funcname
      );
};


TcpServerCharIO::TcpServerCharIO()
  : m( new OpaqueMembers() )
{
}


TcpServerCharIO::TcpServerCharIO( const char* _config, const char sep /* = ',' */ ) 
  : m( new OpaqueMembers() )
{
  const char* funcname = "TcpServerCharIO";

  const char sepstr[] = { sep, 0 };
  FormStr fs_config( "%s", _config );
  char* config = fs_config.str();
  char* c1 = StringScan::find_first_of( config, sepstr );

  if( *c1 )
  {
    *c1 = 0;
    const char* s_option = c1+1;
    if( strcmp( s_option, "delay" ) == 0 ) m->nodelay = false;
    else m->throw_BlockIO_error( funcname, FormStr("unknown option \"%s\"",s_option) );
  }

  int n_port = atoi( config );
  listen( n_port );
}


TcpServerCharIO::TcpServerCharIO( const TcpServerCharIO& a )
  : m( new OpaqueMembers() )
{
  *m = *a.m;
}


TcpServerCharIO::~TcpServerCharIO()
{
  close_all();
  delete m;
}


bool TcpServerCharIO::is_server_open()
{
  return ( m->fd_server != -1 );
}


bool TcpServerCharIO::is_data_open()
{
  // if the data file descriptor is -1, then no, we don't have a connection
  if( m->fd_data == -1 )
    return false;

  // if we think it's connected, try peeking one byte
  char ch;
  int rv = ::recv( m->fd_data, &ch, 1, MSG_NOSIGNAL | MSG_PEEK );

  // if we got the byte or the error code says "try again", return true
  if( (rv == 1) || (rv == -1 && errno == EAGAIN) )
    return true;

  // if we got no byte, or the error code says there's no connection
  // close the connection we think we have and return false
  if( (rv == 0) || ((rv == -1) && (errno == EPIPE || errno == ENOTCONN || errno == ECONNRESET)) )
  {
    close_data();
    return false;
  }

  // otherwise, some a legitimate error occurred
  m->throw_BlockIO_error( "TcpServerCharIO::is_data_open", strerror( errno ) );
}


int TcpServerCharIO::get_server_fd()
{
  return m->fd_server;
}


int TcpServerCharIO::get_data_fd()
{
  return m->fd_data;
}


void TcpServerCharIO::close_all()
{
  close_data();
  close_server();
}


void TcpServerCharIO::close_data()
{
  if( m->fd_data != -1 )
  {
    ::close( m->fd_data );
    m->fd_data = -1;
  }
}


void TcpServerCharIO::close_server()
{
  if( m->fd_server != -1 )
  {
    ::close( m->fd_server );
    m->fd_server = -1;
  }
}


void TcpServerCharIO::listen( int port )
{  
  const char* funcname = "TcpServerCharIO::server_listen";

  if( is_server_open() )
    m->throw_BlockIO_error( funcname, "already listening" );
  
  // create socket

  m->fd_server = socket( PF_INET, SOCK_STREAM, 0 );
  if( m->fd_server == -1 ) m->throw_BlockIO_error( funcname, strerror( errno ) );

  // be friendly with the port

  int n_on = 1;
  setsockopt( m->fd_server, SOL_SOCKET, SO_REUSEADDR, &n_on, sizeof(n_on) );

  // name socket using wildcards

  m->sin.sin_family = PF_INET;
  m->sin.sin_addr.s_addr = INADDR_ANY;
  m->sin.sin_port = htons(port);

  if( ::bind( m->fd_server, (sockaddr*)&m->sin, sizeof(m->sin)) == -1 )
    m->throw_BlockIO_error( funcname, strerror( errno ) );

  // start listening for connections
  ::listen( m->fd_server, 1 );
}


// possibly opens a data connection
bool TcpServerCharIO::accept( double timeout_seconds )
{
  const char* funcname = "TcpServerCharIO::server_accept";

  // if the server isn't listening, throw an error
  if( !is_server_open() )
    m->throw_BlockIO_error( funcname, "cannot accept because not listening" );

  // if after a finite timout, no clients are ready to connect, return false
  if( (timeout_seconds >= 0) && !m->wait_for_server_read( timeout_seconds ) )
    return false;

  // close an existing open connection
  close_data();

  // establish a new connection
  m->fd_data = ::accept( m->fd_server, 0, 0 );
  if( m->fd_data == -1 ) m->throw_BlockIO_error( funcname, strerror( errno ) );

  // if nodelay is true, set the socket to nodelay
  if( m->nodelay )
    set_nodelay( true );

  // force the file descriptor to be nonblocking
  fcntl( m->fd_data, F_SETFL, fcntl( m->fd_data, F_GETFL ) | O_NONBLOCK );

  return true;
}


//
// wait_for_data_connection
//
// wait_for_data_connection is the one function that
// directly manages the data connection.
//
bool TcpServerCharIO::wait_for_data_connection( double timeout_seconds /* = -1 */ )
{
  return is_data_open() || accept( timeout_seconds );
}


//
// set nodelay on the socket
// to disable the Nagle algorithm
// and making the socket feel more interactive
//
void TcpServerCharIO::set_nodelay( bool nodelay )
{
  m->nodelay = nodelay;
  if( m->fd_data != -1 )
  {
    int flag = m->nodelay ? 1 : 0;
    int rv = ::setsockopt( 
      m->fd_data,
      SOL_TCP, 
      TCP_NODELAY, 
      (char*)&flag, 
      sizeof(flag) 
      );
    if( rv == -1 )
      m->throw_BlockIO_error( "TcpServerCharIO::set_nodelay", strerror( errno ) );
  }
}


//
// wait_for_read_or_write
//
bool TcpServerCharIO::OpaqueMembers::wait_for_data_read_or_write( 
  TcpServerCharIO* self, 
  int event, 
  double timeout_seconds 
  )
{
  const double t0 = (timeout_seconds > 0) ? 1e-6 * GetMicros() : 0;
  event |= wait_for_fd::Except;

  // if the data connection is open, then wait for data
  // if it throws an exception in that time, close it and move to the next section
  if( self->is_data_open() )
  {
    wait_for_fd wfd = wait_for_fd( fd_data, event, timeout_seconds );
    if( wfd.can_except() ) self->close_data();
    else return wfd.get_result() & (~wait_for_fd::Except);
  }

  // the data connection is closed, try to open it, then wait for data
  // obey the given timeout_seconds
  double dt;
  while( true )
  {
    dt = (timeout_seconds > 0) ? max<double>(0, timeout_seconds + t0 - 1e-6 * GetMicros()) : timeout_seconds;
    if( ! self->wait_for_data_connection( dt ) )
      return false;

    dt = (timeout_seconds > 0) ? max<double>(0, timeout_seconds + t0 - 1e-6 * GetMicros()) : timeout_seconds;
    wait_for_fd wfd = wait_for_fd( fd_data, event, timeout_seconds );
    if( wfd.can_except() ) self->close_data();
    else return wfd.get_result() & (~wait_for_fd::Except);

    if( dt == 0 )
      return false;
  }

  return false;
}


//
// do_data_read_or_write
//
TcpServerCharIO::size_type TcpServerCharIO::OpaqueMembers::do_data_read_or_write( 
  TcpServerCharIO* self,
  bool b_T_read_F_write,
  data_type* buf, 
  size_type n, 
  unsigned int flags,
  double timeout_seconds,
  const char* funcname
  )
{
  typedef int (*read_write_cmd_type)( int, void*, int, unsigned int );

  double t0 = timeout_seconds <= 0 ? 0 : 1e-6 * GetMicros();

  // try to read some data and see what happens
  size_type ndone = 0;
  while( ndone < n )
  {
    // if a data connection doesn't exist, try to make one
    // otherwise, return only after there's some data to read/write or the timeout has elapsed
    double dt = timeout_seconds <= 0 ? timeout_seconds : max<double>( 0, timeout_seconds + t0 - 1e-6 * GetMicros() );
    int rv = 0;
    if( b_T_read_F_write )
    {
      // we have a connection, read some data
      if( self->wait_for_read( timeout_seconds ) == false ) break;
      rv = ::recv( fd_data, buf + ndone, n - ndone, flags );
    }
    else
    {
      // we have a connection, write some data
      if( self->wait_for_write( timeout_seconds ) == false ) break;
      rv = ::send( fd_data, buf + ndone, n - ndone, flags );
    }

    if( rv > 0 )
    {
      // did some data... count it and try for some more
      ndone += rv;
    }
    else if( rv == 0 )
    {
      // got no data... that means the client is eof, close it and try again
      self->close_data();
    }
    else if( rv == -1 )
    {
      // if EAGAIN or EINTR, no data was read, wait for some data
      // if EPIPE or ENOTCONN or ECONNRESET, then the client isn't connected, close and try again
      // otherwise, a legitimate error has occurred, throw it
      if( errno == EAGAIN || errno == EINTR || errno == ECONNRESET ) { }
      else if( errno == EPIPE || errno == ENOTCONN ) { self->close_data(); }
      else { throw_BlockIO_error( funcname, FormStr( "%s (errno=%d)", strerror( errno ), errno ) ); }
    }
    else
    {
      throw_BlockIO_error( funcname, "recv/send behaved unexpectedly " );
    }

    // oh, and if the remaining timeout has gotten down to zero, we're done
    if( dt == 0 )
      break;
  }

  // otherwise, something valid happened, return the number of bytes read
  return static_cast<size_type>( ndone );
}



//---
//--- standard interface
//---


//
// wait_for_read
//
bool TcpServerCharIO::wait_for_read( double timeout_seconds /* = -1 */ )
{
  return m->wait_for_data_read_or_write( this, wait_for_fd::Read, timeout_seconds );
}


//
// wait_for_write
//
bool TcpServerCharIO::wait_for_write( double timeout_seconds /* = -1 */ )
{
  return m->wait_for_data_read_or_write( this, wait_for_fd::Write, timeout_seconds );
}


//
// read
//
TcpServerCharIO::size_type TcpServerCharIO::read( data_type* buf, size_type n, double timeout_seconds /* = -1 */ )
{
  return m->do_data_read_or_write( 
    this, 
    true,
    buf, 
    n, 
    MSG_NOSIGNAL, 
    timeout_seconds, 
    "TcpServerCharIO::read"
    );
}

//
// write
//
TcpServerCharIO::size_type TcpServerCharIO::write( const data_type* buf, size_type n, double timeout_seconds /* = -1 */ )
{
  return m->do_data_read_or_write( 
    this, 
    false,
    (data_type*)buf, 
    n, 
    MSG_NOSIGNAL | MSG_DONTWAIT, 
    timeout_seconds, 
    "TcpServerCharIO::write"
    );
}



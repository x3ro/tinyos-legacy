// $Id: TcpClientCharIO.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#include "TcpClientCharIO.h"

#include "FormStr.h"
#include "StringScan.h"

#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <string.h>
#include <unistd.h>
#include <netinet/tcp.h>
#include <sys/types.h>
#include <sys/socket.h>


TcpClientCharIO::TcpClientCharIO() 
  : FileDescCharIO(), m_nodelay( true )
{
}


TcpClientCharIO::TcpClientCharIO( const char* _config, const char sep /* = ',' */ ) 
  : FileDescCharIO(), m_nodelay( true )
{
  const char* funcname = "TcpClientCharIO(config,sep)";

  const char sepstr[] = { sep, 0 };
  FormStr fs_config( "%s", _config );
  char* config = fs_config.str();
  char* c1 = StringScan::find_first_of( config, sepstr );
  char* c2 = StringScan::find_first_of( StringScan::find_first_not_of( c1, sepstr ), sepstr );
  const char* s_option = c2;

  if( *c1 == 0 )
    throw_BlockIO_error( funcname, FormStr("config string expects \"host%cport\"",sep) );
  *c1 = 0;

  if( *c2 != 0 )
  {
    *c2 = 0;
    s_option++;
    if( strcmp( s_option, "delay" ) == 0 ) m_nodelay = false;
    else throw_BlockIO_error( funcname, FormStr("unknown option \"%s\"",s_option) );
  }

  const char* s_host = config;
  const char* s_port = c1 + 1;
  int n_port = atoi( s_port );

  connect( s_host, n_port );
}


TcpClientCharIO::~TcpClientCharIO()
{
  close();
}


void TcpClientCharIO::close()
{
  if( FileDescCharIO::get_fd_in() != -1 )
  {
    ::close( FileDescCharIO::get_fd_in() );
    FileDescCharIO::set_fd_io( -1, -1 );
  }
}


void TcpClientCharIO::connect( const char* host, int port )
{
  const char* funcname = "TcpClientCharIO::clientOpen";

  // close an existing connection if necessary
  close();

  // create socket
  hostent* pHost = gethostbyname( host );
  if( pHost == 0 )
    throw_BlockIO_error( funcname, FormStr( "unknown host \"%s\"", host ) );

  int fd = socket( PF_INET, SOCK_STREAM, 0 );
  if( fd == -1 )
    throw_BlockIO_error( funcname, strerror( errno ) );

  m_sin.sin_family = PF_INET;
  memcpy( &m_sin.sin_addr, pHost->h_addr, pHost->h_length );
  m_sin.sin_port = htons( port );

  // connect socket
  if( ::connect(fd, (sockaddr*)&m_sin, sizeof(m_sin)) == -1 )
    throw_BlockIO_error( funcname, strerror( errno ) );

  // force the file descriptor to be nonblocking
  fcntl( fd, F_SETFL, fcntl( fd, F_GETFL ) | O_NONBLOCK );

  // if nodelay is true, set it as such
  if( m_nodelay )
    set_nodelay( true );

  // attach fd to this FileDescCharIO
  FileDescCharIO::set_fd_io( fd, fd );
}


void TcpClientCharIO::set_nodelay( bool nodelay )
{
  m_nodelay = nodelay;
  if( FileDescCharIO::get_fd_in() != -1 )
  {
    int flag = m_nodelay ? 1 : 0;
    int rv = ::setsockopt( 
      FileDescCharIO::get_fd_in(), 
      SOL_TCP, 
      TCP_NODELAY, 
      (char*)&flag, 
      sizeof(flag) 
      );
    if( rv == -1 )
      throw_BlockIO_error( "TcpClientCharIO::set_nodelay", strerror( errno ) );
  }
}


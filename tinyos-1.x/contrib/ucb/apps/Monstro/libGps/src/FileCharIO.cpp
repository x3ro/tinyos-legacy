// $Id: FileCharIO.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#include "FileCharIO.h"

#include "BlockIO.h"

#include "FormStr.h"
#include "StringScan.h"
#include "StdCharIO.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

FileCharIO::FileCharIO()
  : m_std_io(new StdCharIO()), m_b_close_fd_in(false), m_b_close_fd_out(false)
{
}


FileCharIO::FileCharIO( const char* _config, const char sep /* = ',' */ )
  : m_std_io(0), m_b_close_fd_in(false), m_b_close_fd_out(false)
{
  const char* funcname = "FileCharIO(config,sep)";

  const char sepstr[] = { sep, 0 };
  FormStr fs_config( "%s", _config );
  char* config = fs_config.str();
  char* c1 = StringScan::find_first_of( config, sepstr );

  if( *c1 == 0 )
    throw_BlockIO_error( funcname, FormStr("config string expects \"file%cfile\"",sep) );
  *c1 = 0;

  const char* s_file_in = config;
  const char* s_file_out = c1 + 1;

  int fd_in = -1;
  int fd_out = -1;

  if( strcmp( s_file_in, "-" ) == 0 ) 
  { 
    m_std_io = new StdCharIO(); 
    fd_in = m_std_io->get_fd_in(); 
  }
  else if( (*s_file_in == 0) || (strcmp( s_file_in, "0" ) == 0) )
  {
    fd_in = -1;
  }
  else 
  {
    if( (fd_in = ::open( s_file_in, O_RDONLY | O_NONBLOCK )) == -1 )
      throw_BlockIO_error( funcname, FormStr("could not open %s for reading",s_file_in) );
    m_b_close_fd_in = true;
  }

  if( strcmp( s_file_out, "-" ) == 0 )
  {
    if( m_std_io == 0 ) m_std_io = new StdCharIO();
    fd_out = m_std_io->get_fd_out();
  }
  else if( (*s_file_out == 0) || (strcmp( s_file_out, "0" ) == 0) )
  {
    fd_out = -1;
  }
  else
  {
    if( (fd_out = ::open( s_file_out, O_WRONLY | O_CREAT | O_TRUNC | O_NONBLOCK, 0666 )) == -1 )
    {
      if( m_std_io ) delete m_std_io;
      if( m_b_close_fd_in ) ::close( fd_in );
      throw_BlockIO_error( funcname, FormStr("could not open %s for writing",s_file_out) );
    }
    m_b_close_fd_out = true;
  }

  FileDescCharIO::set_fd_io( fd_in, fd_out );
}


FileCharIO::~FileCharIO()
{
  delete m_std_io;
  if( m_b_close_fd_in )  ::close( get_fd_in() );
  if( m_b_close_fd_out ) ::close( get_fd_out() );
}


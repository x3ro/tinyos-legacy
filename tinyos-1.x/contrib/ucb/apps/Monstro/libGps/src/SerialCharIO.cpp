// $Id: SerialCharIO.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#include "SerialCharIO.h"

#include "FormStr.h"
#include "StringScan.h"

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#include <iostream>
#include <fstream>


// default constructor
SerialCharIO::SerialCharIO() 
  : m_bOldTermValid( false )
{
}


// constructor
SerialCharIO::SerialCharIO( const char* device, tcflag_t flags ) 
  : m_bOldTermValid( false )
{
  openSerial( device, flags );
}


// constructor, create from a string specification
SerialCharIO::SerialCharIO( const char* _config, const char sep /* = ',' */ )
  : m_bOldTermValid( false )
{
  const char* funcname = "SerialCharIO(config,sep)";
  const char sepstr[] = { sep, 0 };
  FormStr fs_config( "%s", _config );
  char* config = fs_config.str();
  char* c1 = StringScan::find_first_of( config, sepstr );

  if( *c1 == 0 )
    throw_BlockIO_error( funcname, FormStr("config string expect \"device%cbaud\"",sep) );
  *c1 = 0;

  const char* s_device = config;
  const char* baud_str = c1 + 1;

  int baud_flag = 0;
  int baud_num = atol( baud_str );

  switch( baud_num )
  {
    case      50 : baud_flag = B50; break;
    case      75 : baud_flag = B75; break;
    case     110 : baud_flag = B110; break;
    case     134 : baud_flag = B134; break;
    case     150 : baud_flag = B150; break;
    case     200 : baud_flag = B200; break;
    case     300 : baud_flag = B300; break;
    case     600 : baud_flag = B600; break;
    case    1200 : baud_flag = B1200; break;
    case    1800 : baud_flag = B1800; break;
    case    2400 : baud_flag = B2400; break;
    case    4800 : baud_flag = B4800; break;
    case    9600 : baud_flag = B9600; break;
    case   19200 : baud_flag = B19200; break;
    case   38400 : baud_flag = B38400; break;
    case   57600 : baud_flag = B57600; break;
    case  115200 : baud_flag = B115200; break;
#if 0
    case  230400 : baud_flag = B230400; break;
    case  460800 : baud_flag = B460800; break;
    case  500000 : baud_flag = B500000; break;
    case  576000 : baud_flag = B576000; break;
    case  921600 : baud_flag = B921600; break;
    case 1000000 : baud_flag = B1000000; break;
    case 1152000 : baud_flag = B1152000; break;
    case 1500000 : baud_flag = B1500000; break;
    case 2000000 : baud_flag = B2000000; break;
    case 2500000 : baud_flag = B2500000; break;
    case 3000000 : baud_flag = B3000000; break;
    case 3500000 : baud_flag = B3500000; break;
    case 4000000 : baud_flag = B4000000; break;
#endif
    default:
      throw_BlockIO_error( funcname, FormStr( "unknown baud rate %d (\"%s\")", baud_num, baud_str ) );
  }

  openSerial( s_device, baud_flag );
}


// destructor
SerialCharIO::~SerialCharIO()
{
  closeSerial();
}


// open serial stream
void SerialCharIO::openSerial( const char* device, int baud )
{
//std::ofstream ofs( "css-debug.txt", std::ios::app );
//ofs << "SerialCharIO::openSerial: entry" << std::endl;
  const char* funcname = "SerialCharIO::openSerial";

  // if the old term is set, don't try to open again
  if( m_bOldTermValid )
    throw_BlockIO_error( funcname, "called on an already open SerialCharIO" );

  // open the device
  int fd = ::open( device, O_RDWR | O_NONBLOCK | O_NDELAY | O_NOCTTY );
  if( fd == -1 )
    throw_BlockIO_error( funcname, FormStr("open(), %s",strerror( errno )) );

  char* extraerr = 0;
  // fake while loop for branching to common error handling code, below
  while( true )
  {
    // save current port settings
    if( tcgetattr( fd, &m_tioOldTerm ) == -1 )
    {
      extraerr = "tcgetattr()";
      break;
    }

    if( tcflush( fd, TCIFLUSH ) == -1 )
    {
      extraerr = "tcflush()";
      break;
    }

    // set new port settings for non-canonical input processing
    termios tioNew = m_tioOldTerm;

    // control options
    tioNew.c_cflag &= ~(PARENB | CSTOPB | CSIZE | CRTSCTS | CBAUD);
    tioNew.c_cflag |= (CS8 | CLOCAL | CREAD);

    cfsetispeed( &tioNew, baud );
    cfsetospeed( &tioNew, baud );
    
    // line options
    tioNew.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);

    // input options
    tioNew.c_iflag &= ~(IXON | IXOFF | IXANY);

    // output options
    tioNew.c_oflag &= ~OPOST;

    // control character options
    tioNew.c_cc[VMIN]  = 1; // wait until 1 characters read
    tioNew.c_cc[VTIME] = 0; // inter-character timer unused

    if( tcsetattr( fd, TCSANOW, &tioNew ) == -1 )
    {
      extraerr = "tcsetattr()";
      break;
    }
 
    // set the file descriptors for FileDescCharIO and declare that m_tioOldTerm is valid
    FileDescCharIO::set_fd_io( fd, fd );
    m_bOldTermValid = true;

//ofs << "SerialCharIO::openSerial: exit" << std::endl;

    // return without error
    return;
  }

  // if here, then an error in the C runtime library occurred
  const char* errmsg = strerror( errno );
  ::close( fd );
  throw_BlockIO_error( funcname, FormStr("%s, %s",extraerr,errmsg) );
}



// close serial stream
void SerialCharIO::closeSerial()
{
//std::ofstream ofs( "css-debug.txt", std::ios::app );
//ofs << "SerialCharIO::closeSerial: entry" << std::endl;

  if( m_bOldTermValid )
  {
//ofs << "SerialCharIO::closeSerial: old term valid" << std::endl;
    int fd = FileDescCharIO::get_fd_in();
    const char* errmsg = 0;

    if( ::tcflush( fd, TCIFLUSH ) == -1 )
      errmsg = strerror( errno );

    if( (::tcsetattr( fd, TCSANOW, &m_tioOldTerm ) == -1) && (errmsg == 0) )
      errmsg = strerror( errno );

//ofs << "SerialCharIO::closeSerial: closing fd" << std::endl;
    if( (::close( fd ) == -1) && (errmsg == 0) )
      errmsg = strerror( errno );
//ofs << "SerialCharIO::closeSerial: closed fd" << std::endl;

    m_bOldTermValid = false;
    FileDescCharIO::set_fd_io( -1, -1 );

    if( errmsg )
      throw_BlockIO_error( "SerialCharIO::closeSerial", errmsg );
  }
//ofs << "SerialCharIO::closeSerial: exit" << std::endl;
}


// $Id: ArbCharIO.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#include "ArbCharIO.h"
#include "StringScan.h"
#include "FormStr.h"

#include "BlockIO.h"
#include "FileCharIO.h"
#include "NullCharIO.h"
#include "SerialCharIO.h"
#include "StdCharIO.h"
#include "TcpClientCharIO.h"
#include "TcpServerCharIO.h"
#include "ZeroCharIO.h"

#include <string.h>
#include <vector>


#if 0
ArbCharIO::ArbCharIO()
  : m_io( new NullCharIO() )
{
}
#endif


ArbCharIO::ArbCharIO( const char* config /* = 0 */, const char sep /* = ',' */ )
  : m_io(0)
{
  reopen( config ? config : "null", sep );
}


ArbCharIO::~ArbCharIO()
{
  delete m_io;
}


void ArbCharIO::reopen( const char* _config, const char sep /* = ',' */ )
{
  const char* funcname = "ArbCharIO::reopen";
  delete m_io;
  m_io = 0;
  
  const char sepstr[] = { sep, 0 };
  FormStr fs_config( "%s", _config );
  char* config = fs_config.str();
  char* c1 = StringScan::find_first_of( config, sepstr );

  const char* s_io = config;
  const char* s_param = *c1 ? c1 + 1 : c1;
  *c1 = 0;

  if( strcmp( s_io, "null" ) == 0 ) m_io = new NullCharIO();
  else if( strcmp( s_io, "files"     ) == 0 ) m_io = new FileCharIO( s_param, sep );
  else if( strcmp( s_io, "serial"    ) == 0 ) m_io = new SerialCharIO( s_param, sep );
  else if( strcmp( s_io, "stdio"     ) == 0 ) m_io = new StdCharIO();
  else if( strcmp( s_io, "tcp"       ) == 0 ) m_io = new TcpClientCharIO( s_param, sep );
  else if( strcmp( s_io, "tcplisten" ) == 0 ) m_io = new TcpServerCharIO( s_param, sep );
  else if( strcmp( s_io, "zero"      ) == 0 ) m_io = new ZeroCharIO();
  else throw BlockIO_error( FormStr("%s, unknown iotype \"%s\"",funcname,s_io) );
}


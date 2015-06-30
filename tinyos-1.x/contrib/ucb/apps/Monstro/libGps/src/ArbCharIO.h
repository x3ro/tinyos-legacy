// $Id: ArbCharIO.h,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#ifndef _H_ArbCharIO_h
#define _H_ArbCharIO_h

#include "BlockIO.h"
#include <string>

class ArbCharIO : public BlockIO<char>
{
  public:
    typedef BlockIO<data_type> char_io_type;
    typedef std::string string_type;

  private:
    char_io_type* m_io;

  public:
    //ArbCharIO();
    ArbCharIO( const char* config = 0, const char sep = ',' );
    virtual ~ArbCharIO();

    char_io_type* get_char_io() const { return m_io; }
    void reopen( const char* config, const char sep = ',' );

    // standard interface, see BlockIO.h for details

    virtual bool wait_for_read( double timeout_seconds = -1 )
      { return m_io->wait_for_read( timeout_seconds ); }

    virtual bool wait_for_write( double timeout_seconds = -1 )
      { return m_io->wait_for_write( timeout_seconds ); }

    virtual size_type read( data_type* buf, size_type n, double timeout_seconds = -1 )
      { return m_io->read( buf, n, timeout_seconds ); }

    virtual size_type write( const data_type* buf, size_type n, double timeout_seconds = -1 )
      { return m_io->write( buf, n, timeout_seconds ); }
};

#endif // _H_ArbCharIO_h


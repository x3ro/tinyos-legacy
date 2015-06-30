// $Id: FileDescCharIO.h,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#ifndef _H_FileDescCharIO_h
#define _H_FileDescCharIO_h

#include "BlockIO.h"


class FileDescCharIO : public BlockIO<char>
{
    // Experimenting with opaque private data and members to find out how I
    // like it in practice.  This is good testcase, since so many other classes
    // already use or inherit this class.
    class OpaqueMembers;
    OpaqueMembers* m;

  protected:
    void throw_BlockIO_error( const char* funcname, const char* errmsg );

  public:
    FileDescCharIO();
    FileDescCharIO( int fdIn, int fdOut );
    FileDescCharIO( const FileDescCharIO& a );
    virtual ~FileDescCharIO();

    void set_fd_io( int fdIn, int fdOut );
    int get_fd_in() const;
    int get_fd_out() const;

    // standard interface, see BlockIO.h for details
    virtual bool wait_for_read( double timeout_seconds = -1 );
    virtual bool wait_for_write( double timeout_seconds = -1 );
    virtual size_type read( data_type* buf, size_type n, double timeout_seconds = -1 );
    virtual size_type write( const data_type* buf, size_type n, double timeout_seconds = -1 );
};

#endif // _H_FileDescCharIO_h


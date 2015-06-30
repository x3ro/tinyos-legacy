// $Id: TcpServerCharIO.h,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#ifndef _H_TcpServerCharIO_h
#define _H_TcpServerCharIO_h

#include "BlockIO.h"

class TcpServerCharIO : public BlockIO<char>
{
  private:
    class OpaqueMembers;
    OpaqueMembers* m;

  public:
    TcpServerCharIO();
    TcpServerCharIO( const char* config, const char sep = ',' );
    TcpServerCharIO( const TcpServerCharIO& a );
    virtual ~TcpServerCharIO();

    // server and data
    void close_all();

    // server
    bool is_server_open();
    void close_server();
    int get_server_fd();
    void listen( int port );
    bool accept( double timeout_seconds );

    // data
    bool is_data_open();
    void close_data();
    int get_data_fd();
    bool wait_for_data_connection( double timeout_seconds = -1 );
    void set_nodelay( bool nodelay );
    
    // standard BlockIO interface
    virtual bool wait_for_read( double timeout_seconds = -1 );
    virtual bool wait_for_write( double timeout_seconds = -1 );
    virtual size_type read( data_type* buf, size_type n, double timeout_seconds = -1 );
    virtual size_type write( const data_type* buf, size_type n, double timeout_seconds = -1 );
};

#endif // _H_TcpServerCharIO_h


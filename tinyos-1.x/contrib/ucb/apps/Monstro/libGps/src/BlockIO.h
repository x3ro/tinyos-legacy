// $Id: BlockIO.h,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#ifndef _H_BlockIO_h
#define _H_BlockIO_h

#include <iostream>
#include <stdexcept>


// a BlockIO_error may be thrown given any error on the stream
class BlockIO_error : public std::runtime_error
{ public: BlockIO_error( const char* msg ) : runtime_error( msg ) { std::cerr << "BlockIO_error=" << msg << std::endl; } };


// throw when a function meets end-of-file
class BlockIO_eof : public BlockIO_error
{ public: BlockIO_eof() : BlockIO_error( "EOF" ) { } };


template <class T> class BlockIO 
{
  public:
    typedef unsigned int size_type;
    typedef T data_type;

    // we absolutely need a virtual destructor
    virtual ~BlockIO() { }

    // timeout_seconds < 0  : block indefinitely
    // timeout_seconds == 0 : return immediately
    // timeout_seconds > 0  : block up to timeout_seconds for read/write availability

    // wait_for_read  wait_for_write
    // wait until a call to read or write will probably return more than 0

    virtual bool wait_for_read( double timeout_seconds = -1 ) = 0;
    virtual bool wait_for_write( double timeout_seconds = -1 ) = 0;

    // read  write
    // read/write at most n items from/to the given character buffer
    // return the number of items actually read/written

    virtual size_type read( data_type* buf, size_type n, double timeout_seconds = -1 ) = 0;
    virtual size_type write( const data_type* buf, size_type n, double timeout_seconds = -1 ) = 0;
};


typedef BlockIO<char> BlockIO_char_type;


#endif // _H_BlockIO_h


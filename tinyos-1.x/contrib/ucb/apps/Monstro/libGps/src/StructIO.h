// $Id: StructIO.h,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#ifndef _H_StructIO_h
#define _H_StructIO_h

#include "BlockIO.h"
#include <string>


//
// Manage atomic structure input/output
//
// The template class must provide a member function to_string() that returns
// the structure ready for transmission as a std::string.
//
template <class T> class StructIO : public BlockIO<T>
{
    class OpaqueMembers;
    OpaqueMembers* m;
    friend class OpaqueMembers;

  protected:

    // A derived class must define extract_structs, which scans bytes from the
    // input for a complete data structure.  With each complete data structure
    // read, the derived class must call append_to_input_buffer to prepare it
    // for some future call to read, block_until_input, or get_num_input.

    virtual void extract_structs( std::string& input ) = 0;
  
  public:

    typedef T data_type;
    typedef BlockIO<char> char_io_type;
    typedef char_io_type::size_type size_type;

    StructIO( char_io_type* io = 0 );
    StructIO( const StructIO& a );
    virtual ~StructIO();

    // set the IO interface for reading/writing bytes
    // null (0) is okay, it'll default to a null IO device
    virtual void set_char_io( char_io_type* io );
    char_io_type* get_char_io();
    bool flush(); // returns true if still more data exists to be flushed

    // for putting stuff on the StructIO io buffers
    void append_to_input_buffer( const T& data );
    void append_to_output_buffer( const std::string& output );

    // standard BlockIO interface
    virtual bool wait_for_read( double timeout_seconds = -1 );
    virtual bool wait_for_write( double timeout_seconds = -1 );
    virtual size_type read( data_type* buf, size_type n, double timeout_seconds = -1 );
    virtual size_type write( const data_type* buf, size_type n, double timeout_seconds = -1 );
};


#endif //_H_StructIO_h


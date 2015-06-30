// $Id: string_utils.h,v 1.1 2005/04/21 23:20:45 shawns Exp $

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

#ifndef _H_string_utils_h
#define _H_string_utils_h

#include <string>


//
// IsMachineLSB
//
// test if machine is least-significant-byte first
//
// With compiler optimizations (-O2 in egcs/gcc), not only will this functor be
// inlined away, but the unvisited branch of an if-else statement will be
// compiled away, as well.  Too fancy.
//
union IsMachineLSB
{
  private:
    char ch;
    int i;
  public:
    IsMachineLSB(): i(1) { }
    inline operator bool() const { return ch == 1; }
};


namespace string_utils
{
  template <class data_type> data_type extract_lsb_first( const char* str )
  {
    union data_union
    {
      char bytes[ sizeof(data_type) ];
      data_type value;
    } u;

    if( IsMachineLSB() ) std::copy( str, str + sizeof(data_type), u.bytes );
    else std::copy_backward( str, str + sizeof(data_type), u.bytes ); // XXX FIXME XXX WRONG!!!!
    return u.value;
  }

  template <class data_type> void append_lsb_first( std::string& s, const data_type val )
  {
    const char* data = reinterpret_cast<const char*>(&val);
    if( IsMachineLSB() ) s.append( data, sizeof(data_type) ); 
    else { for( int i=sizeof(data_type)-1; i>=0; --i ) s += data[i]; }
  }
}


#endif // _H_string_utils_h


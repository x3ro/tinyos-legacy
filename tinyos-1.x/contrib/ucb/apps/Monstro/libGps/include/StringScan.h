// $Id: StringScan.h,v 1.1 2005/04/21 23:20:45 shawns Exp $

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

#ifndef _H_StringScan_h
#define _H_StringScan_h

#include <stdexcept>

namespace StringScan
{

class scan_error : public std::runtime_error { public: scan_error(const char* s): runtime_error(s) { } };


template <class T,class U>
bool is_in_list( T ch, U cs )
{ while((*cs)&&(ch!=*cs)) ++cs; return *cs; }


template <class T,class U>
bool is_in_range( T ch, U cs )
{ while(cs[0]&&cs[1]&&!((ch>=cs[0])&&(ch<=cs[1]))) cs+=2; return cs[0]&&cs[1]; }


template <class T,class U>
T find_first_not_of(T s, U cs)
{ while(*s&&is_in_list(*s,cs)) ++s; return s; }


template <class T,class U>
T find_first_not_of(T s, T send, U cs)
{ while((s!=send)&&is_in_list(*s,cs)) ++s; return s; }


template <class T,class U>
T find_first_of(T s, U cs)
{ while(*s&&!is_in_list(*s,cs)) ++s; return s; }


template <class T,class U>
T find_first_of(T s, T send, U cs)
{ while((s!=send)&&!is_in_list(*s,cs)) ++s; return s; }


//---
//--- ranged tests
//---

template <class T,class U>
T find_first_not_of_range(T s, U cs)
{ while(*s&&is_in_range(*s,cs)) ++s; return s; }


template <class T,class U>
T find_first_not_of_range(T s, T send, U cs)
{ while((s!=send)&&is_in_range(*s,cs)) ++s; return s; }


template <class T,class U>
T find_first_of_range(T s, U cs)
{ while(*s&&!is_in_range(*s,cs)) ++s; return s; }


template <class T,class U>
T find_first_of_range(T s, T send, U cs)
{ while((s!=send)&&!is_in_range(*s,cs)) ++s; return s; }


template <class T>
T sscan_hex( const char* str, const char** strend )
{
  T n = 0;
  const char* s = str;
  while( true )
  {
    if( (*s>='0') && (*s<='9') ) n = (16*n) + ((*s)-'0');
    else if( (*s>='a') && (*s<='f') ) n = (16*n) + ((*s)-'a'+10);
    else if( (*s>='A') && (*s<='F') ) n = (16*n) + ((*s)-'A'+10);
    else break;
    ++s;
  }
  if( strend ) *strend = s;
  if( s == str ) throw scan_error("invalid hex format");
  return n;
}


template <class T>
T sscan_integer( const char* str, const char** strend )
{
  T n = 0;
  bool negate = false;
  if( *str == '-' ) { negate = true; ++str; }
  const char* s = str;
  while( true )
  {
    if( (*s>='0') && (*s<='9') ) n = (10*n) + ((*s)-'0');
    else break;
    ++s;
  }
  if( strend ) *strend = s;
  if( s == str ) throw scan_error("invalid integer format");
  return (negate?-n:n);
}

} // namespace StringScan

#endif  // _H_StringScan_h

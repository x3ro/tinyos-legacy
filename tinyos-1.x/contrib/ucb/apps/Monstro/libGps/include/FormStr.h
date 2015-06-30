// $Id: FormStr.h,v 1.1 2005/04/21 23:20:45 shawns Exp $

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

#ifndef _FORMSTR_H
#define _FORMSTR_H

#include <string>

#include <stdio.h>
#include <stdarg.h>

#ifdef _MSC_VER // Microsoft
#define vsnprintf _vsnprintf
#endif

#define FORMSTR_INITSIZE 128

class FormStr
{
  char* m_data;
  size_t m_size;

protected:
  void resize(size_t size)
  { 
    delete m_data; 
    m_data = 0; 
    m_size = size; 
    if(m_size) { m_data=new char[m_size]; m_data[0]=0; }
  }

public:

  FormStr() : m_data(0), m_size(0) { resize(FORMSTR_INITSIZE); }
  FormStr(const char* fmt, ...) : m_data(0), m_size(0) 
  { resize(FORMSTR_INITSIZE); va_list ap; va_start(ap,fmt); vform(fmt,ap); }
  ~FormStr() { resize(0); }

  //operator char*() { return str(); }
  operator const char*() const { return str(); }
  char* str() { return m_data; }
  const char* str() const { return m_data; }

  FormStr& form( const char* fmt, ... )  { va_list ap; va_start(ap,fmt); return vform(fmt,ap); }
  FormStr& vform( const char* fmt, va_list ap )
  {
    while(true)
    {
      int len = vsnprintf( m_data, m_size, fmt, ap );
      if(len<0) resize(2*m_size);
      else if(static_cast<size_t>(len)>m_size) resize(len+1);
      else break;
    };
    return *this;
  }
};


#endif // _FORMSTR_H

// $Id: StructIO.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#include "StructIO.h"

#include "FormStr.h"
#include "GetMicros.h"
#include "NullCharIO.h"
#include "string_utils.h"

#include <algorithm>
#include <string>
#include <vector>

#include <unistd.h>

template <class T> inline T min( T a, T b )
{ return (a<b)?a:b; }


template <class T>
class StructIO<T>::OpaqueMembers
{
  public:

    char_io_type* char_io;
    NullCharIO null_char_io;
    
    std::string input_data;
    std::string output_data;

    typedef std::vector< data_type > vector_data_type;
    vector_data_type input_structs;

    void snarf_input_bytes();

    size_type get_num_input( StructIO<T>* self )
    {
      snarf_input_bytes();
      self->extract_structs( input_data );
      return input_structs.size();
    }
};


//
// snarf_input_bytes
// read all available bytes from the IO interface into a working string
// 
template <class T>
void StructIO<T>::OpaqueMembers::snarf_input_bytes()
{
  while( true )
  {
    char buffer[1024];
    size_type n = char_io->read( buffer, 1024, 0 );
    if( n > 0 ) input_data.append( buffer, n );
    else break;
  }
}


//
// construct with a given char io
//
template <class T>
StructIO<T>::StructIO( char_io_type* io /* = 0 */ )
  : m( new OpaqueMembers() )
{
  m->char_io = io;
}


//
// copy constructor
//
template <class T>
StructIO<T>::StructIO( const StructIO& a )
  : m( new OpaqueMembers() )
{
  *m = *a.m;
}


//
// virtual destructor
//
template <class T>
StructIO<T>::~StructIO()
{
  delete m;
}


//
// append a struct to the pending input array
//
template <class T>
void StructIO<T>::append_to_input_buffer( const T& data )
{
  m->input_structs.push_back( data );
}

template <class T>
void StructIO<T>::append_to_output_buffer( const std::string& output )
{
  m->output_data += output;
}


//
// wait_for_read
// wait until some are available or until timeout
//
template <class T>
bool StructIO<T>::wait_for_read( double timeout_seconds /* = -1 */ )
{
  // get_num_input does the snarfing of input bytes and extraction of packets
  // if any are available right away, return true
  if( m->get_num_input(this) > 0 )
    return true;

  // if the timeout is 0, return false right away (since no input is avail)
  if( timeout_seconds == 0 )
    return false;

  // grab the current time to obey timeout_seconds
  double t0 = GetMicros() * 1e-6;
  
  // keep scanning for packets until we have at least one packet
  // or until we timeout
  while( true )
  {
    // if the given timeout is negative, wait indefinitely for input bytes to snarf
    // otherwise, wait at most the remaining amount of timeout time
    if( timeout_seconds < 0 ) 
    {
      m->char_io->wait_for_read( timeout_seconds );
    }
    else
    {
      double dt = GetMicros() * 1e-6 - t0;
      if( (dt >= timeout_seconds) || (m->char_io->wait_for_read( timeout_seconds - dt ) == false) )
	return false;
    }

    // snarf of input bytes and extract embeded structures
    // if any are available, return true, otherwise continue looking
    if( m->get_num_input(this) > 0 )
      return true;
  }
}


//
// wait_for_write
//
template <class T>
bool StructIO<T>::wait_for_write( double timeout_seconds /* = -1 */ )
{
  return m->char_io->wait_for_write( timeout_seconds );
}


//
// read
// read at most n structs, calling get_num_input to snarf and extract the packets
// return the number of packets actually read
//
template <class T> 
typename StructIO<T>::size_type StructIO<T>::read( data_type* buf, size_type n, double timeout_seconds /* = -1 */ )
{
  const double t0 = timeout_seconds <= 0 ? timeout_seconds : 1e-6 * GetMicros();
  size_type ndone = 0;

  while( ndone < n )
  {
    size_type navail = min( m->get_num_input(this), n - ndone );
    if( navail == 0 )
    {
      if( timeout_seconds == 0 )
	break;
    }
    else
    {
      std::copy( m->input_structs.begin(), m->input_structs.begin() + navail, buf + ndone );
      m->input_structs.erase( m->input_structs.begin(), m->input_structs.begin() + navail );
      ndone += navail;
    }

    if( ndone != n )
    {
      const double dt = timeout_seconds <= 0 ? timeout_seconds : timeout_seconds + t0 - 1e-6 * GetMicros();
      if( dt == 0 )
	break;
      wait_for_read( dt );
    }
  }

  return ndone;
}


//
// write 
// write the n structs to the output stream
//
template <class T>
typename StructIO<T>::size_type StructIO<T>::write( const data_type* buf, size_type n, double timeout_seconds /* = -1 */ )
{
  for( const data_type* bufend = buf+n; buf != bufend; ++buf )
    m->output_data += buf->to_string();

  if( timeout_seconds == 0 ) 
  { 
    flush(); 
  }
  else if( timeout_seconds < 0 ) 
  { 
    while( flush() ) 
      wait_for_write( -1 ); 
  }
  else 
  { 
    const double t0 = 1e-6 * GetMicros(); 
    while( flush() && ((1e-6 * GetMicros() - t0) < timeout_seconds) ) 
      wait_for_write( -1 ); 
  }
  return n;
}


template <class T>
bool StructIO<T>::flush()
{
  size_type n = m->char_io->write( m->output_data.data(), m->output_data.length(), 0 );
  if( n == m->output_data.length() ) { m->output_data.erase(); return false; }
  else { m->output_data.erase( 0, n ); return true; }
}


//
// set_char_io
// set the IO interface for reading/writing bytes
// this also resets the current, internal read-state
//
template <class T>
void StructIO<T>::set_char_io( char_io_type* io )
{ 
  m->input_data.erase();
  m->char_io = io ? io : &m->null_char_io; 
}


//
// get_char_io
// return the current char IO
//
template <class T>
typename StructIO<T>::char_io_type* StructIO<T>::get_char_io()
{
  return m->char_io;
}


//$Id: ByteQueue.java,v 1.1.1.1 2007/11/05 19:11:22 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

package net.tinyos.comm;

public class ByteQueue
{
  byte buffer[];
  int nbegin;
  int nend;

  int num_free_back()
  {
    return buffer.length - nend;
  }

  void left_justify_into( byte dest[] )
  {
    System.arraycopy( buffer, nbegin, dest, 0, nend-nbegin );
    nend -= nbegin;
    nbegin = 0;
    buffer = dest;
  }

  synchronized void ensure_free( int len )
  {
    // There are nbegin free bytes at the beginning of buffer, and
    // (buffer.length-nend) free bytes at the end of buffer.  If in total there
    // are not enough free bytes to store len bytes, then double the buffer
    // size until it is sufficiently large.  Allocate that buffer and "left
    // justify" the current buffer into the new buffer, then set the new buffer
    // as the current buffer.

    // Otherwise, if there are enough total free bytes, then just left justify
    // the current buffer into itself.

    // Otherwise, if there are enough free bytes at the end of the buffer, do
    // nothing for now.

    if( (nbegin + num_free_back()) < len )
    {
      int newlen = buffer.length * 2;
      int total = available() + len;
      while( newlen < total )
        newlen *= 2;
      left_justify_into( new byte[newlen] );
    }
    else if( num_free_back() < len )
    {
      left_justify_into( buffer );
    }
  }

  synchronized public int available()
  {
    return nend - nbegin;
  }

  synchronized public void push_back( byte b )
  {
    ensure_free(1);
    buffer[nend++] = b;
  }

  synchronized public void push_back( byte b[] )
  {
    push_back( b, 0, b.length );
  }

  synchronized public void push_back( byte b[], int off, int len )
  {
    ensure_free( len );
    System.arraycopy( b, off, buffer, nend, len );
    nend += len;
  }

  synchronized public int pop_front()
  {
    if( available() > 0 )
      return ((int)buffer[nbegin++]) & 255;
    return -1;
  }

  synchronized public int pop_front( byte b[] )
  {
    return pop_front( b, 0, b.length );
  }

  synchronized public int pop_front( byte b[], int off, int len )
  {
    int n = available();
    if( len < n )
      len = n;
    System.arraycopy( buffer, nbegin, b, off, len );
    nbegin += len;
    return len;
  }

  public ByteQueue()
  {
    this(64);
  }

  public ByteQueue( int initial_buffer_length )
  {
    buffer = new byte[ initial_buffer_length ];
    nbegin = 0;
    nend = 0;
  }
}


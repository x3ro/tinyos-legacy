/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: forward_buffers.h,v 1.1 2003/06/02 12:34:18 dlkiskis Exp $

// Description: So how this works is a number of unallocated TOS_Msg's are
// managed by forward_buffer.  When you call alloc_forward_buffer, the return
// value is an unallocated TOS_Msg.  The unallocated TOS_Msg was swapped out
// and the given allocated TOS_Msg was swapped in.  You use that unallocated
// TOS_Msg as the return parameter for a receive event.  You continue using the
// TOS_Msg you passed into alloc_forward_buffer as if it were yours to keep.
// When you're done with your TOS_Msg, probably in a sendDone, you call
// free_forward_buffer on it, where forward_buffer then marks it as
// unallocated.  That TOS_Msg will then be returned by some future call to
// alloc_forward_buffer.  See?  Just an allocation scheme for the swap
// semantics of receiving messages in TinyOS.  Easy as pie.

#ifndef _H_forward_buffers
#define _H_forward_buffers

#include "Routing.h"

enum {
  FORWARD_BUFFER_SIZE = 2,
};


typedef struct {
  TOS_Msg msg_data[ FORWARD_BUFFER_SIZE ];
  TOS_MsgPtr msg[ FORWARD_BUFFER_SIZE ];
  uint8_t first_unused;
} G_forward_buffer_t;

G_forward_buffer_t G_forward_buffer;


void init_forward_buffers()
{
  int ii;
  for( ii=0; ii<FORWARD_BUFFER_SIZE; ii++ )
    G_forward_buffer.msg[ii] = G_forward_buffer.msg_data + ii;
  G_forward_buffer.first_unused = 0;
}


TOS_MsgPtr alloc_forward_buffer( TOS_MsgPtr msg )
{
  if( G_forward_buffer.first_unused < FORWARD_BUFFER_SIZE )
  {
    TOS_MsgPtr tmp = G_forward_buffer.msg[ G_forward_buffer.first_unused ];
    G_forward_buffer.msg[ G_forward_buffer.first_unused ] = msg;
    G_forward_buffer.first_unused++;
    return tmp;
  }
  return 0;
}


void free_forward_buffer( TOS_MsgPtr msg )
{
  TOS_MsgPtr* ii = G_forward_buffer.msg;
  TOS_MsgPtr* iiend = G_forward_buffer.msg + G_forward_buffer.first_unused;
  while( ii != iiend )
  {
    if( *ii == msg )
    {
      TOS_MsgPtr tmp = *ii;
      *ii = *(iiend-1);
      *(iiend-1) = tmp;
      G_forward_buffer.first_unused--;
      return;
    }
    ii++;
  }
}


#endif // _H_forward_buffers


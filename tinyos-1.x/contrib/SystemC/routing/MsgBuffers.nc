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
// $Id: MsgBuffers.nc,v 1.1 2003/10/09 01:14:14 cssharp Exp $

interface MsgBuffers
{
  command result_t init();

  // Debugging code insterted.  Instead of
  //
  //   "call MsgBuffers.alloc();"
  //
  // now use (noting the underscore)
  //
  //   "call MsgBuffers_alloc();"
  //
  // It's a #define in MsgBuffers.h.  When the ohshit timer flushes the msg
  // buffers, a diag msg is radioed with the debug uint8 from each caller.
  // That uint8 is a unique("MsgBuffersDebug"), and the offending allocators
  // can be found with appropriate greps to build/mica2dot/app.c.

  command TOS_MsgPtr debug_alloc( uint8_t debug );
  command TOS_MsgPtr debug_alloc_for_swap( uint8_t debug, TOS_MsgPtr msg_to_alloc );

  command void free( TOS_MsgPtr msg_to_release );
  command void free_and_swap( TOS_MsgPtr msg_to_release, TOS_MsgPtr msg_to_provide );

  command void reset();
  command void report();
}


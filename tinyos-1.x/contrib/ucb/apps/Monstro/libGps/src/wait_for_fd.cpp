// $Id: wait_for_fd.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#include "wait_for_fd.h"

#include "FormStr.h"

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include <errno.h>
#include <string.h>


wait_for_fd::wait_for_fd( int fd, int events, double timeout_seconds )
  : result( 0 )
{
  fd_set fds_read;
  fd_set fds_write;
  fd_set fds_except;

  fd_set* pfds_read = 0;
  fd_set* pfds_write = 0;
  fd_set* pfds_except = 0;
  
  struct timeval tv;
  struct timeval* ptv = (timeout_seconds < 0) ? 0 : &tv;

  if( events & Read )
  {
    pfds_read = &fds_read;
    FD_ZERO( pfds_read );
    FD_SET( fd, pfds_read );
  }

  if( events & Write )
  {
    pfds_write = &fds_write;
    FD_ZERO( pfds_write );
    FD_SET( fd, pfds_write );
  }

  if( events & Except )
  {
    pfds_except = &fds_except;
    FD_ZERO( pfds_except );
    FD_SET( fd, pfds_except );
  }

  if( ptv )
  {
    ptv->tv_sec = static_cast<unsigned int>( timeout_seconds );
    ptv->tv_usec = static_cast<unsigned int>( 1e6 * timeout_seconds - 1e6 * ptv->tv_sec );
  }

  int rv = ::select( fd+1, pfds_read, pfds_write, pfds_except, ptv );

  if( rv > 0 )
  {
    if( pfds_read && FD_ISSET( fd, pfds_read ) ) 
      result |= Read;

    if( pfds_write && FD_ISSET( fd, pfds_write) ) 
      result |= Write;

    if( pfds_except && FD_ISSET( fd, pfds_except) ) 
      result |= Except;
  }
  else if( rv < 0 )
  {
    // don't throw an exception if the error is EINTR
    // if the error is EINTR, just leave (I guess... maybe I should do something else? like loop and try again?)
    if( errno != EINTR )
      throw wait_for_fd_error( FormStr("wait_for_fd, %s",strerror( errno )) );
  }
}



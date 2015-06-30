// $Id: GpsBox.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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
 * @author Shawn Schaffert
 */

#include <unistd.h>
#include "GpsBox.h"
#include "GetMicros.h"

GpsBox::GpsBox( const char* gpsiostr )
  : io_gps( gpsiostr )
  , rfsgps( &io_gps )
  , n_prtkb_updates( rfsgps.getNumPrtkbUpdates() )
  , n_vlhb_updates( rfsgps.getNumVlhbUpdates() )
{
  rfsgps.sendInitCommands();
  rfsgps.requestPeriodicUpdates( 0.1 );
}

RfsGps& GpsBox::rfs() { return rfsgps; }
GpsPrtkb GpsBox::prtkb() { return m_prtkb; }
GpsVlhb GpsBox::vlhb() { return m_vlhb; }

bool GpsBox::iterate( double timeout_seconds )
{
  GetMicros::data_type tbegin = GetMicros();
  GetMicros::data_type timeout = GetMicros::data_type( timeout_seconds * 1e6 );
  int n_iters = 0;

  // block for up to one second until we have updates for both vlhb and prtkb
  while( (n_prtkb_updates == (unsigned int) rfsgps.getNumPrtkbUpdates())
         || (n_vlhb_updates == (unsigned int) rfsgps.getNumVlhbUpdates()) )
  {
    rfsgps.processIO();
    if( n_iters++ > 0 ) { usleep( 1000 ); }

    GetMicros::data_type tnow = GetMicros();
    if( (tnow - tbegin) >= timeout )
      return false;
  }

  // grab the current Prtkb and Vlhb data structures and update count
  m_prtkb = rfsgps.getPrtkb();
  m_vlhb = rfsgps.getVlhb();

  n_prtkb_updates = rfsgps.getNumPrtkbUpdates();
  n_vlhb_updates  = rfsgps.getNumVlhbUpdates();

  // that's it, flush all the streams so our requests go out, etc
  rfsgps.processIO();
  return true;
}


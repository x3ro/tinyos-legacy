// $Id: RfsGps.h,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#ifndef _H_RfsGps_h
#define _H_RfsGps_h

#include "GpsIO.h"


class RfsGps
{
  public:
    typedef GpsIO::char_io_type char_io_type;
    
  private:
    GpsIO m_gps_io;

    GpsPrtkb m_currentPrtkb;
    GpsVlhb  m_currentVlhb;
    double m_originLLH[3];
    double m_currentXYZ[3];
    int m_nPrtkbUpdates;
    int m_nVlhbUpdates;

  public:

    // Construct a GPS object
    RfsGps( char_io_type* io = 0 );

    // On destruction, command the GPS to stop all updates
    // (stop periodic updates from filling the serial buffer)
    ~RfsGps();

    // Process pending input/output to/from the GPS
    void processIO();

    // Return the number of updates made to the current position since construction
    int getNumPrtkbUpdates() { return m_nPrtkbUpdates; }

    //
    int getNumVlhbUpdates() { return m_nVlhbUpdates; }

    // Retrieve the current local XYZ coordinates
    // +x: north   +y: east   +z: down
    //
    // A good idea might be to call processIO then call this member
    // if getNumUpdates changed
    void getCurrentXYZ(double& x, double& y, double& z);
    double getCurrentX();
    double getCurrentY();
    double getCurrentZ();

    // Retrieve the current global LLH coordinantes
    // LLH = latitude, longitude, height
    void getCurrentLLH(double& latitude, double& longitude, double& height);

    // Retrieve the current global LLH deviations
    // LLH = latitude, longitude, height
    void getCurrentLLHDev(double& dev_latitude, double& dev_longitude, double& dev_height);

    // Return the GPS position type
    // Smaller numbers mean more accurate position measurements
    // 
    // From NovAtel MiLLenium GPSCard v4.501 Command Descriptions Manual
    // Table D-3  RTK Status for Position Type 3 (RT-20)
    //   0 - Floating ambiguity solution (converged)
    //   1 - Floating ambiguity solution (not yet converged)
    //   2 - Modeling reference phase
    //   3 - Insufficient observations
    //   4 - Variance exceeds limit
    //   5 - Residual too big
    //   6 - Delta position too big
    //   7 - Negative variance
    //   8 - RTK position not computed
    int getPositionType() { return m_currentPrtkb.status_RTK; }

    // Return the current Prtkb data structure
    const GpsPrtkb& getPrtkb() { return m_currentPrtkb; }

    // Return the current Vlhb data structure
    const GpsVlhb& getVlhb() { return m_currentVlhb; }

    // Initialize the local LLH (lat, long, height) origin
    // Default to the red fire hydrant near the shack at Richmond Field Station
    void initOrigin(
        const double latitude  =   37.913885400636104, 
        const double longitude = -122.33609599269469, 
        const double height    =  -26.2 );

    // Command the GPS to send a single update
    // Note, to send/receive pending data to/from the GPS, processIO must be called
    void requestOneUpdate();

    // Command the GPS module to perform periodic updates every interval seconds
    // Note, to send/receive pending data to/from the GPS, processIO must be called
    void requestPeriodicUpdates(double interval);

    // Stop all (periodic) updates
    void stopAllUpdates();

    // Send basic initialization commands
    void sendInitCommands();

    // Not for general use
    void process_gps_packet( const GpsPacket& packet );

    // write_string
    // send a null-terminated string to the char io device attached
    void write_string( const char* str );
};


#endif // _H_RfsGps_h


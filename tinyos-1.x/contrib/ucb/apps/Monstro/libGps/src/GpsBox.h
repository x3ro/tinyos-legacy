// $Id: GpsBox.h,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#include "ArbCharIO.h"
#include "RfsGps.h"

class GpsBox
{
  public:
  typedef ArbCharIO::char_io_type char_io_type;

  private:
  ArbCharIO io_gps;
  RfsGps rfsgps;

  GpsPrtkb m_prtkb;
  GpsVlhb m_vlhb;

  unsigned int n_prtkb_updates;
  unsigned int n_vlhb_updates;

  public:
  GpsBox( const char* gpsiostr );
  bool iterate( double timeout_seconds );
  RfsGps& rfs();
  GpsPrtkb prtkb();
  GpsVlhb vlhb();
};


#ifdef SWIG

struct GpsPrtkb
{
  int    week;            // week number
  double  time;            // GPS time into week
  double  lag;             // differential lag
  int    sats;            // number of matched satellites (00-12)
  int    sats_RTK;        // number of matched satellites above RTK mask angle
  int    sats_RTK_L1_L2;  // number of matched satellites above RTK mask angle with both L1 & L2 available
  double  latitude;        // latitude
  double  longitude;       // longitude
  double  height;          // height above mean sea level
  double  undulation;      // undulation
  int    id;              // datum id
  double  dev_latitude;    // standard deviation of latitude
  double  dev_longitude;   // standard deviation of longitude
  double  dev_height;      // standard deviation of height
  int    status_solution; // solution status
  int    status_RTK;      // RTK status
  int    pos_type;        // position type
  int    idle;            // idle
  int    station;         // rederence station identification (RTCM: 0-1023, or RTCA: 266305-15179385)
};

struct GpsVlhb
{
  int    week;            // week number (units: weeks)
  double   seconds;          // seconds of week (units: seconds)
  double  latency;          // latency (units: meters per second)
  double  age;              // age (units: seconds)
  double  hspeed;          // horizontal speed (units: meters per second)
  double  tog;              // track over ground (units: degrees)
  double  vspeed;          // vertical speed (units: meters per second)
  int     status_solution;  // solution status
  int    status_velocity;  // velocity status
};

class RfsGps
{
  public:
    int getNumPrtkbUpdates();
    int getNumVlhbUpdates();

    // Retrieve the current local XYZ coordinates
    // +x: north   +y: east   +z: down
    double getCurrentX();
    double getCurrentY();
    double getCurrentZ();

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
};

#endif//SWIG


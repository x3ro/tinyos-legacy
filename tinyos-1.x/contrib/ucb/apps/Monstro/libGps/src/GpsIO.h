// $Id: GpsIO.h,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#ifndef _H_GpsIO_h
#define _H_GpsIO_h

#include "StructIO.h"

#include "types_int.h"
#include "types_float.h"
#include <string>


//
// Raw GPS Packet structure
//
struct GpsPacket
{
  enum message_id_type
  {
    PRTKB = 63,
    VLHB  = 34
  };

  int8 sync[3];
  int8 checksum;
  int32 message_id;
  int32 message_byte_count;
  std::string message;

  void clear();

  void assign_header( const char* data );
  std::string to_string() const;

  uint8 calcChecksum() const;
  int verify(message_id_type expected_id, int expected_bytes) const;
};


//
// Particular field structure of GPS PRTKB message
//
struct GpsPrtkb
{
  int32    week;            // week number
  float64  time;            // GPS time into week
  float64  lag;             // differential lag
  int32    sats;            // number of matched satellites (00-12)
  int32    sats_RTK;        // number of matched satellites above RTK mask angle
  int32    sats_RTK_L1_L2;  // number of matched satellites above RTK mask angle with both L1 & L2 available
  float64  latitude;        // latitude
  float64  longitude;       // longitude
  float64  height;          // height above mean sea level
  float64  undulation;      // undulation
  int32    id;              // datum id
  float64  dev_latitude;    // standard deviation of latitude
  float64  dev_longitude;   // standard deviation of longitude
  float64  dev_height;      // standard deviation of height
  int32    status_solution; // solution status
  int32    status_RTK;      // RTK status
  int32    pos_type;        // position type
  int32    idle;            // idle
  int32    station;         // rederence station identification (RTCM: 0-1023, or RTCA: 266305-15179385)
  static int sizeof_data() { return 112; } // the number of expected data bytes held by this structure
};


//
// Particular field structure of GPS VLHB message
//
struct GpsVlhb
{
  int32    week;            // week number (units: weeks)
  float64   seconds;          // seconds of week (units: seconds)
  float64  latency;          // latency (units: meters per second)
  float64  age;              // age (units: seconds)
  float64  hspeed;          // horizontal speed (units: meters per second)
  float64  tog;              // track over ground (units: degrees)
  float64  vspeed;          // vertical speed (units: meters per second)
  int32     status_solution;  // solution status
  int32    status_velocity;  // velocity status
  static int sizeof_data() { return 60; } // the number of expected data bytes held by this structure
};


//
// Convert latitude, longitude, height coordinates to x, y, z coordinates
// Based on code written by Davin Shim.
// Written by Cory Sharp.
//
// INPUTS:
//   const double* LLH_origin = 3 element array of position of origin in LLH
//   const double* LLH_current = 3 element array of current position in LLH
//
// OUTPUT:
//   double* XYZ_current = 3 element array of current position in LLH
//
void convertLLH2XYZ(const double* LLH_origin, const GpsPrtkb& PRTKB_current, double* XYZ_current);


//
// Manage GPS input/output
//
class GpsIO : public StructIO<GpsPacket>
{
  public:
    typedef StructIO<data_type> super_type;

  private:
    enum Working_Packet_State { WPS_Need_Sync, WPS_Need_Header, WPS_Need_Data };
    Working_Packet_State m_wps_state;
    data_type m_working_packet;

  protected:
    virtual void extract_structs( std::string& s );
    
  public:
    GpsIO( char_io_type* io = 0 ) { get_char_io(); set_char_io( io ); }
    virtual ~GpsIO() { }

    virtual void set_char_io( char_io_type* io ) { m_wps_state = WPS_Need_Sync; super_type::set_char_io(io); }
    virtual const char* get_io_type_name() { return "GpsIO"; }
};


#endif //_H_GpsIO_h


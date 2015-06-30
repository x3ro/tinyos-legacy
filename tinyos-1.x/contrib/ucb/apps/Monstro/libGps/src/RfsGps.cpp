// $Id: RfsGps.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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

#include <string>

#include "RfsGps.h"
#include "FormStr.h"
#include "StructIO.cpp"


//
// Construct a GPS object
//
RfsGps::RfsGps( char_io_type* io /* = 0 */ )
  : m_gps_io(io), m_nPrtkbUpdates(0), m_nVlhbUpdates(0)
{ 
  initOrigin();
  for(int i=0; i<3; i++) m_currentXYZ[i] = 0;
  memset( &m_currentPrtkb, 0, sizeof(GpsPrtkb) );
  memset( &m_currentVlhb, 0, sizeof(GpsVlhb) );
  sendInitCommands();
}


//
// On destruction, command the GPS to stop all updates
// (stop periodic updates from filling the serial buffer)
//
RfsGps::~RfsGps()
{
  stopAllUpdates();
}


//
// Process pending input/output to/from the GPS
//
void RfsGps::processIO() 
{ 
  m_gps_io.flush();

  GpsIO::data_type gps_packet;
  while( m_gps_io.read( &gps_packet, 1, 0 ) == 1 )
  {
    process_gps_packet( gps_packet );
    m_gps_io.flush();
  }
}


//
// Retrieve the current local XYZ coordinates
// +x: north   +y: east   +z: down
//
// A good idea might be to call processIO then call this member
// if getNumUpdates changed
//
void RfsGps::getCurrentXYZ(double& x, double& y, double& z)
{
  x = m_currentXYZ[0];
  y = m_currentXYZ[1];
  z = m_currentXYZ[2];
}

double RfsGps::getCurrentX()
{
  return m_currentXYZ[0];
}

double RfsGps::getCurrentY()
{
  return m_currentXYZ[1];
}

double RfsGps::getCurrentZ()
{
  return m_currentXYZ[2];
}


//
// Retrieve the current global LLH coordinantes
// LLH = latitude, longitude, height
//
void RfsGps::getCurrentLLH(double& latitude, double& longitude, double& height)
{
  latitude  = m_currentPrtkb.latitude;
  longitude = m_currentPrtkb.longitude;
  height    = m_currentPrtkb.height;
}


//
// Retrieve the current global LLH deviations
// LLH = latitude, longitude, height
//
void RfsGps::getCurrentLLHDev(double& dev_latitude, double& dev_longitude, double& dev_height)
{
  dev_latitude  = m_currentPrtkb.dev_latitude;
  dev_longitude = m_currentPrtkb.dev_longitude;
  dev_height    = m_currentPrtkb.dev_height;
}


//
// Initialize the local LLH (lat, long, height) origin
// Default to the red fire hydrant near the shack at Richmond Field Station
//
void RfsGps::initOrigin(
    const double latitude  /* =   37.913885400636104 */ , 
    const double longitude /* = -122.33609599269469  */ , 
    const double height    /* =  -26.2               */  )
{
  m_originLLH[0] = latitude;
  m_originLLH[1] = longitude;
  m_originLLH[2] = height;
}


//
// Command the GPS to send a single update
//
// Note, to send/receive pending data to/from the GPS, processIO must be called
//
void RfsGps::requestOneUpdate()
{
  write_string( "\rlog com1 prtkb once\r" );
  write_string( "\rlog com1 vlhb once\r" );
  processIO();
}


//
// Command the GPS module to perform periodic updates every interval seconds
//
// Note, to send/receive pending data to/from the GPS, processIO must be called
//
void RfsGps::requestPeriodicUpdates(double interval)
{
  write_string( FormStr( "\rlog com1 prtkb ontime %g\r", interval ).str() );
  write_string( FormStr( "\rlog com1 vlhb ontime %g\r", interval ).str() );
  processIO();
}


//
// Stop all (periodic) updates
//
void RfsGps::stopAllUpdates()
{
  write_string( "\runlogall\r" );
  processIO();
}


//
// Send basic initialization commands
//
void RfsGps::sendInitCommands()
{
  write_string( "\runlogall\r" );
  write_string( "\runfix\r" );
  write_string( "\rdynamics foot\r" );  // set the expected speed range of remote station
  write_string( "\raccept com2,rtca\r" );
  write_string( "\rrtkmode known_llh_position 37.914119,-122.336107,6.509627\r" );
  processIO();
}


//
// Not for general use - automatic callback interface
//
// This member can be called back with current data when processIO is executed
// It converts a GPS Prtkb packet to local XYZ coordinates
// Current local XYZ coordinates can be retrieved with the member getCurrentXYZ
//
void RfsGps::process_gps_packet( const GpsPacket& packet )
{
  if( packet.verify( GpsPacket::PRTKB, GpsPrtkb::sizeof_data() ) == 0 )
  {
    packet.message.copy( (char*)(&m_currentPrtkb), GpsPrtkb::sizeof_data() );
    convertLLH2XYZ( m_originLLH, m_currentPrtkb, m_currentXYZ );
    m_nPrtkbUpdates++;
  }

  if( packet.verify( GpsPacket::VLHB, GpsVlhb::sizeof_data() ) == 0 )
  {
    packet.message.copy( (char*)(&m_currentVlhb), GpsVlhb::sizeof_data() );
    m_nVlhbUpdates++;
  }
}


//
// write_string
// send a null-terminated string to the char io device attached
//
void RfsGps::write_string( const char* str )
{
  m_gps_io.append_to_output_buffer( str );
}



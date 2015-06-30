// $Id: GpsIO.cpp,v 1.1 2005/04/21 23:22:21 shawns Exp $

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
 * @auther Shawn Schaffert
 */

#include "GpsIO.h"

#include "GetMicros.h"
#include "FormStr.h"
#include "string_utils.h"

#include <algorithm>
#include <cmath>
//#include <tnt/fmat.h>
#include <unistd.h>

//using TNT::Fortran_Matrix;


#include "StructIO.cpp"


void GpsPacket::clear()
{ 
  checksum = 0; 
  message_id = 0; 
  message_byte_count = 0; 
  message.erase(); 
}


std::string GpsPacket::to_string() const
{
  std::string s;
  s.append( sync, sync+3 );
  s += static_cast<char>( checksum );
  string_utils::append_lsb_first( s, message_id );
  string_utils::append_lsb_first( s, message_byte_count );
  s += message;
  return s;
}


void GpsPacket::assign_header( const char* data )
{
  sync[0] = data[0];
  sync[1] = data[1];
  sync[2] = data[2];
  checksum = data[3];
  message_id = string_utils::extract_lsb_first< int32 >( data + 4 );
  message_byte_count = string_utils::extract_lsb_first< int32 >( data + 8 );
}


uint8 GpsPacket::calcChecksum() const
{
  uint8 checksum = 0;
  for(int i=0; i<12; i++) checksum ^= ((const char*)this)[i];
  for(std::string::size_type i=0; i<message.length(); i++) checksum ^= message[i];
  return checksum;
}


int GpsPacket::verify(message_id_type expected_id, int expected_bytes) const
{
  if( calcChecksum() != 0 ) return 1;
  if( (std::string::size_type)(message_byte_count-12) != message.length() ) return 2;
  if( message_id != expected_id ) return 3;
  if( (message_byte_count-12) != expected_bytes ) return 4;
  return 0;
}


//
// Convert Latitude, Longitude, Height to ECEF
// Written by David Hyunchul Shim
// Updates by Cory Sharp
//
void LLH2ECEF(double lat, double longe, double height, double* ECEF)
{
  const double a_wgs84 = 6378137.0; // semimajor axis [m]
  // (b_wgs84 unused)
  // const double b_wgs84 = 6356752.3142; // semiminor axis [m]
  const double e_wgs84 = 0.0818; // eccentricity of WGS84 

  double slambda = sin(lat);
  double N = a_wgs84 / sqrt( 1 - e_wgs84*e_wgs84 * slambda*slambda );
  double temp = (N+height)*cos(lat);

  //ECEF.newsize(3,1);
  ECEF[0] = temp * cos(longe);
  ECEF[1] = temp * sin(longe);
  ECEF[2] = ( N*(1 - e_wgs84*e_wgs84) + height ) * slambda;
}


//
// Written by David Hyunchul Shim
// Updates by Cory Sharp
//
void ObtainECEF2TPTX(double lat, double longe, double Re2t[3][3])
{
  double slambda = sin(lat);
  double clambda = cos(lat);
  double cpi = cos(longe);
  double spi = sin(longe);

  //Re2t.newsize(3,3);
  Re2t[0][0] = -slambda * cpi;
  Re2t[0][1] = -slambda * spi;
  Re2t[0][2] = clambda;
  Re2t[1][0] = -spi;
  Re2t[1][1] = cpi;
  Re2t[1][2] = 0;
  Re2t[2][0] = -clambda * cpi;
  Re2t[2][1] = -clambda * spi;
  Re2t[2][2] = -slambda;
}

//
// Convert latitude, longitude, height coordinates to x, y, z coordinates
// LLH must be given in degrees.
//
void convertLLH2XYZ(const double* LLH_origin, const GpsPrtkb& PRTKB_current, double* XYZ_current)
{
  const double D2R = M_PI / 180.0;

  // obtain the ECEF coord of Origin
  double OriginECEF[3];
  LLH2ECEF( LLH_origin[0] * D2R, LLH_origin[1] * D2R, LLH_origin[2], OriginECEF );

  // precompute the transformation matrix
  double Re2t[3][3];
  ObtainECEF2TPTX( LLH_origin[0]*D2R, LLH_origin[1]*D2R, Re2t );

  // obtain ECEF using LLH representation
  double CurrentECEF[3];
  LLH2ECEF( 
      PRTKB_current.latitude * D2R, 
      PRTKB_current.longitude * D2R,
      PRTKB_current.height + PRTKB_current.undulation,
      CurrentECEF
    );

  // now compute the Local cartesian coord (LCC) from the delta ECEF
  // +x : north +y: east +z: down

  //Fortran_Matrix<double> XYZ( Re2t * (CurrentECEF - OriginECEF) );
  //XYZ_current[0] = XYZ(1,1);
  //XYZ_current[1] = XYZ(2,1);
  //XYZ_current[2] = XYZ(3,1);

  double DIFF[3];
  DIFF[0] = CurrentECEF[0] - OriginECEF[0];
  DIFF[1] = CurrentECEF[1] - OriginECEF[1];
  DIFF[2] = CurrentECEF[2] - OriginECEF[2];
  XYZ_current[0] = Re2t[0][0]*DIFF[0] + Re2t[0][1]*DIFF[1] + Re2t[0][2]*DIFF[2];
  XYZ_current[1] = Re2t[1][0]*DIFF[0] + Re2t[1][1]*DIFF[1] + Re2t[1][2]*DIFF[2];
  XYZ_current[2] = Re2t[2][0]*DIFF[0] + Re2t[2][1]*DIFF[1] + Re2t[2][2]*DIFF[2];
}









/*
void LLH2ECEF(double lat, double longe, double height, Fortran_Matrix<double>& ECEF)
{
  const double a_wgs84 = 6378137.0; // semimajor axis [m]
  // (b_wgs84 unused)
  // const double b_wgs84 = 6356752.3142; // semiminor axis [m]
  const double e_wgs84 = 0.0818; // eccentricity of WGS84 

  double slambda = sin(lat);
  double N = a_wgs84 / sqrt( 1 - e_wgs84*e_wgs84 * slambda*slambda );
  double temp = (N+height)*cos(lat);

  ECEF.newsize(3,1);
  ECEF(1,1) = temp * cos(longe);
  ECEF(2,1) = temp * sin(longe);
  ECEF(3,1) = ( N*(1 - e_wgs84*e_wgs84) + height ) * slambda;
}


//
// Written by David Hyunchul Shim
// Updates by Cory Sharp
//
void ObtainECEF2TPTX(double lat, double longe, Fortran_Matrix<double>& Re2t)
{
  double slambda = sin(lat);
  double clambda = cos(lat);
  double cpi = cos(longe);
  double spi = sin(longe);

  Re2t.newsize(3,3);
  Re2t(1,1) = -slambda * cpi;
  Re2t(1,2) = -slambda * spi;
  Re2t(1,3) = clambda;
  Re2t(2,1) = -spi;
  Re2t(2,2) = cpi;
  Re2t(2,3) = 0;
  Re2t(3,1) = -clambda * cpi;
  Re2t(3,2) = -clambda * spi;
  Re2t(3,3) = -slambda;
}

//
// Convert latitude, longitude, height coordinates to x, y, z coordinates
// LLH must be given in degrees.
//
void convertLLH2XYZ(const double* LLH_origin, const GpsPrtkb& PRTKB_current, double* XYZ_current)
{
  const double D2R = M_PI / 180.0;

  // obtain the ECEF coord of Origin
  Fortran_Matrix<double> OriginECEF;
  LLH2ECEF( LLH_origin[0] * D2R, LLH_origin[1] * D2R, LLH_origin[2], OriginECEF );

  // precompute the transformation matrix
  Fortran_Matrix<double> Re2t;
  ObtainECEF2TPTX( LLH_origin[0]*D2R, LLH_origin[1]*D2R, Re2t );

  // obtain ECEF using LLH representation
  Fortran_Matrix<double> CurrentECEF;
  LLH2ECEF( 
      PRTKB_current.latitude * D2R, 
      PRTKB_current.longitude * D2R,
      PRTKB_current.height + PRTKB_current.undulation,
      CurrentECEF
    );

  // now compute the Local cartesian coord (LCC) from the delta ECEF
  // +x : north +y: east +z: down
  Fortran_Matrix<double> XYZ( Re2t * (CurrentECEF - OriginECEF) );
  XYZ_current[0] = XYZ(1,1);
  XYZ_current[1] = XYZ(2,1);
  XYZ_current[2] = XYZ(3,1);
}
*/






//
// extract_gps_packets
// extract all valid GPS packets from the snarfed bytes in the working string
//
void GpsIO::extract_structs( std::string& input )
{
  // keep on eating up GPS packets until there are no more to eat
  while( true )
  {
    switch( m_wps_state )
    {
      // if we don't have a sync, try to find one
      case WPS_Need_Sync :
      {
	// if we don't have at least 3 bytes snarfed
	// leave for now
	if( input.length() < 3 ) 
	  return;

	// otherwise, scan the string for the GPS synchronization header 0xAA 0x44 0x11
	const char header[] = { 0xAA, 0x44, 0x11, 0 };
	std::string::size_type n = input.find( &header[0] );

	// if the header was not found, delete all but the last two snarfed bytes
	// (those last two bytes _could_ be part of a valid header, we'll find out later)
	// leave for now
	if( n == std::string::npos ) 
	{ 
	  input.erase( 0, input.length() - 2 ); 
	  return; 
	}

	// delete any garbage bytes before the header
	if( n > 0 ) 
	  input.erase( 0, n );

	// there, we have a valid sync and need the full header
	// continue to the next section (no break)
	m_wps_state = WPS_Need_Header;
      }

      // if we have a sync, but not a header, try to get it
      case WPS_Need_Header :
      {
	// all we're looking for is at least 12 bytes, if we dont have them
	// leave for now
	if( input.length() < 12 ) 
	  return;

	// that's a complete header
	// copy into the working packet and mark it as valid
	// and continue to the next section (no break)
	m_working_packet.assign_header( input.data() );
	m_wps_state = WPS_Need_Data;
      }

      // if we have a header, but not the message data, try to get it
      case WPS_Need_Data :
      {
	// if we don't yet have enough for a full packet
	// leave for now
	if( input.length() < static_cast<std::string::size_type>(m_working_packet.message_byte_count) )
	  return;

	// assign the message data of the GPS packet
	// and append it to the vector of available GPS packets
	m_working_packet.message.assign( input, 12, m_working_packet.message_byte_count - 12 );
	super_type::append_to_input_buffer( m_working_packet );
     
	// prepare for the next GPS packet
	// - delete the packet bytes from the available bytes string
	// - put the input state back to looking for sync
	input.erase( 0, m_working_packet.message_byte_count );
	m_wps_state = WPS_Need_Sync;

	// fall through (no break) and let the while loop catch us
      }
    }

    // if here, then we didn't hit any "leave for now" sections
    // that means we successfully scanned a GPS packet
    // so, let the while loop continue, scanning for more GPS packets
  }
}



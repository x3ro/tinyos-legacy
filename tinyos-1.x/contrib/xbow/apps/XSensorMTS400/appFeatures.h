/**
 * Compile-time flags for defining application specific feature preferences.
 *
 * @file       appFeatures.h
 * @author     Martin Turon
 *
 * @version    2004/8/8         mturon          Initial version
 *
 * $Id: appFeatures.h,v 1.5 2005/04/06 03:20:38 husq Exp $
 */
// crossbow sensor board id
//define MTS420 to enable gps. 
//       MTS400 will not send gps packets.
// Uncomment the following line if you are using a MTS420 board.

#define MTS420

#ifndef MTS420
#define  SENSOR_BOARD_ID 0x85               //MTS400 sensor board id
#else
#define  SENSOR_BOARD_ID 0x86               //MTS420 sensor board id
#endif

//#define FEATURE_GPS_ONLY 1

#ifndef FEATURE_GPS_ONLY
#define FEATURE_GPS_ONLY 0
#endif




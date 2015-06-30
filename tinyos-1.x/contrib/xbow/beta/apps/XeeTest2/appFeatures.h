/**
 * Compile-time flags for defining application specific feature preferences.
 *
 * @file       appFeatures.h
 * @author     Martin Turon
 *
 * @version    2004/8/8         mturon          Initial version
 *
 * $Id: appFeatures.h,v 1.2 2004/11/15 08:15:12 husq Exp $
 */

#define MTS310

// crossbow sensor board id
#ifndef MTS310
#define  SENSOR_BOARD_ID 0x83               //MTS300 sensor board id
#else
#define  SENSOR_BOARD_ID 0x84               //MTS300 sensor board id
#endif

#define FEATURE_SOUNDER     0
#define FEATURE_LEDS  

#ifdef TEN_X
#define XSENSOR_SAMPLE_RATE  5000
//#define XSENSOR_SAMPLE_RATE  (18432 - (TOS_LOCAL_ADDRESS << 2))
#else
#define XSENSOR_SAMPLE_RATE  5000
//#define XSENSOR_SAMPLE_RATE  (184320 - (TOS_LOCAL_ADDRESS << 7))

#endif

// #ticks with leds
#ifdef TEN_X
#define DOLEDSN 255
#else
#define DOLEDSN 6
#endif


// Define SOUND_STATE_CHANGE one of two ways:
//      One time sound at test init   ==>  FALSE
//      Continuous beeping throughout ==>  !sound_state
#define SOUND_STATE_CHANGE  FALSE
//#define SOUND_STATE_CHANGE  !sound_state


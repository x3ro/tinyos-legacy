/**
 * Converts Makefile defines to globally available compile-time definitions.
 * Also provides deployment specific constants.
 *
 * @file     appFeatures.h 
 * @author   Martin Turon
 *
 * $Id: appFeatures.h,v 1.2 2004/09/09 22:00:12 jdprabhu Exp $
 */

// crossbow sensor board id
#define  SENSOR_BOARD_ID 0x81       //MDA300 sensor board id

// Application compilation features: 
// Set to 1 to enable, 0 to disable.

#ifdef TEN_X
#define XSENSOR_SAMPLE_RATE  (180 - (TOS_LOCAL_ADDRESS << 2)) 
#define  FEATURE_LEDS    1
#else
#define XSENSOR_SAMPLE_RATE  (1800 - (TOS_LOCAL_ADDRESS << 7))
#define  FEATURE_LEDS    0
#endif

#ifndef MULTIHOPROUTER
#define MULTIHOPROUTER	EWMAMultiHopRouter
#endif

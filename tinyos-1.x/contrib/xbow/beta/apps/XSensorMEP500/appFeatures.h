/**
 * Compile-time flags for defining application specific feature preferences.
 *
 * @file       appFeatures.h
 * @author     Martin Turon
 *
 * @version    2004/8/8         mturon          Initial version
 *
 * $Id: appFeatures.h,v 1.2 2004/08/16 21:12:47 ammbot Exp $
 */

// crossbow sensor board id
#define  SENSOR_BOARD_ID 0x03              //MEP500 sensor board id

#ifdef TEN_X
#define FEATURE_LED_DEBUG  
#define XSENSOR_SAMPLE_RATE  (30000 - (TOS_LOCAL_ADDRESS << 2))
#else
#define FEATURE_LED_DEBUG  
#define XSENSOR_SAMPLE_RATE  (300000 - (TOS_LOCAL_ADDRESS << 7))
#endif

// #ticks with leds
#define DOLEDSN 3

#ifdef TEN_X
#define IFLEDSON(ledsexpr)  { ledsexpr; }
#define IFLEDSOFF(ledsexpr) { ledsexpr; }
#else
#define IFLEDSON(ledsexpr)  { if((doleds!=0) || (TOS_LOCAL_ADDRESS==0)) { ledsexpr; }}
#define IFLEDSOFF(ledsexpr) { if((doleds==0) || (TOS_LOCAL_ADDRESS==0)) { ledsexpr; }}
#endif

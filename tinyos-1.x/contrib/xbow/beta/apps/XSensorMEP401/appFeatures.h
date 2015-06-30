/**
 * Compile-time flags for defining application specific feature preferences.
 *
 * @file       appFeatures.h
 * @author     Martin Turon
 *
 * @version    2004/8/8         mturon          Initial version
 *
 * $Id: appFeatures.h,v 1.3 2004/08/16 22:23:19 mturon Exp $
 */

// crossbow sensor board id
#define  SENSOR_BOARD_ID 0x87              //MEP401 sensor board id

#ifdef TEN_X
#define FEATURE_LED_DEBUG  
#define XSENSOR_SAMPLE_RATE  (30000 - (TOS_LOCAL_ADDRESS << 2))
#else
#define FEATURE_LED_DEBUG  
#define XSENSOR_SAMPLE_RATE  (300000 - (TOS_LOCAL_ADDRESS << 7))
#endif

// #ticks with leds
#ifdef TEN_X
#define DOLEDSN 255
#else
#define DOLEDSN 6
#endif

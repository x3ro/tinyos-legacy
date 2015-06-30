/**
 * Compile-time flags for defining application specific feature preferences.
 *
 * @file       appFeatures.h
 * @author     Martin Turon
 *
 * @version    2004/8/8         mturon          Initial version
 *
 * $Id: appFeatures.h,v 1.7 2005/03/04 10:08:49 husq Exp $
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

#define FEATURE_GPS_ONLY 1

#ifndef FEATURE_GPS_ONLY
#define FEATURE_GPS_ONLY 0
#endif
// current Xee lib donnot support MicaZ
#ifdef PLATFORM_MICAZ
#define FEATURE_XEE_PARAMS  0
#else
#define FEATURE_XEE_PARAMS  0
#endif

/// FEATURE_XEE_PARAMS -- enables changing nodeid, group, and other params
#ifndef FEATURE_XEE_PARAMS
#define FEATURE_XEE_PARAMS  0
#endif


/** 
 * FEATURE_XEE_PARAMS enables dynamic setting of various parameters when set. 
 * Params include: nodeid, group, radio power, radio freq/band.
 */
#if FEATURE_XEE_PARAMS
#define XEE_PARAMS_COMPONENT   RecoverParamsC,
#define XEE_PARAMS_WIRING()    Main.StdControl->RecoverParamsC.ParamControl;
#else 
#define XEE_PARAMS_COMPONENT 
#define XEE_PARAMS_WIRING()     
#endif



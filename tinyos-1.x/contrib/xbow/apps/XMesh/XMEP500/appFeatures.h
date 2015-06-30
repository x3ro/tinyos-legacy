/**
 * Compile-time flags for defining application specific feature preferences.
 *
 * @file       appFeatures.h
 * @author     Martin Turon
 *
 * @version    2004/8/8         mturon          Initial version
 *
 * $Id: appFeatures.h,v 1.2 2005/01/27 07:10:43 husq Exp $
 */

/// FEATURE_LEDS -- powers up the LEDs for debugging purposes
#ifndef FEATURE_LEDS
#define FEATURE_LEDS        1
#endif

/// FEAUTRE_DELUGE -- enables over-the-air reprogramming
#ifndef FEATURE_DELUGE
#define FEATURE_DELUGE      0
#endif

/// FEATURE_XEE_PARAMS -- enables changing nodeid, group, and other params
#ifndef FEATURE_XEE_PARAMS
#define FEATURE_XEE_PARAMS  0
#endif

/// FEATURE_UART_SEND -- enable serial port debugging of a node
#ifndef FEATURE_UART_SEND
#define FEATURE_UART_SEND   0
#endif

/// FEATURE_SOUNDER -- enable test of speaker output
#ifndef FEATURE_SOUNDER
#define FEATURE_SOUNDER     0
#endif


#ifdef TEN_X
#define XSENSOR_SAMPLE_RATE  (1843 - (TOS_LOCAL_ADDRESS << 2))
//#define XSENSOR_SAMPLE_RATE  3000
#else
#define XSENSOR_SAMPLE_RATE  (184320 - (TOS_LOCAL_ADDRESS << 7))
#endif

/**
 * Define wiring macros for various application features. 
 */

/** FEATURE_LEDS will enable debugging Leds when set to 1. */
#if FEATURE_LEDS
#define LEDS_COMPONENT	       LedsC,
#define LEDS_WIRING(X)         X.Leds -> LedsC;
#else
#define LEDS_COMPONENT	       NoLeds,
#define LEDS_WIRING(X)         X.Leds -> NoLeds;
#endif

/** FEATURE_DELUGE will enable over-the-air programming when set to 1. */
#if FEATURE_DELUGE
#define DELUGE_COMPONENT       DelugeC,
#define DELUGE_WIRING()        Main.StdControl->DelugeC;
#else
#define DELUGE_COMPONENT
#define DELUGE_WIRING()    
#endif

/** 
 * FEATURE_XEE_PARAMS enables dynamic setting of various parameters when set. 
 * Params include: nodeid, group, radio power, radio freq/band.
 */
#if FEATURE_XEE_PARAMS
#define XEE_PARAMS_COMPONENT   RecoverParamsC,
#define XEE_PARAMS_WIRING()    Main.StdControl->RecoverParamsC.ParamControl;  RecoverParamsC.CommControl -> Comm;
#else 
#define XEE_PARAMS_COMPONENT 
#define XEE_PARAMS_WIRING()     
#endif

#ifndef MULTIHOPROUTER
#define MULTIHOPROUTER	       EWMAMultiHopRouter
#endif



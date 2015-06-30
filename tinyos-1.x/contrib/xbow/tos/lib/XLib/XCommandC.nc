/**
 * Provides a library module for handling basic application messages for
 * controlling a wireless sensor network.
 * 
 * @file      XCommandC.nc
 * @author    Martin Turon
 * @version   2004/10/1    mturon      Initial version
 *
 * All wiring of internal components for this module is done here.
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 *
 * $Id: XCommandC.nc,v 1.3 2005/01/27 03:36:31 husq Exp $
 */

includes XCommand;

configuration XCommandC {
  provides {
    interface XCommand;
//    interface StdControl;
  }
  uses {
  	interface Send;
    interface Receive as Bcast;
    interface ReceiveMsg;
//    interface Leds;             // Wire via application layer.
  }
}

implementation {
    components LedsC, 
#if FEATURE_XEE_PARAMS     
    RecoverParamsC, 
#else
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)	
	CC1000ControlM, 
#else
	CC2420ControlM,
#endif	
#endif
    SerialId, XCommandM;
    
    XCommand   = XCommandM;
    Send       = XCommandM;
    Bcast      = XCommandM;
    ReceiveMsg = XCommandM;
#if FEATURE_XEE_PARAMS      
    XCommandM.Config -> RecoverParamsC;
    XCommandM.ConfigSave -> RecoverParamsC;
#else    
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    XCommandM.CC1000Control -> CC1000ControlM;
#else
	XCommandM.CC2420Control -> CC2420ControlM;
#endif    
#endif    

    XCommandM.DS2401 -> SerialId;
    XCommandM.HardwareId -> SerialId;
    XCommandM.Leds -> LedsC;


} 

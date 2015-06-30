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
 * $Id: XCommandC.nc,v 1.2 2004/11/11 00:59:47 mturon Exp $
 */

includes XCommand;

configuration XCommandC {
  provides {
    interface XCommand;
//    interface StdControl;
  }
  uses {
    interface Receive as Bcast;
    interface ReceiveMsg;
//    interface Leds;             // Wire via application layer.
  }
}

implementation {
    components // Main, 
//	GenericCommPromiscuous as Comm, Bcast, 
	LedsC, 
	CC1000ControlM, 
	XCommandM;
    
    XCommand   = XCommandM;
    Bcast      = XCommandM;
    ReceiveMsg = XCommandM;

    XCommandM.Leds -> LedsC;

    XCommandM.CC1000Control -> CC1000ControlM;
    
//    Main.StdControl -> Bcast.StdControl;
//    Main.StdControl -> Comm;

//    XCommandM.Bcast -> Bcast.Receive[AM_XCOMMAND_MSG];
//    Bcast.ReceiveMsg[AM_XCOMMAND_MSG]->Comm.ReceiveMsg[AM_XCOMMAND_MSG];
} 

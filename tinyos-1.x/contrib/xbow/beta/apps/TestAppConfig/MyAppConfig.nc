// $Id: MyAppConfig.nc,v 1.7 2004/09/03 09:19:25 husq Exp $


// Copyright (c) 2004 by Sensicast, Inc.
// All rights including that of resale granted to Crossbow, Inc.
//
// Permission to use, copy, modify, and distribute this software and its
// documentation for any purpose, without fee, and without written
// agreement is hereby granted, provided that the above copyright
// notice, the (updated) modification history and the author appear in
// all copies of this source code.
//
// Permission is also granted to distribute this software under the
// standard BSD license as contained in the TinyOS distribution.
//
// @Author: Michael Newman
//
#define myappconfigEdit 1
//
// Modification History:
//  13Jan04 MJNewman 1: Created.

includes MyApp;

configuration MyAppConfig { }
implementation {
  components 
	Main, GenericComm, MyApp, MyAppComplex,
	// add sys parameters wiring
	RecoverParamsC,	AppConfigC;  
  
    Main.StdControl->  RecoverParamsC.ParamControl;
    Main.StdControl -> MyApp;
    Main.StdControl -> MyAppComplex;
    
    AppConfigC.ConfigInt8[CONFIG_MY_PARAM1] -> MyApp.MySetting8;
    AppConfigC.ConfigInt16[CONFIG_MY_PARAM2] -> MyApp.MySetting16;
    AppConfigC.Config[CONFIG_MY_PARAM3] -> MyAppComplex.MySetting;
}

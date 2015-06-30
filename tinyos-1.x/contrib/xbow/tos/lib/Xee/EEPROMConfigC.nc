// The main user-visible configuration component for storing variables
// in flash that survive code load and power cycles.
//
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
#define EEPROMConfigEdit 1
//
// Modification History:
//  13Jan04 MJNewman 1: Created.

includes Config;
configuration EEPROMConfigC {
    provides interface StdControl;
    provides interface ConfigSave;

    // Where user settings are connected
    uses interface Config[AppParamID_t setting];
}
implementation {
    components
	    EEPROMConfigM,
	    LedsC,
	    InternalEEPROMC;

    StdControl = EEPROMConfigM;
    ConfigSave = EEPROMConfigM;
    Config = EEPROMConfigM;

    InternalEEPROMC.WriteData <- EEPROMConfigM;
    InternalEEPROMC.ReadData <- EEPROMConfigM;
    InternalEEPROMC.StdControl <- EEPROMConfigM.EEPROMstdControl;

    EEPROMConfigM.Leds -> LedsC;
}

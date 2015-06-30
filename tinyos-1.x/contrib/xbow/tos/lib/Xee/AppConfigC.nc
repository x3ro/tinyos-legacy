// The main user-visible configuration component for storing variables
// in flash that survive code load and power cycles.
//
//
//
// Users wire their configuration variables to either Config or ConfigInt16
// (see MyApp, MyAppComplex, MyAppConfig for examples).
//
// This configuration wires in the MessageConfig (set settings via radio)
// and EEPROMConfig (initial settings from EEPROM) components - possibly these
// wirings should be done elsewhere (for when those components are not used).
//
// All the code should have StdControl's too.
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
#define AppConfigEdit 1
//
// Modification History:
//  13Jan04 MJNewman 1: Created.

includes AppConfig;

configuration AppConfigC {
    provides interface StdControl;
    provides interface ConfigSave;
    provides interface Config as ExternalConfig[AppParamID_t setting];

    // Where user settings are connected
    uses interface Config[AppParamID_t setting];
    uses interface ConfigInt8[AppParamID_t setting];
    uses interface ConfigInt16[AppParamID_t setting];
}
implementation {
    components  EEPROMConfigC, AppConfigM;

    StdControl = EEPROMConfigC;
    ConfigSave = EEPROMConfigC;

    ExternalConfig = AppConfigM.ExternalConfig;

    Config = AppConfigM.Config;
    ConfigInt8 = AppConfigM.ConfigInt8;
    ConfigInt16 = AppConfigM.ConfigInt16;

    EEPROMConfigC.Config -> AppConfigM;
    
}

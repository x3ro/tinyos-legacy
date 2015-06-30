// Save and restore all parameters as system starts.
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
// @Author: Michael Newman, Hu Siquan
//
// $Id: RecoverParamsC.nc,v 1.1 2005/04/04 09:50:42 husq Exp $

#define RecoverParamsCedit 1

includes AppConfig;

configuration RecoverParamsC {
    provides interface StdControl as ParamControl;
    provides interface Config[AppParamID_t setting];
    provides interface ConfigSave;
    uses interface StdControl as CommControl;
}
implementation {
    components AppConfigC, RecoverSystemParamsM,SerialId;
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)      
    components CC1000RadioC, HPLCC1000M;
#else
	components CC2420RadioC, HPLCC2420C;
#endif    
    ParamControl = AppConfigC.StdControl;
    Config = AppConfigC;
    ConfigSave = AppConfigC;

    RecoverSystemParamsM.CommControl = CommControl;
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)    
    RecoverSystemParamsM.CC1000Control ->CC1000RadioC;
    RecoverSystemParamsM.HPLChipcon ->HPLCC1000M;
#else 
    RecoverSystemParamsM.CC2420Control ->CC2420RadioC;
    RecoverSystemParamsM.HPLChipcon ->HPLCC2420C;
#endif    
    RecoverSystemParamsM.DS2401 -> SerialId;
    RecoverSystemParamsM.HardwareId -> SerialId;

    AppConfigC.ConfigInt16[CONFIG_MOTE_ID] -> RecoverSystemParamsM.SystemMoteID;
    AppConfigC.ConfigInt8[CONFIG_MOTE_GROUP] -> RecoverSystemParamsM.SystemGroupNumber;
    AppConfigC.ConfigInt8[CONFIG_MOTE_MODEL] -> RecoverSystemParamsM.SystemModelType;
    AppConfigC.ConfigInt8[CONFIG_MOTE_SUBMODEL] -> RecoverSystemParamsM.SystemSuModelType;
    AppConfigC.ConfigInt8[CONFIG_MOTE_CPU_TYPE] -> RecoverSystemParamsM.SystemMoteCPUType;
    AppConfigC.ConfigInt8[CONFIG_MOTE_RADIO_TYPE] -> RecoverSystemParamsM.SystemRadioType;
    AppConfigC.ConfigInt16[CONFIG_MOTE_VENDOR] -> RecoverSystemParamsM.SystemVendorID;
    AppConfigC.Config[CONFIG_MOTE_SERIAL] -> RecoverSystemParamsM.SystemSerialNumber;
    AppConfigC.Config[CONFIG_MOTE_CPU_OSCILLATOR_HZ] -> RecoverSystemParamsM.SystemCPUOscillatorFrequency;   

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)     
    AppConfigC.Config[CONFIG_CC1000_TUNE_HZ]->RecoverSystemParamsM.CC1KTuneHZ;  // 32 bits of frequency * 1,000,000
    AppConfigC.Config[CONFIG_CC1000_LOWER_HZ]->RecoverSystemParamsM.CC1KLowerHZ; // 32 bits of frequency * 1,000,000
    AppConfigC.Config[CONFIG_CC1000_UPPER_HZ]->RecoverSystemParamsM.CC1KUpperHZ; // 32 bits of frequency * 1,000,000
    AppConfigC.ConfigInt8[CONFIG_CC1000_RF_POWER]->RecoverSystemParamsM.CC1KRFPower; // 8 bits of rf power 
    AppConfigC.ConfigInt8[CONFIG_CC1000_RF_CHANNEL]->RecoverSystemParamsM.CC1KRFChannel; // 8 bits of rf channel 
#else    
    AppConfigC.ConfigInt8[CONFIG_CC2420_RF_POWER]->RecoverSystemParamsM.CC2420RFPower; // 8 bits of rf power 
    AppConfigC.ConfigInt8[CONFIG_CC2420_RF_CHANNEL]->RecoverSystemParamsM.CC2420RFChannel; // 8 bits of rf channel 
#endif
  
    AppConfigC.Config[CONFIG_FACTORY_INFO1]->RecoverSystemParamsM.CrossbowFactoryInfo1; // 16 bytes of factory information (printable ascii)
    AppConfigC.Config[CONFIG_FACTORY_INFO2]->RecoverSystemParamsM.CrossbowFactoryInfo2; // 16 bytes of factory information (printable ascii)
    AppConfigC.Config[CONFIG_FACTORY_INFO3]->RecoverSystemParamsM.CrossbowFactoryInfo3; // 16 bytes of factory information (printable ascii)
    AppConfigC.Config[CONFIG_FACTORY_INFO4]->RecoverSystemParamsM.CrossbowFactoryInfo4; // 16 bytes of factory information (printable ascii)  
}

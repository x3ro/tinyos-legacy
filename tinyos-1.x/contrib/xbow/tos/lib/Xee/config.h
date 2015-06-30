// Macros and definitions for variables stored in flash that survive
// code reloads and reboots.
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
// $Id: config.h,v 1.1 2005/04/04 09:50:42 husq Exp $
//
#ifndef __CONFIG_H__
#define __CONFIG_H__
//
// Modification History:
//  22Mar04 MJNewman 4: Reduce max param size to 16.
//  23Feb04 MJNewman 3: remove application blocks
//  13Jan04 MJNewman 2: 0 never used for an ID.
//  24Dec03 MJNewman 1: Created.

// Parameter IDs are composed of an application ID and a parameter ID
// within the application. The composite forms a 32 bit unique ID which
// can be used to identify the parameter. These unique IDs are passed
// in subroutine calls.
//
// The purpose of having an application ID is to define who controls
// the specification of individual parameter IDs. Application IDs are
// assigned to companies that build hardware or software. They have no
// purpose other than as a naming convention to isolate who controls
// the specification.

#pragma pack(1)


//??? Temporary move to TOS file
enum {
	AM_XEECMDMSG = 0x55,
	AM_XEEDATAMSG = 0x56,
};


// This type is used to pass parameter IDs in subroutine calls. It must
// always be a legal argument to a subroutine.
typedef uint32_t AppParamID_t;


typedef uint8_t ParameterID_t;

// cell to store a CRC
typedef uint16_t ParamCRC_t;

// Build a 32 bit parameter ID combining an application and parameter
// ID.
//
// Inputs:
//	_appID		application ID
//	_paramID	parameter ID
// Returns:
//	combined AppParamID_t
#define APP_PARAM_ID(_appID, _paramID) ((AppParamID_t)(((uint32_t)_appID) << 8 | ((ParameterID_t)_paramID)))

// Recover the application portion of an AppParamID_t
//
// Inputs:
//	_appParamID	an AppParamID_t
// Returns:
//	the application ID portion
#define GET_APP_ID(_appParamID) (((uint32_t)_appParamID) >> 8)

// recover the parameter ID portion of an AppParamID_t
//
// Inputs:
//	_appParamID	an AppParamID_t
// Returns:
//	the parameter ID portion
#define GET_PARAM_ID(_appParamID) ((uint8_t)_appParamID)

// Some well known applications and parameters of those applications:

enum ApplicationID {
    // Parameters should never appear with an application of 0
    TOS_INVALID_APPLICATION = 0,
    TOS_SYSTEM = 1,			// the TinyOS operating System
    TOS_CROSSBOW = 2,			// Crossbow manufacturer parameters
    TOS_CC1000 = 3,			// CC1000 radio parameters
    TOS_CC2420 = 4,			// CC2420 radio parameters
    // Parameter flash memory is set to all ones when the flash is
    // cleared. Finding a parameter block as all ones should be
    // properly handled without reporting errors. 
    TOS_TEST_APPLICATION = (0xfffffeL),	// for use when a parameter ID has not yet been assigned
					// it is reused often and should never be used for a
					// released application.
    TOS_NO_APPLICATION = (0xffffffL),
};

// Header portion of initial memory block describing flash parameters
typedef struct {
    ParamCRC_t crc;			// CRC of this version block, includes
					// the data that follows this header
    uint8_t majorVersion;
    uint8_t minorVersion;
    uint16_t buildNumber;		// place for builder to put an ID number, ignored by code
    uint8_t bytes;			// number of bytes in the entire parameter block.
					// This byte count allows the parameter
					// block to be expanded in a
					// compatible way. The byte
					// count will never be less
					// than 1 and will typically be
					// a multiple of 16 to make
					// EEPROM writing easy for the
					// physical layers
} FlashVersionHeader_t;
enum {
    ParameterIgnoreVersion = 0xff,
};
// FlashVersionHeader_t NOTES:
//
// The majorVersion and minorVersion specify the shape of this table.
// Adding particular applications or parameters does not change the version.
//
// The majorVersion changes when an incompatible change occurs.
// The minorVersion changes when a compatible extension is made.

// Current version numbers
#define PARAM_MAJOR_VERSION 1
#define PARAM_MINOR_VERSION 1

// Data portion of flash parameters, padded to make it fit a line on
// some common flash memory types.
typedef struct {
    uint8_t data[16 - sizeof(FlashVersionHeader_t)]; // Where any expansion will show up. Unused and set to 0.
} FlashVersionData_t;


#define BASE_OF_PARAMETERS (0)

// This structure is located at BASE_OF_PARAMETERS of the flash memory.
// A major version of 0 or 0xff is an indication that no block is
// present. If the CRC is invalid no block is present and writing
// parameters is not allowed (unless the entire block is all zeros or all
// ones.
typedef struct {
    FlashVersionHeader_t vHdr;
    FlashVersionData_t d;
} FlashVersionBlock_t;


// The parameter ID is set to TOS_IGNORE_PARAMETER when a parameter should be ignored.
// This can be used to disable a setting without recovering the
// space.
enum ParameterID {
    TOS_UNUSED_PARAMETER = 0,		// 0 is never used, treated same as TOS_NO_PARAMETER
    TOS_IGNORE_PARAMETER = 0xfe,	// explicitly disabled
    TOS_NO_PARAMETER = 0xff,
};

// No more than 16 bytes of data in a single parameter value.
#define TOS_MAX_PARAM_LENGTH 16

// Storage for each parameter. No single parameter can have more than
// TOS_MAX_PARAM_LENGTH bytes of data.
//
// The initial design used an application block which was intended to
// contain both the CRC and application ID fields. This caused
// implementation issues with having to rewrite the application block
// each time a parameter block was written. It was also determined that
// the parameter blocks needed a CRC for two reasons. First the CRC
// check is done before the count is used which prevents sequencing
// through a potentially huge number of parameter blocks that are not
// really there. Second the split phase nature of reading from Flash
// makes it much easier to check the CRC early with all data present
// rather than remembering state and reading the parameter data twice,
// first to check the CRC and then to read the values.
// 
// With these issues it became clear that at least 3 parameter blocks
// per application were necessary to save any space over the simple
// design with no special application block. Thus the application block
// was removed.
typedef struct {
    ParamCRC_t crc;			// CRC of the parameter block including the data
    uint32_t applicationID : 24;
    uint32_t paramID : 8;
    uint8_t count;			// number of bytes in the data block
} ParameterHeader_t;

// Space to store the largest parameter 
typedef struct {
    ParameterHeader_t paHdr;
    uint8_t data[TOS_MAX_PARAM_LENGTH];	// block of data
} ParameterBlock_t;

////////////////////////////////////////
// Parameter IDs for TOS_SYSTEM 'application'
////////////////////////////////////////
enum systemParamID {
    TOS_MOTE_ID = 1,			// 16 bits of TinyOS mote ID
    TOS_MOTE_GROUP = 2,			// 8 bits of TinyOS group ID
    TOS_MOTE_MODEL = 3,			// 8 bits for model type see below
    TOS_MOTE_SUBMODEL = 4,		// 8 bits for sub model code see below
    TOS_MOTE_CPU_TYPE =5,		// 8 bits for CPU type code see below
    TOS_MOTE_RADIO_TYPE = 6,		// 8 bits for Radio type code see below
    TOS_MOTE_VENDOR = 7,		// 16 bits for manufacturer code see below
    TOS_MOTE_SERIAL = 8,		// 32 bits for serial number,
					// Expected to be unique within
					// vendor and model
    TOS_MOTE_CPU_OSCILLATOR_HZ = 9,	// 32 bits for CPU oscillator frequency in
					// cycles per second EX: 7372800  					
};

// Model values for TOS_MOTE_MODEL
enum modelID {
    TOS_MODEL_UNKNOWN = 1,
    TOS_MODEL_MICA1 = 2,
    TOS_MODEL_MICA2 = 3,
    TOS_MODEL_MICA2DOT = 4,
    TOS_MODEL_H900 = 5,
};

// Sub model values for TOS_MOTE_SUBMODEL
enum subModelID {
    TOS_SUBMODEL_UNKNOWN = 1,
    TOS_SUBMODEL_DEFAULT = 2,		// standard model
};
    
// Sub model values for TOS_MOTE_CPU_TYPE
enum cpuTypeID {
    TOS_CPU_TYPE_UNKNOWN = 1,
    TOS_CPU_TYPE_ATMEGA128 = 2,
};

// Sub model values for TOS_MOTE_RADIO_TYPE
enum radioTypeID {
    TOS_RADIO_TYPE_UNKNOWN = 1,
    TOS_RADIO_TYPE_CC1000 = 2,
    TOS_RADIO_TYPE_H900 = 3,
    TOS_RADIO_TYPE_CC2420 = 4,
};

// Vendor numbers for TOS_MOTE_VENDOR
enum vendorID {
    TOS_VENDOR_UNKNOWN = 1,
    TOS_VENDOR_CROSSBOW = 2,
    TOS_VENDOR_SENSICAST = 3,
};

////////////////////////////////////////
// Parameter IDs for TOS_CC1000 'application'
////////////////////////////////////////
enum cc1000ParamID{
    TOS_CC1000_TUNE_HZ = 1,		// 32 bits of frequency * 1,000,000 ex: 995,918,000
    TOS_CC1000_LOWER_HZ = 2,		// 32 bits of frequency * 1,000,000 ex: 916,000,000
    TOS_CC1000_UPPER_HZ = 3,		// 32 bits of frequency * 1,000,000 ex: 933,000,000
    TOS_CC1000_RF_POWER = 4, // 8 bit hex between 0x00 and 0xFF show radio transmit power, ref. CC1000 datasheet
    TOS_CC1000_RF_CHANNEL = 5, // 8 bit hex show radio preset channel, ref. CC1000const.h
};

////////////////////////////////////////
// Parameter IDs for TOS_CC2420 'application'
////////////////////////////////////////
enum cc2420ParamID{
    TOS_CC2420_TUNE_HZ = 1,		// 32 bits of frequency * 1,000,000 ex: 995,918,000
    TOS_CC2420_LOWER_HZ = 2,		// 32 bits of frequency * 1,000,000 ex: 916,000,000
    TOS_CC2420_UPPER_HZ = 3,		// 32 bits of frequency * 1,000,000 ex: 933,000,000
    TOS_CC2420_RF_POWER = 4, // 8 bit hex between 0x00 and 0xFF show radio transmit power, ref. CC2420 datasheet
    TOS_CC2420_RF_CHANNEL = 5, // 8 bit hex show radio preset channel, ref. CC2420const.h
};

////////////////////////////////////////
// Parameter IDs for TOS_CROSSBOW 'application'
////////////////////////////////////////
enum crossbowID {
    TOS_FACTORY_INFO1 = 1,			// 16 bytes of factory information (printable ascii)
    TOS_FACTORY_INFO2 = 2,			// 16 bytes of factory information (printable ascii)
    TOS_FACTORY_INFO3 = 3,			// 16 bytes of factory information (printable ascii)
    TOS_FACTORY_INFO4 = 4,			// 16 bytes of factory information (printable ascii)
};

// These are provided because the macro can not be directly used in the
// wiring:
//
//    AppConfigC.ConfigInt16[APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_ID)]->RecoverSystemParamsM.SystemMoteID;
//Fails, it must be
//   AppConfigC.ConfigInt16[CONFIG_MOTE_ID] -> RecoverSystemParamsM.SystemMoteID;
enum {
    CONFIG_NO_APPLICATION = APP_PARAM_ID(TOS_NO_APPLICATION,TOS_NO_PARAMETER),
    CONFIG_MOTE_ID = APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_ID),
    CONFIG_MOTE_GROUP = APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_GROUP),
    CONFIG_MOTE_MODEL = APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_MODEL),
    CONFIG_MOTE_SUBMODEL = APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_SUBMODEL),
    CONFIG_MOTE_CPU_TYPE = APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_CPU_TYPE),
    CONFIG_MOTE_RADIO_TYPE = APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_RADIO_TYPE),
    CONFIG_MOTE_VENDOR = APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_VENDOR),
    CONFIG_MOTE_SERIAL = APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_SERIAL),
    CONFIG_MOTE_CPU_OSCILLATOR_HZ = APP_PARAM_ID(TOS_SYSTEM,TOS_MOTE_CPU_OSCILLATOR_HZ),
    CONFIG_FACTORY_INFO1 = APP_PARAM_ID(TOS_CROSSBOW,TOS_FACTORY_INFO1),
    CONFIG_FACTORY_INFO2 = APP_PARAM_ID(TOS_CROSSBOW,TOS_FACTORY_INFO2),
    CONFIG_FACTORY_INFO3 = APP_PARAM_ID(TOS_CROSSBOW,TOS_FACTORY_INFO3),
    CONFIG_FACTORY_INFO4 = APP_PARAM_ID(TOS_CROSSBOW,TOS_FACTORY_INFO4),
    CONFIG_CC1000_TUNE_HZ = APP_PARAM_ID(TOS_CC1000,TOS_CC1000_TUNE_HZ),
    CONFIG_CC1000_LOWER_HZ = APP_PARAM_ID(TOS_CC1000,TOS_CC1000_LOWER_HZ),
    CONFIG_CC1000_UPPER_HZ = APP_PARAM_ID(TOS_CC1000,TOS_CC1000_UPPER_HZ),
    CONFIG_CC1000_RF_CHANNEL = APP_PARAM_ID(TOS_CC1000,TOS_CC1000_RF_CHANNEL),
    CONFIG_CC1000_RF_POWER = APP_PARAM_ID(TOS_CC1000,TOS_CC1000_RF_POWER),
    CONFIG_CC2420_RF_CHANNEL = APP_PARAM_ID(TOS_CC2420,TOS_CC2420_RF_CHANNEL),
    CONFIG_CC2420_RF_POWER = APP_PARAM_ID(TOS_CC2420,TOS_CC2420_RF_POWER),
};

enum RFCHANNEL{
	CC1K_MAX_RF_CHANNEL = 34,
};

#endif // configHedit


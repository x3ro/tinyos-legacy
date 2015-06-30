// Methods to read parameters from flash at startup and store to flash
// on request.
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
#define EEPROMConfigCedit 1
//
// Modification History:
//  25Jan04 MJNewman 1: Created.

includes config;
includes crc;

module EEPROMConfigM {
  provides interface StdControl;
  provides interface ConfigSave;
  uses {
      interface Config[AppParamID_t setting];
      interface WriteData;
      interface ReadData;
      interface StdControl as EEPROMstdControl;
      interface Leds;
  }
}

implementation
{

// To turn on debugging printouts uncomment the next line.
//#define SO_DEBUG 1
#include "SOdebug.h"

#ifndef MIN
#define MIN(_a,_b) ((_a < _b) ? _a : _b)
#endif
#ifndef MAX
#define MAX(_a,_b) ((_a >= _b) ? _a : _b)
#endif


    // Keep track of how far along in reading from EEPROM we are
    enum {
	PARAM_NEVER_STARTED = 0,
	PARAM_IDLE,			// Nothing to do
	PARAM_READ_VERSION,		// waiting for FlashVersionBlock_t
	PARAM_READ_PARAMETER,		// waiting for the next ParameterBlock_t
	PARAM_SAVE_VERSION,
	PARAM_SAVE_PARAMETERS,		// seeking parameter block in application for current parameter
	PARAM_SAVE_NEW_PARAMETERS,	// writing parameters at the end of all blocks
	PARAM_SAVE_END_PARAM,		// save a trailing parameter header after all parameters
    } paramState;
    static uint16_t currentBlock;	// byte index in EEPROM for where we are in processing data

    // Used to mark a block of parameters for ConfigSave and for
    // recovering parameters. The application ID is the application
    // portion of endAppParam. It is the same for the current parameter
    // and the last parameter so the application is not stored in
    // duplicate.
    uint8_t nextParamID;		// the next parameter to fetch/store
    AppParamID_t endAppParam;		// current application ID and the last parameter ID
    bool rescanRequired;		// rescan after adding one paramter at the end of the world.


    command result_t StdControl.init()
    {
	paramState = PARAM_NEVER_STARTED;
	nextParamID = 0;
	call EEPROMstdControl.init();
	call Leds.init();
	return SUCCESS;
    }

    // Temporary data for split phase read/write to flash.
    union {
	FlashVersionBlock_t versionInfo;
	ParameterBlock_t param;
	uint8_t data[1];		// ReadData.read and WriteData.write use a pointer to this cell
    } flashTemp;

    command result_t StdControl.start()
    {
	// At startup read all parameters from EEprom and push them out to
	// memory cells via the Config interface.
	SODbg(DBG_TEMP,"\n\nEEPROMConfigM.start\n");
	if (paramState == PARAM_IDLE) return SUCCESS;
	if (paramState == PARAM_NEVER_STARTED) {
	    call EEPROMstdControl.start();
	    // Initiate the sequence of reads
	    paramState = PARAM_READ_VERSION;
	    currentBlock = BASE_OF_PARAMETERS;
	    rescanRequired = FALSE;
	    call ReadData.read(currentBlock,&flashTemp.data[0],sizeof(FlashVersionBlock_t));
	};
	return SUCCESS;
    }

    command result_t StdControl.stop()
    {
	return SUCCESS;
    }

#if 0
    // ??? It is unfortunate that this routine is not exposed in the
    // radio stack. We would like to use it from there to save code
    // space. Note that if we can use the CRC routine from there the
    // 'includes crc;' line at the top of this file should be removed
    // too.
    extern uint16_t calcrc(uint8_t *ptr, uint8_t count);
#else
    // Internal function to calculate 16 bit CRC
    uint16_t calcrc(uint8_t *ptr, uint8_t count) {
	uint16_t crc;

	crc = 0;
	while (count-- > 0)
	    crc = crcByte(crc, *ptr++);

	return crc;
    }
#endif

    // Check the CRC of a block that starts with a CRC cell and is of
    // some length. Determine if the CRC matches the CRC in the block.
    //
    // Inputs:
    //	pBlock		pointer to block to check, the CRC is the first
    //			cell in the block,
    //	length
    // Returns:
    //	TRUE if CRC matches CRC cell, false otherwise
    static bool checkBlockCRC(void *pBlock,size_t length)
    {
	ParamCRC_t calcCRC;

	calcCRC = *((ParamCRC_t *)pBlock);
	if (length < sizeof(ParamCRC_t)) return FALSE; // error, reject it
	if (length == sizeof(ParamCRC_t)) return TRUE; // only the CRC is present OK.
	if (calcCRC != calcrc( (((uint8_t *)pBlock)+sizeof(ParamCRC_t)),
			       (uint8_t)(length-sizeof(ParamCRC_t)))) return FALSE;
	return TRUE;
    }


    // Set the CRC of a block that starts with a CRC cell and is of
    // some length.
    //
    // Inputs:
    //	pBlock		pointer to block to check, the CRC is the first
    //			cell in the block,
    //	length
    static void setBlockCRC(void *pBlock,size_t length)
    {
	if (length < sizeof(ParamCRC_t)) return;
	*((ParamCRC_t *)pBlock) = calcrc( (((uint8_t *)pBlock)+sizeof(ParamCRC_t)),
					  (uint8_t)(length-sizeof(ParamCRC_t)) );
	return;
    }

    // Write a trailing parameter block. Drive the state to saving new
    // parameters at the end of the world.
    static void writeTrailingParameter() {
	paramState = PARAM_SAVE_NEW_PARAMETERS;
	flashTemp.param.paHdr.count = 0;
	flashTemp.param.paHdr.applicationID = TOS_NO_APPLICATION;
	flashTemp.param.paHdr.paramID = TOS_NO_PARAMETER;
	setBlockCRC(&flashTemp.param.paHdr,sizeof(ParameterHeader_t));
	call WriteData.write(currentBlock,&flashTemp.data[0],sizeof(ParameterHeader_t));
	return;
    }

    // Hunt for the next parameter with a non-zero size
    // Global variables are updated that point to the next parameter
    // number of the application writing parameters.
    static void findNextParameter() {
	while (TRUE) {
	    uint16_t paramSize;
	    if (nextParamID > GET_PARAM_ID(endAppParam)) {
//		SODbg(DBG_TEMP,"findNextParameter no more at %d end %d\n",nextParamID,GET_PARAM_ID(endAppParam));
		return;
	    };
	    paramSize = call Config.get[APP_PARAM_ID(GET_APP_ID(endAppParam),nextParamID)](NULL,0);
	    // skip parameters that are not used or available
//	    SODbg(DBG_TEMP,"findNextParameter param %d had size %d\n",nextParamID,paramSize);
	    if (paramSize != 0) {
		// found a real parameter
//		SODbg(DBG_TEMP,"findNextParameter found %d size %d\n",nextParamID,paramSize);
		return;
	    };
	    nextParamID += 1;
	};
    }

    event result_t WriteData.writeDone(uint8_t *pWriteBuffer,uint32_t writeNumBytesWrite,result_t result)
    {
	switch (paramState) {
	    case PARAM_NEVER_STARTED:
	    case PARAM_IDLE:
	    case PARAM_READ_VERSION:
	    case PARAM_READ_PARAMETER:
	    default:
		// These should never have initiated a write
		return FAIL;
	    case PARAM_SAVE_VERSION:
		// A new version block is saved now write an ending
		// parameter. The write done will go on to saving new
		// parameters.
		SODbg(DBG_TEMP,"SAVE_VERSION Start save of trailing parameter block at %d.\n",currentBlock);
		writeTrailingParameter();
		return SUCCESS;
	    case PARAM_SAVE_NEW_PARAMETERS:
		// Just wrote a parameter at the end of the world.
		if (!rescanRequired) {
		    // Find the next parameter to write
		    findNextParameter();
		    if (nextParamID > GET_PARAM_ID(endAppParam)) {
			SODbg(DBG_TEMP,"SAVE_NEW_PARAMETERS no more parameters\n");
		    } else {
			SODbg(DBG_TEMP,"SAVE_NEW_PARAMETERS next param to write is %d\n",nextParamID);
		    };
		};
		if (rescanRequired || (nextParamID > GET_PARAM_ID(endAppParam))) {
		    // Either we are at the end or have to rescan
		    // earlier application blocks.
		    // Write the trailing parameter block.
		    // The writeDone will come back later and determine if a
		    // rescan is required for other parameters.
		    SODbg(DBG_TEMP,"SAVE_NEW_PARAMETERS start write of ending parameter at %d (rescan is %d)\n",
			  currentBlock,rescanRequired);
		    writeTrailingParameter();
		    paramState = PARAM_SAVE_END_PARAM;
		    return SUCCESS;
		};
		{
		    size_t paramSize;
		    // Initiate write of parameter at the end of the
		    // world.
		    paramSize = call Config.get[APP_PARAM_ID(GET_APP_ID(endAppParam),nextParamID)](&flashTemp.param.data[0],
			sizeof(flashTemp.param.data));
#if (SO_DEBUG)
		    {
			int32_t value;
			switch (paramSize) {
			    case 1:
				value = (*(uint8_t *)flashTemp.param.data);
				break;
			    case 2:
				value = (*(uint16_t *)flashTemp.param.data);
				break;
			    case 4:
				value = (*(uint32_t *)flashTemp.param.data);
				break;
			    default:
				value = 0;
				SODbg(DBG_TEMP,"Value can not be printed in:\n");
				break;
			};
			SODbg(DBG_TEMP,"SAVE_NEW_PARAMETERS start write of param %d value %ld size %d at %d\n",nextParamID,
			      value,paramSize,currentBlock);
		    }
#endif
		    flashTemp.param.paHdr.count = MIN(paramSize,sizeof(flashTemp.param.data));
		    flashTemp.param.paHdr.applicationID = GET_APP_ID(endAppParam);
		    flashTemp.param.paHdr.paramID = nextParamID;
		    paramSize += sizeof(ParameterHeader_t);
		    setBlockCRC(&flashTemp.param.paHdr,paramSize);
		    call WriteData.write(currentBlock,&flashTemp.data[0],paramSize);
		    currentBlock += paramSize;
		    nextParamID += 1;
		}
		return SUCCESS;
	    case PARAM_SAVE_PARAMETERS:
		// Save of a single parameter in an existing
		// application block succeeded. Initiate a read of the
		// next parameter from flash. When the read comes back
		// try to update the value.
		while (TRUE) {
		    size_t paramSize;
		    if (nextParamID > GET_PARAM_ID(endAppParam)) {
			// Just wrote the last parameter
			SODbg(DBG_TEMP,"SAVE_PARAMETERS write OK, all done\n");
			paramState = PARAM_IDLE;
			signal ConfigSave.saveDone(SUCCESS,endAppParam);
			return SUCCESS;
		    };
		    paramSize = call Config.get[APP_PARAM_ID(GET_APP_ID(endAppParam),nextParamID)](NULL,0);
		    // skip parameters that are not used or available
		    if (paramSize != 0) {
			SODbg(DBG_TEMP,"SAVE_PARAMETERS write OK next is %d size %d\n",nextParamID,paramSize);
			break; // found a real one
		    };
		    nextParamID += 1;
		};
		call ReadData.read(currentBlock,&flashTemp.data[0],sizeof(ParameterBlock_t));
		break;
	    case PARAM_SAVE_END_PARAM:
		if (nextParamID > GET_PARAM_ID(endAppParam)) {
		    SODbg(DBG_TEMP,"SAVE_END_PARAM write OK, all done\n");
		    paramState = PARAM_IDLE;
		    signal ConfigSave.saveDone(SUCCESS,endAppParam);
		    return SUCCESS;
		};
		if (rescanRequired) {
		    // Wrote a parameter at the end of the world.
		    // Start over from the first application looking
		    // for the next parameter to write in earlier
		    // application blocks.
		    SODbg(DBG_TEMP,"SAVE_END_PARAM start rescan\n");
		    currentBlock = BASE_OF_PARAMETERS + sizeof(FlashVersionBlock_t);
		    rescanRequired = FALSE;
		};
		paramState = PARAM_SAVE_PARAMETERS;
		call ReadData.read(currentBlock,&flashTemp.data[0],sizeof(ParameterBlock_t));
		return SUCCESS;
	};
	return SUCCESS;
    }

    event result_t ReadData.readDone(uint8_t *pReadBuffer,uint32_t readByteCount,result_t result)
    {
	if (pReadBuffer != &flashTemp.data[0]) {
	    // Getting here is a serious bug. Abort everything. Higher
	    // level code may be expecting a 'done' event which will
	    // never come.
	    SODbg(DBG_TEMP,"readDone bad pointer\n");
	    paramState = PARAM_IDLE;
	    return SUCCESS;
	};
	if (result == FAIL) {
	    paramState = PARAM_IDLE;
	    SODbg(DBG_TEMP,"readDone failed to read flash\n");
	    return SUCCESS;
	};
	// We assume that the read byte count matches the requested
	// byte count. This may be an issue.
	switch (paramState) {
	    default:
		paramState = PARAM_IDLE;
	    case PARAM_NEVER_STARTED:
	    case PARAM_IDLE:
		SODbg(DBG_TEMP,"readDone at PARAM_IDLE\n");
		return FAIL;
	    case PARAM_READ_VERSION:
	    {
		// Validate the version block and initiate parameter
		// block reads.
		SODbg(DBG_TEMP,"READ_VERSION wants %d got major %d minor %d\n",PARAM_MAJOR_VERSION,
		      flashTemp.versionInfo.vHdr.majorVersion,
		      flashTemp.versionInfo.vHdr.minorVersion);
		if (PARAM_MAJOR_VERSION != flashTemp.versionInfo.vHdr.majorVersion) {
		    // there is no compatible version info, quit
		    if (flashTemp.versionInfo.vHdr.majorVersion != ParameterIgnoreVersion) {
			SODbg(DBG_TEMP,"READ_VERSION wrong version\n");
		    };
		    paramState = PARAM_IDLE;
		    return SUCCESS;
		};
		if (!checkBlockCRC(&flashTemp.versionInfo,sizeof(FlashVersionBlock_t))) {
		    // bad CRC reject everything else
		    SODbg(DBG_TEMP,"READ_VERSION bad CRC\n");
		    paramState = PARAM_IDLE;
		    return SUCCESS;
		};
		paramState = PARAM_READ_PARAMETER;
		currentBlock += sizeof(FlashVersionBlock_t);
		call ReadData.read(currentBlock,&flashTemp.data[0],sizeof(ParameterBlock_t));
		return SUCCESS;
	    }
	    case PARAM_READ_PARAMETER:
		if (flashTemp.param.paHdr.paramID == TOS_UNUSED_PARAMETER) {
		    // Error to find illegal parameter number
		    SODbg(DBG_TEMP,"READ_PARAMETER illegal to find TOS_UNUSED_PARAMETER\n");
		    paramState = PARAM_IDLE;
		    return SUCCESS;
		};
		currentBlock += sizeof(ParameterHeader_t) + flashTemp.param.paHdr.count;
		if (!checkBlockCRC(&flashTemp.param.paHdr,(sizeof(ParameterHeader_t) + flashTemp.param.paHdr.count))) {
		    // bad CRC reject everything else
		    SODbg(DBG_TEMP,"READ_PARAMETER bad CRC\n");
		    paramState = PARAM_IDLE;
		    return SUCCESS;
		};
		if(flashTemp.param.paHdr.paramID == TOS_NO_PARAMETER) {
		    SODbg(DBG_TEMP,"READ_PARAMETER all parameters read\n");
		    paramState = PARAM_IDLE;
		    return SUCCESS;
		};
		if ((flashTemp.param.paHdr.applicationID != TOS_NO_APPLICATION)
		      && (flashTemp.param.paHdr.paramID != TOS_IGNORE_PARAMETER)) {
		    // Store this parameter to memory
#if (SO_DEBUG)
		    {
			int32_t value;
			switch (flashTemp.param.paHdr.count) {
			    case 1:
				value = (*(uint8_t *)flashTemp.param.data);
				break;
			    case 2:
				value = (*(uint16_t *)flashTemp.param.data);
				break;
			    case 4:
				value = (*(uint32_t *)flashTemp.param.data);
				break;
			    default:
				value = 0;
				SODbg(DBG_TEMP,"Value can not be printed in:\n");
				break;
			};
			SODbg(DBG_TEMP,"READ_PARAMETER app %ld ID %d size %d value %ld from flash to RAM\n",
			      (uint32_t)flashTemp.param.paHdr.applicationID,
			      (uint16_t)flashTemp.param.paHdr.paramID,
			      (int)flashTemp.param.paHdr.count,value);
		    }
#endif
		    if (SUCCESS != call Config.set[APP_PARAM_ID(flashTemp.param.paHdr.applicationID,
			flashTemp.param.paHdr.paramID)](&flashTemp.param.data,
			flashTemp.param.paHdr.count)) {
			SODbg(DBG_TEMP,"READ_PARAMETER write to RAM failed\n");
		    };
		};
		paramState = PARAM_READ_PARAMETER;
		call ReadData.read(currentBlock,&flashTemp.data[0],sizeof(ParameterBlock_t));
		return SUCCESS;
	    case PARAM_SAVE_VERSION:
	    {
		// Saving parameters. First we validate the version
		// block. If it is not there we have to write it.
		// If it is present and valid then hunt for the
		// existing parameter to write.
		if (flashTemp.versionInfo.vHdr.majorVersion != ParameterIgnoreVersion) {
		    SODbg(DBG_TEMP,"SAVE_VERSION read %d(%d)-%d bytes=%d\n",flashTemp.versionInfo.vHdr.majorVersion,
			  flashTemp.versionInfo.vHdr.minorVersion,flashTemp.versionInfo.vHdr.buildNumber,
			  flashTemp.versionInfo.vHdr.bytes);
		};
		if (PARAM_MAJOR_VERSION != flashTemp.versionInfo.vHdr.majorVersion) {
		    // Always write the parameters, even if there is an
		    // old version block. Use the test below to accept
		    // empty blocks and never rewrite old versions.
		    if ((flashTemp.versionInfo.vHdr.majorVersion == ParameterIgnoreVersion)
			  || (flashTemp.versionInfo.vHdr.majorVersion == 0)){
			SODbg(DBG_TEMP,"SAVE_VERSION found empty parameter storage. Writing version block.\n");
		    } else {
			SODbg(DBG_TEMP,"SAVE_VERSION version mismatch. Discarding old parameters writing new version block.\n");
		    };
		    flashTemp.versionInfo.vHdr.majorVersion = PARAM_MAJOR_VERSION;
		    flashTemp.versionInfo.vHdr.minorVersion = PARAM_MINOR_VERSION;
		    flashTemp.versionInfo.vHdr.buildNumber = 0;
		    flashTemp.versionInfo.vHdr.bytes = sizeof(FlashVersionBlock_t) - sizeof(FlashVersionHeader_t);
		    memset(&flashTemp.versionInfo.d.data,sizeof(FlashVersionData_t),0);
		    setBlockCRC(&flashTemp.versionInfo,sizeof(FlashVersionBlock_t));
		    currentBlock = BASE_OF_PARAMETERS;
		    call WriteData.write(currentBlock,&flashTemp.data[0],sizeof(FlashVersionBlock_t));
		    currentBlock += sizeof(FlashVersionBlock_t);
		    return SUCCESS;
		};
		if (!checkBlockCRC(&flashTemp.versionInfo,sizeof(FlashVersionBlock_t))) {
		    // bad CRC reject everything else
		    SODbg(DBG_TEMP,"SAVE_VERSION read bad CRC\n");
		    paramState = PARAM_IDLE;
		    signal ConfigSave.saveDone(FAIL,APP_PARAM_ID(GET_APP_ID(endAppParam),nextParamID));
		    return SUCCESS;
		};
		if (PARAM_MAJOR_VERSION != flashTemp.versionInfo.vHdr.majorVersion) {
		    // there is no compatible version info, quit
		    SODbg(DBG_TEMP,"SAVE_VERSION major version mismatch, write aborted.\n");
		    paramState = PARAM_IDLE;
		    signal ConfigSave.saveDone(FAIL,APP_PARAM_ID(GET_APP_ID(endAppParam),nextParamID));
		    return SUCCESS;
		};
		paramState = PARAM_SAVE_PARAMETERS;
		currentBlock += sizeof(FlashVersionBlock_t);
		call ReadData.read(currentBlock,&flashTemp.data[0],sizeof(ParameterBlock_t));
		SODbg(DBG_TEMP,"SAVE_VERSION version block OK look for first parameter to save.\n");
		return SUCCESS;
	    }
	    case PARAM_SAVE_PARAMETERS:
		if (flashTemp.param.paHdr.paramID == TOS_NO_PARAMETER) {
		    // No more paramaters to read. Rewrite the trailing
		    // block with good CRC. The writeDone will
		    // then start writing parameters at the end of the
		    // world.
		    writeTrailingParameter();
		    return SUCCESS;
		};
		if (!checkBlockCRC(&flashTemp.param.paHdr,(sizeof(ParameterHeader_t) + flashTemp.param.paHdr.count))) {
		    // bad CRC reject everything else
		    SODbg(DBG_TEMP,"SAVE_PARAMETERS read parameter with bad CRC at %d\n",currentBlock);
		    paramState = PARAM_IDLE;
		    signal ConfigSave.saveDone(FAIL,APP_PARAM_ID(GET_APP_ID(endAppParam),nextParamID));
		    return SUCCESS;
		};
		if (GET_APP_ID(endAppParam) == flashTemp.param.paHdr.applicationID) {
		    if (flashTemp.param.paHdr.paramID == nextParamID) {
			// Found the parameter we are trying to write
			size_t paramSize;
			SODbg(DBG_TEMP,"SAVE_PARAMETERS app %ld param %d write new value at %d\n",
			      (uint32_t)flashTemp.param.paHdr.applicationID,nextParamID,currentBlock);
			paramSize = call Config.get[APP_PARAM_ID(GET_APP_ID(endAppParam),nextParamID)](&flashTemp.param.data[0],
			    sizeof(flashTemp.param.data));
			if (paramSize != flashTemp.param.paHdr.count) {
			    // Sizes do not match. Mark the old one as
			    // ignore. We will create a new one later.
			    // Completion of the write will reread this
			    // parameter block and skip over it. The
			    // parameter will then be written later.
			    SODbg(DBG_TEMP,"SAVE_PARAMERTERS size mismatch write TOS_IGNORE_PARAMETER\n"); 
			    flashTemp.param.paHdr.paramID = TOS_IGNORE_PARAMETER;
			};
			setBlockCRC(&flashTemp.param.paHdr,(sizeof(ParameterHeader_t) + flashTemp.param.paHdr.count));
			call WriteData.write(currentBlock,&flashTemp.data[0],
					     (sizeof(ParameterHeader_t) + flashTemp.param.paHdr.count));
			currentBlock += sizeof(ParameterHeader_t) + flashTemp.param.paHdr.count;
			if (paramSize != flashTemp.param.paHdr.count) {
			    // Completion of the write will reread this
			    // parameter block and skip over it. The
			    // parameter will then be written later.
			    return SUCCESS;
			} else {
			    // Completion of the write will look for
			    // the next parameter, rereading and
			    // skiping this one
			    nextParamID += 1;
			    return SUCCESS;
			};
		    };
		    if (flashTemp.param.paHdr.paramID > nextParamID) {
			// Did not find the parameter we are trying to
			// write but a later parameter of this
			// application has been found. Keep searching
			// for the current parameter but remember that
			// the next parameter we try to write may be
			// earlier in the memory. The flag set here will
			// start over after writing this parameter
			// rescanning all earlier blocks and finding the
			// other parameters.
			SODbg(DBG_TEMP,"SAVE_PARAMETERS rescan is required found %d while seeking %d\n",
			      flashTemp.param.paHdr.paramID,nextParamID); 
			rescanRequired = TRUE;
		    };
		};
		currentBlock += sizeof(ParameterHeader_t) + flashTemp.param.paHdr.count;
		SODbg(DBG_TEMP,"SAVE_PARAMETERS read next param %d\n",nextParamID); 
		call ReadData.read(currentBlock,&flashTemp.data[0],sizeof(ParameterBlock_t));
		return SUCCESS;
	    case PARAM_SAVE_END_PARAM:
		SODbg(DBG_TEMP,"readDone in SAVE_END_PARAM, probably a BUG.\n");
		//... fall into PARAM_SAVE_NEW_PARAMETERS
	    case PARAM_SAVE_NEW_PARAMETERS:
		// BUG to be reading something when trying to save new
		// parameters or trailing header.
		SODbg(DBG_TEMP,"readDone in SAVE_NEW_PARAMETERS, probably a BUG.\n");
		paramState = PARAM_IDLE;
		signal ConfigSave.saveDone(FAIL,APP_PARAM_ID(GET_APP_ID(endAppParam),nextParamID));
		return FAIL;
	};
	// Error to ever get here
	return FAIL;
    }


    // Read each parameter from memory and store it in EEPROM
    // Save all  parameters in range start to end inclusive.
    // The save occurs in order. Parameters that follow any failure
    // are not saved. The parameters must have the same application ID.
    //
    // Inputs:
    //	startParam	first parameter ID of set to save
    //	endParam	last parameter ID of set
    // Returns:
    //	FAIL could not start save, one might already be running OR
    //		illegal argument types OR start > end. A saveDone event
    //		will not occur.
    //	SUCCESS save in progress. Completion will be reported with a
    //		saveDone event.
    command result_t ConfigSave.save(AppParamID_t startParam, AppParamID_t endParam)
    {
	call Leds.redToggle();
	if (paramState != PARAM_IDLE) {
	    // can not save parameters right now.
	    SODbg(DBG_TEMP,"configSave.save SAVE is busy\n");
	    return FAIL;
	};
	if (GET_APP_ID(startParam) != GET_APP_ID(endParam)) {
	    SODbg(DBG_TEMP,"configSave.save APP ID mismatch start: %d end: %d\n",
		  (int)GET_APP_ID(startParam),(int)GET_APP_ID(endParam));
	    return FAIL; // ERROR: not the same APP
	};
	endAppParam = endParam;
	nextParamID = GET_PARAM_ID(startParam);
	if (GET_PARAM_ID(endAppParam) < nextParamID) {
	    SODbg(DBG_TEMP,"configSave.save end before start\n");
	    nextParamID = 0;
	    return FAIL; // ERROR: end < start
	};
	call Leds.redToggle();
	SODbg(DBG_TEMP,"configSave.save save started app %ld start %d end %d\n",
	     (uint32_t)GET_APP_ID(endParam),(uint16_t)nextParamID,(uint16_t)GET_PARAM_ID(endParam));
	findNextParameter();		// move forward to the first parameter with non 0 size.
	paramState = PARAM_SAVE_VERSION;
	call EEPROMstdControl.start();
	currentBlock = BASE_OF_PARAMETERS;
	call ReadData.read(currentBlock,&flashTemp.data[0],sizeof(FlashVersionBlock_t));
	return SUCCESS;
    }

}

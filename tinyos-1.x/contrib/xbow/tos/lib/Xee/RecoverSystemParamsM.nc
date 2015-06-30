// Save and restore of TOS_AM_GROUP and TOS_LOCAL_ADDRESS
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
//
// @Author: Michael Newman, Hu Siquan
//
// $Id: RecoverSystemParamsM.nc,v 1.1 2005/04/04 09:50:42 husq Exp $

#define RecoverSystemParamsMedit 1

includes config;

module RecoverSystemParamsM {
  provides interface ConfigInt8 as SystemGroupNumber;
  provides interface ConfigInt16 as SystemMoteID;
  provides interface ConfigInt8 as SystemModelType;
  provides interface ConfigInt8 as SystemSuModelType;
  provides interface ConfigInt8 as SystemMoteCPUType;
  provides interface ConfigInt8 as SystemRadioType;
  provides interface ConfigInt16 as SystemVendorID;
  provides interface Config as SystemSerialNumber;
  provides interface Config as SystemCPUOscillatorFrequency;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)  
  provides interface Config as CC1KTuneHZ;  // 32 bits of frequency * 1,000,000
  provides interface Config as CC1KLowerHZ; // 32 bits of frequency * 1,000,000
  provides interface Config as CC1KUpperHZ; // 32 bits of frequency * 1,000,000
  provides interface ConfigInt8 as CC1KRFChannel; // 8 bits of rf channel, refer to CC1kconst.h for preset rf channel
  provides interface ConfigInt8 as CC1KRFPower; // 8 biss of rf power, from 0x0 to 0xff
#else
  provides interface ConfigInt8 as CC2420RFChannel; // 8 bits of rf channel, refer to CC1kconst.h for preset rf channel
  provides interface ConfigInt8 as CC2420RFPower; // 8 biss of rf power, from 0x0 to 0xff
#endif  
  provides interface Config as CrossbowFactoryInfo1; // 16 bytes of factory information (printable ascii)
  provides interface Config as CrossbowFactoryInfo2; // 16 bytes of factory information (printable ascii)
  provides interface Config as CrossbowFactoryInfo3; // 16 bytes of factory information (printable ascii)
  provides interface Config as CrossbowFactoryInfo4; // 16 bytes of factory information (printable ascii)  
  
  uses {
  	interface StdControl as CommControl;
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)   	
  	interface CC1000Control;
	interface HPLCC1000 as HPLChipcon;
#else
  	interface CC2420Control;
	interface HPLCC2420 as HPLChipcon;
#endif	
    // SerialID
	interface StdControl as DS2401;  
	interface HardwareId;
  	}
}
implementation {
	
#ifndef MIN
#define MIN(_a,_b) ((_a < _b) ? _a : _b)
#endif

  command int16_t SystemMoteID.get() {
    return TOS_LOCAL_ADDRESS;
  }

  command result_t SystemMoteID.set(int16_t value) {
      if (value == TOS_BCAST_ADDR) {
	  // Not allowed to set address to broadcast address
	  return FAIL;
      };	  
      atomic {
	  TOS_LOCAL_ADDRESS = value;
      };
      return SUCCESS;
  }

  command int8_t SystemGroupNumber.get() {
      return TOS_AM_GROUP;
  }

  command result_t SystemGroupNumber.set(int8_t value) {
      TOS_AM_GROUP = value;
      return SUCCESS;
  }
  
  int8_t sysModelType = TOS_MODEL_UNKNOWN; // default value
  command int8_t SystemModelType.get() {
  	return sysModelType;  	
  }
  
  command result_t SystemModelType.set(int8_t value) {
  	  sysModelType = value; 
  	  return SUCCESS; 	
  }

  int8_t sysSubModelType = TOS_SUBMODEL_UNKNOWN; // default value
  command int8_t SystemSuModelType.get() {
  	return sysSubModelType;  	
  }
  
  command result_t SystemSuModelType.set(int8_t value) {
  	  sysSubModelType = value; 
  	  return SUCCESS; 	
  }

  int8_t sysMoteCPUType = TOS_CPU_TYPE_UNKNOWN; // default value
  command int8_t SystemMoteCPUType.get() {
  	return sysMoteCPUType;  	
  }
  
  command result_t SystemMoteCPUType.set(int8_t value) {
  	  sysMoteCPUType = value; 
  	  return SUCCESS; 	
  }
  
  int8_t sysRadioType = TOS_RADIO_TYPE_UNKNOWN; // default value
  command int8_t SystemRadioType.get() {
  	return sysRadioType;  	
  }
  
  command result_t SystemRadioType.set(int8_t value) {
  	  sysRadioType = value; 
  	  return SUCCESS; 	
  }
  	  
  int16_t sysVendorID = TOS_VENDOR_UNKNOWN; // default value
  command int16_t SystemVendorID.get() {
  	return sysVendorID;  	
  }
  
  command result_t SystemVendorID.set(int16_t value) {
  	  sysVendorID = value; 
  	  return SUCCESS; 	
  }
  
  command size_t SystemSerialNumber.get(void *buffer, size_t size) {
	if (buffer != NULL) {
		  call DS2401.init();
	  	  call HardwareId.read((uint8_t *)buffer);
    }
	return 8;
  }

  command result_t SystemSerialNumber.set(void *buffer, size_t size) {
	return SUCCESS;
  }
  
  int32_t sysCPUOscillatorFrequency = 0; // default value

  command size_t SystemCPUOscillatorFrequency.get(void *buffer, size_t size) {
	if (buffer != NULL) {
	    memcpy(buffer,&sysCPUOscillatorFrequency, MIN(size,sizeof(sysCPUOscillatorFrequency)));
    };
	return sizeof(sysCPUOscillatorFrequency);
  }

  command result_t SystemCPUOscillatorFrequency.set(void *buffer, size_t size) {
	int32_t value;
	if (size != sizeof sysCPUOscillatorFrequency)
	    return FAIL;
	value = *(int32_t *)buffer;
	sysCPUOscillatorFrequency = value;
	return SUCCESS;
  }
  
  
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)   	  
   /*
   * CC1KTuneHZ.get(void *buffer, size_t size)
   *
   * Compute the achieved frequency in Hz from the CC1K parameters read from
   * CC1K registers. 
   *
   * This routine assumes the following:
   *  - Crystal Freq: 14.7456 MHz
   *  - LO Injection: High
   *  - Separation: 64 KHz
   *  - IF: 150 KHz
   */
  command size_t CC1KTuneHZ.get(void *buffer, size_t size) {
  	uint32_t cc1kTuneFreq = 0; // default value
  	double FRef, LOFreq, RXchanel, dFsep;
  	uint32_t RXFreq;
  	uint32_t FSep = 0;
  	uint8_t freq2A, freq1A, freq0A, Fsep1, Fsep0;
  	
  	freq2A = call HPLChipcon.read(CC1K_FREQ_2A);
  	freq1A = call HPLChipcon.read(CC1K_FREQ_1A);
  	freq0A = call HPLChipcon.read(CC1K_FREQ_0A);
  	Fsep1  = call HPLChipcon.read(CC1K_FSEP1);
  	Fsep0  = call HPLChipcon.read(CC1K_FSEP0);	
  	
  	RXFreq =  (((uint32_t)freq2A) << 16) + (((uint32_t)freq1A)  << 8) + freq0A;
  	FSep   =  (((uint32_t)Fsep1) << 8) +  Fsep0;
  	
	dFsep = FSep + (FSep % 10) * 0.1111111;
  	FRef = ( 64.0 * 16384.0) / ( dFsep * 1000.0);
  	LOFreq = ( (double)RXFreq + 8192.0) * FRef/16384.0 ;  	
  	RXchanel = LOFreq - 150.0 / 1000.0;  	
  	cc1kTuneFreq = (uint32_t)(RXchanel*1000000);

	if (buffer != NULL) {
	    memcpy(buffer,&cc1kTuneFreq, MIN(size,sizeof(cc1kTuneFreq))); // cc1kTuneFreq
	};
	return sizeof(cc1kTuneFreq);
  }

  command result_t CC1KTuneHZ.set(void *buffer, size_t size) {
	int32_t cc1kTuneFreq;
	if (size != sizeof cc1kTuneFreq)
	    return FAIL;
	cc1kTuneFreq = *(int32_t *)buffer;
	call CommControl.stop();
	call CC1000Control.TuneManual(cc1kTuneFreq);
	call CommControl.start();

	return SUCCESS;
  }
  
  int32_t cc1kLowerFreq = 0; // default value

  command size_t CC1KLowerHZ.get(void *buffer, size_t size) {
	if (buffer != NULL) {
	    memcpy(buffer,&cc1kLowerFreq, MIN(size,sizeof(cc1kLowerFreq)));
    };
	return sizeof(cc1kLowerFreq);
  }

  command result_t CC1KLowerHZ.set(void *buffer, size_t size) {
	int32_t value;
	if (size != sizeof cc1kLowerFreq)
	    return FAIL;
	value = *(int32_t *)buffer;
	cc1kLowerFreq = value;
	return SUCCESS;
  }
  
  int32_t cc1kUpperFreq = 0; // default value

  command size_t CC1KUpperHZ.get(void *buffer, size_t size) {
	if (buffer != NULL) {
	    memcpy(buffer,&cc1kUpperFreq, MIN(size,sizeof(cc1kUpperFreq)));
    };
	return sizeof(cc1kUpperFreq);
  }

  command result_t CC1KUpperHZ.set(void *buffer, size_t size) {
	int32_t value;
	if (size != sizeof cc1kUpperFreq)
	    return FAIL;
	value = *(int32_t *)buffer;
	cc1kUpperFreq = value;
	return SUCCESS;
  }
  
  command int8_t CC1KRFPower.get() {
    return call CC1000Control.GetRFPower();
  }

  command result_t CC1KRFPower.set(int8_t value) {
      call CC1000Control.SetRFPower(value);
      return SUCCESS;
  }

  command int8_t CC1KRFChannel.get(){
    // read the registers
    // check the table to find the correct working freq
    // where is the table? In prog flash, prog_param(CC1K_Params[][])
    int ch_index=0;
    uint8_t freq2A, freq1A, freq0A;
  	
    freq2A = call HPLChipcon.read(CC1K_FREQ_2A);
    freq1A = call HPLChipcon.read(CC1K_FREQ_1A);
    freq0A = call HPLChipcon.read(CC1K_FREQ_0A);
    while(ch_index<=CC1K_MAX_RF_CHANNEL)
      {
		if((freq2A == PRG_RDB(&CC1K_Params[ch_index][1]))&& 
	   		(freq1A == PRG_RDB(&CC1K_Params[ch_index][2]))&&
	   		(freq0A == PRG_RDB(&CC1K_Params[ch_index][3])))
		{
	  		break;
		}
		else
		{
	  		ch_index++;
		}
      }
    return ch_index;
  }

  command result_t CC1KRFChannel.set(int8_t value) {
	call CommControl.stop();
	call CC1000Control.TunePreset(value);
	call CommControl.start();
	return SUCCESS;
  }
#else
  
  command int8_t CC2420RFPower.get() {
    return call CC2420Control.GetRFPower();
  }

  command result_t CC2420RFPower.set(int8_t value) {
      call CC2420Control.SetRFPower(value);
      return SUCCESS;
  }
  
    command int8_t CC2420RFChannel.get(){
    // read the registers to get CC2420 channel
    // For operation in channel k, the FSCTRL.FREQ 
    // register should therefore be set to: FSCTRL.FREQ = 357 + 5 (k-11)
    // Valid channel values are 11 through 26.
    int channel = 11;
    channel = (((call HPLChipcon.read(CC2420_FSCTRL))&0x03ff)-357)/5.0 + 11;
    return channel;
  }

  command result_t CC2420RFChannel.set(int8_t value) {
	call CommControl.stop();
	call CC2420Control.TunePreset(value);
	call CommControl.start();
	return SUCCESS;
  }

#endif  
  
  uint8_t xbowFacInfo1[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,}; // default value

  command size_t CrossbowFactoryInfo1.get(void *buffer, size_t size) {
	if (buffer != NULL) {
	    memcpy(buffer,xbowFacInfo1, MIN(size,16*sizeof(uint8_t)));
    };
	return 16*sizeof(uint8_t);
  }

  command result_t CrossbowFactoryInfo1.set(void *buffer, size_t size) {
	uint8_t *value;
	int i;
	if (size != 16*sizeof(uint8_t))
	    return FAIL;
	value = (uint8_t *)buffer;
	for(i=0;i<16;i++) xbowFacInfo1[i] = value[i];
	return SUCCESS;
  }
  
  uint8_t xbowFacInfo2[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,}; // default value

  command size_t CrossbowFactoryInfo2.get(void *buffer, size_t size) {
	if (buffer != NULL) {
	    memcpy(buffer,xbowFacInfo2, MIN(size,16*sizeof(uint8_t)));
    };
	return 16*sizeof(uint8_t);
  }

  command result_t CrossbowFactoryInfo2.set(void *buffer, size_t size) {
	uint8_t *value;
	int i;
	if (size != 16*sizeof(uint8_t))
	    return FAIL;
	value = (uint8_t *)buffer;
	for(i=0;i<16;i++) xbowFacInfo2[i] = value[i];
	return SUCCESS;
  }
  
  int8_t xbowFacInfo3[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,}; // default value

  command size_t CrossbowFactoryInfo3.get(void *buffer, size_t size) {
	if (buffer != NULL) {
	    memcpy(buffer,xbowFacInfo3, MIN(size,16*sizeof(uint8_t)));
    };
	return 16*sizeof(uint8_t);
  }

  command result_t CrossbowFactoryInfo3.set(void *buffer, size_t size) {
	int8_t *value;
	int i;
	if (size != 16*sizeof(uint8_t))
	    return FAIL;
	value = (int8_t *)buffer;
	for(i=0;i<16;i++) xbowFacInfo3[i] = value[i];
	return SUCCESS;
  }
  
  int8_t xbowFacInfo4[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,}; // default value

  command size_t CrossbowFactoryInfo4.get(void *buffer, size_t size) {
	if (buffer != NULL) {
	    memcpy(buffer,xbowFacInfo4, MIN(size,16*sizeof(uint8_t)));
    };
	return 16*sizeof(uint8_t);
  }

  command result_t CrossbowFactoryInfo4.set(void *buffer, size_t size) {
	int8_t *value;
	int i;
	if (size != 16*sizeof(uint8_t))
	    return FAIL;
	value = (int8_t *)buffer;
	for(i=0;i<16;i++) xbowFacInfo4[i] = value[i];
	return SUCCESS;
  }
  
  event result_t HardwareId.readDone(uint8_t *id, result_t success)
  {	
    return SUCCESS;
  } 
  
}

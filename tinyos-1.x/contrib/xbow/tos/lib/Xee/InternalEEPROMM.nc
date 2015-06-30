// Methods to read parameters from internal EEPROM
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
#define InternalEEPROMedit 1
//
// Modification History:
//  22Jan04 MJNewman 1: Created.

includes EEPROM;

module InternalEEPROMM {
    provides interface StdControl;
    provides interface WriteData;
    provides interface ReadData;
}

implementation
{

// To turn on debugging printouts uncomment the next line.
//#define SO_DEBUG 1
#include "SOdebug.h"

#include <avr/eeprom.h>

    command result_t StdControl.init()
    {
	SODbg(DBG_TEMP,"InternalEEPROM.init\n");
	return SUCCESS;
    }

    command result_t StdControl.start()
    {
	SODbg(DBG_TEMP,"InternalEEPROM.start\n");
	return SUCCESS;
    }

    command result_t StdControl.stop()
    {
	return SUCCESS;
    }


    static uint8_t *pReadBuffer;
    static uint16_t readNumBytesRead;

    task void sendReadDone() {
	signal ReadData.readDone(pReadBuffer,readNumBytesRead,SUCCESS);
    }

    command result_t ReadData.read(uint32_t offset, uint8_t *buffer, uint32_t numBytesRead) {
	uint16_t i;
	SODbg(DBG_TEMP,"InternalEEPROM.ReadData.read %ld for %d bytes\n",offset,(int)numBytesRead);
	pReadBuffer = buffer;
	readNumBytesRead = (uint16_t)numBytesRead;	// limited to 64K by address space
	for (i = 0;i < readNumBytesRead;i += 1) {
	    buffer[i] = eeprom_read_byte((uint8_t *)((uint16_t)offset + i));
	};
	post sendReadDone();
	return SUCCESS;
    }

    static uint8_t *pWriteBuffer;
    static uint16_t writeNumBytesWrite;

    task void sendWriteDone() {
	signal WriteData.writeDone(pWriteBuffer,writeNumBytesWrite,SUCCESS);
    }

    command result_t WriteData.write(uint32_t offset, uint8_t *buffer, uint32_t numBytesWrite) {
	uint16_t i;
	SODbg(DBG_TEMP,"InternalEEPROM.WriteData.write at %ld for %d bytes\n",offset,(int)numBytesWrite);
	pWriteBuffer = buffer;
	writeNumBytesWrite = (uint16_t)numBytesWrite;	// limited to 64K by address space
	for (i = 0;i < writeNumBytesWrite;i += 1) {
	    eeprom_write_byte((uint8_t *)((uint16_t)offset + i),buffer[i]);
	};
	post sendWriteDone();
	return SUCCESS;
    }

    default event result_t WriteData.writeDone(uint8_t *data, uint32_t numBytesWrite, result_t success) {
	return SUCCESS;
    }

    default event result_t ReadData.readDone(uint8_t *buffer, uint32_t numBytesRead, result_t success) {
	return SUCCESS;
    }

}

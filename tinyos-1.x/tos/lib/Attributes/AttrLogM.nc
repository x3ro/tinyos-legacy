// $Id: AttrLogM.nc,v 1.5 2003/10/07 21:46:16 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* 
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     10/22/2002
 *
 */

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */


includes EEPROM;

// component to expose data logged in EEPROM by the logattr command as
// an attribute
module AttrLogM
{
	provides interface StdControl;
	uses 
	{
		interface AttrRegister;
		interface LoggerRead;
		interface LoggerWrite;
	}
}
implementation
{
	uint16_t *result;	// pointer to result buffer for pending getAttr
	// double buffers
	uint8_t line1[TOS_EEPROM_LINE_SIZE];
	uint8_t line2[TOS_EEPROM_LINE_SIZE];
	uint8_t *linebuf;	// pointer to current buffer to read values from
	bool readPending;	// read from EEPROM pending
	bool attrInProgress; // getAttr has been called but not all stored
						 // samples have been fetched yet
	bool readingFirstLine; // reading first line of data
	short lineOffset;	// offset into linebuf for current value to be returned
	uint16_t nsamples;	// total number of samples stored in EEPROM
	uint16_t sampleNo;	// current sample number
	char attrName[MAX_ATTR_NAME_LEN + 1];	// name of the attribute that was logged
	uint32_t samplePeriod;	// sample period when the samples are collected

	command result_t StdControl.init()
	{
		if (call AttrRegister.registerAttr("attrlog", UINT16, 2) != SUCCESS)
			return FAIL;
		readPending = FALSE;
		readingFirstLine = FALSE;
		attrInProgress = FALSE;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	event result_t AttrRegister.startAttr()
	{
		return call AttrRegister.startAttrDone();
	}

	event result_t AttrRegister.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		if (!attrInProgress)
		{
			// if this is first time, initialize
			attrInProgress = TRUE;
			readingFirstLine = FALSE;
			nsamples = 0;
			sampleNo = 0;
			call LoggerRead.resetPointer();
			// read the first line of EEPROM for the metadata
			readPending = TRUE;
			if (call LoggerRead.readNext(line2) == FAIL)
			{
				readPending = FALSE;
				attrInProgress = FALSE;
				return FAIL;
			}
			result = (uint16_t*)resultBuf;
			// return with result pending
			*errorNo = SCHEMA_RESULT_PENDING;
			dbg(DBG_USR2, "attrlog in progress.\n");
			return SUCCESS;
		}
		if (lineOffset < TOS_EEPROM_LINE_SIZE)
		{
			// there are more data to be read from the current buffer
			*(uint16_t*)resultBuf = *(uint16_t*)(linebuf + lineOffset);
			dbg(DBG_USR2, "sample = %d, attrlog = %d\n", sampleNo, *(uint16_t*)resultBuf);
			lineOffset += sizeof(uint16_t);
			*errorNo = SCHEMA_RESULT_READY;
			sampleNo++;
			if (sampleNo >= nsamples)
				// we are done with all the stored values
				attrInProgress = FALSE;
			else if (lineOffset >= TOS_EEPROM_LINE_SIZE && !readPending)
			{
				// time to switch buffer and read new data
				uint8_t *otherbuf = linebuf;
				if (linebuf == line1)
					linebuf = line2;
				else 
					linebuf = line1;
				lineOffset = 0;
					
				readPending = TRUE;
				if (call LoggerRead.readNext(otherbuf) == FAIL)
				{
					readPending = FALSE;
					attrInProgress = FALSE;
				}
			}
		}
		else if (!readPending)
		{
			// buffer just filled, now switch to it
			uint8_t *otherbuf = linebuf;
			if (linebuf == line1)
				linebuf = line2;
			else 
				linebuf = line1;
			lineOffset = 0;
				
			// fill the other buffer
			readPending = TRUE;
			if (call LoggerRead.readNext(otherbuf) == FAIL)
			{
				readPending = FALSE;
				attrInProgress = FALSE;
			}
			*(uint16_t*)resultBuf = *(uint16_t*)(linebuf + lineOffset);
			dbg(DBG_USR2, "sample = %d, attrlog = %d\n", sampleNo, *(uint16_t*)resultBuf);
			lineOffset += sizeof(uint16_t);
			*errorNo = SCHEMA_RESULT_READY;
			sampleNo++;
			if (sampleNo >= nsamples)
				// done with all stored data
				attrInProgress = FALSE;
			return SUCCESS;
		}
		else
		{
			// done with one buffer but the other buffer is not ready
			*(uint16_t*)resultBuf = 0;
			*errorNo = SCHEMA_ERROR;
		}
		return SUCCESS;
	}

	event result_t LoggerRead.readDone(uint8_t *buffer, result_t success)
	{
		uint8_t *ptr;
		readPending = FALSE;
		if (success == FAIL)
			return FAIL;
		if (readingFirstLine)
		{
			*result = *(uint16_t*)linebuf;
			dbg(DBG_USR2, "sample = %d, attrlog = %d\n", sampleNo, *result);
			call AttrRegister.getAttrDone("attrlog", (char*)result, SCHEMA_RESULT_READY);
			sampleNo++;
			lineOffset = sizeof(uint16_t);
			readingFirstLine = FALSE;

			readPending = TRUE;
			if (nsamples > TOS_EEPROM_LINE_SIZE/sizeof(uint16_t))
			{
				// now fill the other buffer
				if (call LoggerRead.readNext(line2) == FAIL)
				{
					readPending = FALSE;
					memset(line2, 0, TOS_EEPROM_LINE_SIZE);
				}
			}
		}
		if (nsamples == 0)
		{
			uint16_t magicNo;
			// read the first line for attr name, sample period and
			// number of samples
			magicNo = *(uint16_t*)buffer;
			if (magicNo != 0xABCD)
			{
				// if the magic number doesn't match, it means that
				// attribute values have not been properly logged
				attrInProgress = FALSE;
				*result = 0;
				call AttrRegister.getAttrDone("attrlog", (char*)result, SCHEMA_ERROR);
				return FAIL;
			}
			ptr = buffer + sizeof(uint16_t);
			strcpy(attrName, ptr);
			ptr += 8;
			samplePeriod = *(uint32_t*)ptr;
			ptr += sizeof(uint32_t);
			nsamples = *(uint16_t*)ptr;
			dbg(DBG_USR2, "attr name = %s, sample period = %d, nsamples = %d\n", attrName, samplePeriod, nsamples);
			linebuf = line1;
			// now read the real data
			readPending = TRUE;
			readingFirstLine = TRUE;
			if (call LoggerRead.readNext(linebuf) == FAIL)
			{
				attrInProgress = FALSE;
				readingFirstLine = FALSE;
				*result = 0;
				call AttrRegister.getAttrDone("attrlog", (char*)result, SCHEMA_ERROR);
				return FAIL;
			}
		}
		return SUCCESS;
	}

	event result_t AttrRegister.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t LoggerWrite.writeDone(result_t success)
	{
		return success;
	}
}

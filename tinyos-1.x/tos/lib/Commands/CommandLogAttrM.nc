// $Id: CommandLogAttrM.nc,v 1.5 2003/10/07 21:46:17 idgay Exp $

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
 * Date:     10/18/2002
 *
 */

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */


includes EEPROM;

// register command logattr that logs readings of an attribute at
// certain sample rate to EEPROM
// signature: VOID logattr(STRING attrname, UINT32 sample_period, UINT16 nsamples)

module CommandLogAttrM
{
	provides interface StdControl;
	uses
	{
		interface CommandRegister;
		interface AttrUse;
		interface Timer;
		interface LoggerWrite;
		interface LoggerRead;
		interface Leds;
	}
}
implementation
{
	// double buffer
	uint8_t line1[TOS_EEPROM_LINE_SIZE];
	uint8_t line2[TOS_EEPROM_LINE_SIZE];
	uint8_t *linebuf;	// pointer to current buffer
	short lineOffset;	// offset in current buffer to the next value
	bool writePending;	// a write to EEPROM is pending
	bool logattrRunning; // an attribute logging session is in progress
	bool writingLastLine; // writing out the last line to EEPROM
	uint32_t sampleNo;
	uint32_t samplePeriod; // sample period in milliseconds
	uint16_t nsamples;	// number of samples to be logged
	uint16_t attrval;
	AttrDescPtr attrDesc;  // descriptor for the attribute to be logged

	command result_t StdControl.init()
	{
		ParamList paramList;
		setParamList(&paramList, 3, STRING, UINT32, UINT16);
		if (call CommandRegister.registerCommand("logattr", VOID, 0, &paramList) != SUCCESS)
			return FAIL;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		logattrRunning = FALSE;
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		logattrRunning = FALSE;
		call Timer.stop();
		return SUCCESS;
	}

	event result_t CommandRegister.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params)
	{
		char *name;
		uint8_t *ptr;
		writingLastLine = FALSE;
		*errorNo = SCHEMA_ERROR;
		if (logattrRunning)
			return FAIL;
		if (params->numParams != 3)
			return FAIL;
		name = params->paramDataPtr[0];
		samplePeriod = *(uint32_t*)params->paramDataPtr[1];
		nsamples = *(uint16_t*)params->paramDataPtr[2];
		attrDesc = call AttrUse.getAttr(name);
		if (attrDesc == NULL)
			return FAIL;	// attribute does not exist
		sampleNo = 0;
		// XXX only supports UINT16 type for now 
		if (attrDesc->type != UINT16)
			return FAIL;
		// log the attribute name, sample period and number of samples
		// to the first line of EEPROM
		ptr = line2;
		*(uint16_t*)ptr = 0xABCD; // write magic number
		ptr += sizeof(uint16_t);
		strncpy(ptr, name, 7);
		ptr += 8;
		*(uint32_t*)ptr = samplePeriod;
		ptr += sizeof(uint32_t);
		*(uint16_t*)ptr = nsamples;
		call LoggerWrite.resetPointer();
		writePending = TRUE;
		if (call LoggerWrite.append(line2) == FAIL)
		{
			writePending = FALSE;
			return FAIL;
		}
		linebuf = line1;
		lineOffset = 0;
		logattrRunning = TRUE;
		if (call Timer.start(TIMER_REPEAT, samplePeriod) == FAIL)
		{
			logattrRunning = FALSE;
			return FAIL;
		}
		dbg(DBG_USR2, "logattr started.\n");
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t LoggerWrite.writeDone(result_t success)
	{
		writePending = FALSE;
		call Leds.greenToggle();
		dbg(DBG_USR2, "LoggerWrite done.\n");
		if (writingLastLine)
		{
			call CommandRegister.commandDone("logattr", NULL, SCHEMA_RESULT_READY);
			dbg(DBG_USR2, "logattr finished.\n");
			writingLastLine = FALSE;
			logattrRunning = FALSE;
		}
		return success;
	}

	event result_t Timer.fired()
	{
	  
		SchemaErrorNo errorNo;
		sampleNo++;
		if (call AttrUse.getAttrValue(attrDesc->name, (char*)&attrval, &errorNo) == FAIL)
			return FAIL;
		if (errorNo == SCHEMA_RESULT_READY)
			// simulate split-phase attributes
			signal AttrUse.getAttrDone(attrDesc->name, (char*)&attrval, errorNo);
		if (sampleNo >= nsamples)
		{
			// done with command
			call Timer.stop();
			// writing out the last line
			writingLastLine = TRUE;
		}
		return SUCCESS;
	}

	event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo)
	{
		if (!logattrRunning || strcasecmp(name, attrDesc->name) != 0)
			return SUCCESS;
		call Leds.yellowToggle();
		if (lineOffset == TOS_EEPROM_LINE_SIZE)
		{
			// current buffer is full
			if (!writePending)
			{
				uint8_t *buf;
				// switch buffer
				buf = linebuf;
				if (linebuf == line1)
					linebuf = line2;
				else
					linebuf = line1;
				lineOffset = 0;
			dbg(DBG_USR2, "linebuf 0x%x = %d %d\n", buf, *(uint16_t*)buf, *(uint16_t*)(buf + 2));
				// flush current buffer
				writePending = TRUE;
				if (call LoggerWrite.append(buf) == FAIL)
					writePending = FALSE;
				dbg(DBG_USR2, "writing EEPROM.\n");
			}
			else
				return FAIL;
		}
		dbg(DBG_USR2, "sample = %d, logging value %d to buffer 0x%x offset %d\n", sampleNo, *(uint16_t*)resultBuf, linebuf, lineOffset);
		memcpy(linebuf + lineOffset, resultBuf, sizeof(uint16_t));
		lineOffset += sizeof(uint16_t);
		if (lineOffset == TOS_EEPROM_LINE_SIZE || writingLastLine)
		{
			uint8_t *buf;
			// current buffer full
			if (writePending)
				// if EEPROM is busy, wait until next time
				return SUCCESS;
			// switch buffer
			buf = linebuf;
			if (linebuf == line1)
				linebuf = line2;
			else
				linebuf = line1;
			dbg(DBG_USR2, "buffer switched.\n");
			lineOffset = 0;
			dbg(DBG_USR2, "linebuf 0x%x = %d %d\n", buf, *(uint16_t*)buf, *(uint16_t*)(buf + 2));
			// try to flush the buffer
			writePending = TRUE;
			if (call LoggerWrite.append(buf) == FAIL)
				writePending = FALSE;
			dbg(DBG_USR2, "writing EEPROM.\n");
		}
		return SUCCESS;
	}
	event result_t LoggerRead.readDone(uint8_t *buffer, result_t success)
	{
		return success;
	}
}

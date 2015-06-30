// $Id: Attr.nc,v 1.3 2004/03/09 18:30:07 idgay Exp $

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
 * Date:     6/28/2002
 *
 */

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */


module Attr
{
	provides
	{
		interface StdControl;
		interface AttrRegister as Attr[uint8_t id];
		interface AttrRegisterConst as ConstAttr;
		interface AttrUse;
	}
}
implementation 
{
	AttrDescs		attrDescs;
	bool			addAttrPending;
	uint32_t		constAttrs[MAX_CONST_ATTRS];
	int				nConstAttrs;

	command result_t StdControl.init()
	{
		attrDescs.numAttrs = 0;
		addAttrPending = FALSE;
		nConstAttrs = 0;
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

	/* Add the specified attribute to the schema.  Copies the attribute
	   into the schema (does not store the passed in reference.)

	   If the attribute already exists, replaces it with the new
	   descriptor.
	*/
	command result_t Attr.registerAttr[uint8_t id](char *attrName, TOSType type, uint8_t attrLen)
	{
		short attrIdx;
		AttrDescPtr attrDesc;
		bool attrExists = FALSE;
		short len;
		if (addAttrPending)
			return FAIL;
		else
			addAttrPending = TRUE;
		// XXX should probably turn this into a task
		// if attribute already exists, replace it with new attr definition
		for (attrIdx = 0; attrIdx < attrDescs.numAttrs; attrIdx++)
			if (strcasecmp(attrDescs.attrDesc[(int)attrIdx].name, attrName) == 0)
			{
				attrExists = TRUE;
				break;
			}
		if (!attrExists)
		{
			if (attrDescs.numAttrs < MAX_ATTRS)
				attrDescs.numAttrs++;
			else
			{
				addAttrPending = FALSE;
				return FAIL;
			}
		}
		attrDesc = &attrDescs.attrDesc[(int)attrIdx];
		attrDesc->type = type;
		attrDesc->idx = attrIdx;
		len = sizeOf(type);
		if (len < 0)
			// for variable length types
			attrDesc->nbytes = attrLen;
		else
			attrDesc->nbytes = (uint8_t)len;
		attrDesc->id = id;
		attrDesc->constIdx = -1;
		attrDesc->name = attrName;
		addAttrPending = FALSE;
		return SUCCESS;
	}
 
	/* Return a pointer to the  descriptor for the specified command,
	   or NULL if the command does not exist
	*/
	command AttrDescPtr AttrUse.getAttr(char *name)
	{
		// read numAttrs to local variable to reduce the window of race condition, XXX
		short numAttrs = attrDescs.numAttrs;
		short i;
		for (i = 0; i < numAttrs; i++)
		{
			if (strcasecmp(attrDescs.attrDesc[i].name, name) == 0)
				return &attrDescs.attrDesc[i];
		}
		return NULL;
	}

	/* Return a pointer to the descriptor for the specified command index,
	   or NULL if the index is not valid
	*/
	command AttrDescPtr AttrUse.getAttrById(uint8_t attrIdx) 
	{
		short numAttrs = attrDescs.numAttrs;
		if (attrIdx >= numAttrs)
			return NULL;
		return &attrDescs.attrDesc[(short)attrIdx];
	}

	command AttrDescsPtr AttrUse.getAttrs()
	{
		return &attrDescs;
	}

	command uint8_t AttrUse.numAttrs()
	{
		return attrDescs.numAttrs;
	}

	command result_t AttrUse.getAttrValue(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		AttrDescPtr attrDesc = call AttrUse.getAttr(name);
		if (attrDesc == NULL)
			return FAIL;
		if (attrDesc->constIdx >= 0)
		{
			memcpy(resultBuf, (char*)&constAttrs[(short)attrDesc->constIdx],
					attrDesc->nbytes);
			*errorNo = SCHEMA_RESULT_READY;
		}
		else if (signal Attr.getAttr[attrDesc->id](name, resultBuf, errorNo) != SUCCESS)
			return FAIL;
		if (*errorNo == SCHEMA_ERROR)
			return FAIL;
		return SUCCESS;
	}

	command result_t AttrUse.startAttr(uint8_t id)
	{
		if (id >= attrDescs.numAttrs)
			return FAIL;
		if (signal Attr.startAttr[id]() != SUCCESS)
			return FAIL;
		return SUCCESS;
	}

	command result_t AttrUse.setAttrValue(char *name, char *attrVal)
	{
		AttrDescPtr attrDesc = call AttrUse.getAttr(name);
		if (attrDesc == NULL)
			return FAIL;
		if (attrDesc->constIdx >= 0)
		{
			if (attrVal == NULL)
				return FAIL;
			memcpy((char*)&constAttrs[(short)attrDesc->constIdx], attrVal,
					attrDesc->nbytes);
		}
		else if (signal Attr.setAttr[attrDesc->id](name, attrVal) != SUCCESS)
			return FAIL;
		return SUCCESS;
	}

	command result_t ConstAttr.registerAttr(char *name, TOSType attrType, char *attrVal)
	{
		short attrIdx;
		short len;
		AttrDescPtr attrDesc;
		bool attrExists = FALSE;
		if (addAttrPending ||
			lengthOf(attrType, attrVal) > MAX_CONST_LEN ||
			nConstAttrs >= MAX_CONST_ATTRS)
			return FAIL;
		else
			addAttrPending = TRUE;
		// XXX should probably turn this into a task
		// if attribute already exists, replace it with new attr definition
		for (attrIdx = 0; attrIdx < attrDescs.numAttrs; attrIdx++)
			if (strcasecmp(attrDescs.attrDesc[(int)attrIdx].name, name) == 0)
			{
				attrExists = TRUE;
				break;
			}
		if (!attrExists)
		{
			if (attrDescs.numAttrs < MAX_ATTRS)
				attrDescs.numAttrs++;
			else
			{
				addAttrPending = FALSE;
				return FAIL;
			}
		}
		attrDesc = &attrDescs.attrDesc[(int)attrIdx];
		attrDesc->type = attrType;
		attrDesc->idx = attrIdx;
		len = sizeOf(attrType);
		if (len < 0)
			// for variable length types
			attrDesc->nbytes = lengthOf(attrType, attrVal);
		else
			attrDesc->nbytes = len;
		attrDesc->id = 0;
		if (!attrExists || attrDesc->constIdx < 0)
			attrDesc->constIdx = nConstAttrs++;
		memcpy((char*)&constAttrs[(short)attrDesc->constIdx], attrVal, attrDesc->nbytes);
		attrDesc->name = name;
		addAttrPending = FALSE;
		return SUCCESS;
	}

	command result_t Attr.getAttrDone[uint8_t id](char *name, char *resultBuf, SchemaErrorNo errorNo)
	{
		signal AttrUse.getAttrDone(name, resultBuf, errorNo);
		return SUCCESS;
	}

	command result_t Attr.startAttrDone[uint8_t id]()
	{
		signal AttrUse.startAttrDone(id);
		return SUCCESS;
	}

	default event result_t Attr.getAttr[uint8_t id](char *name, char *resultBuf, SchemaErrorNo *errorNo) {
	  return SUCCESS;
	}

	default event result_t Attr.setAttr[uint8_t id](char *name, char *attrVal) {
	  return SUCCESS;
	}

	default event result_t Attr.startAttr[uint8_t id]() {
	  return SUCCESS;
	}
}

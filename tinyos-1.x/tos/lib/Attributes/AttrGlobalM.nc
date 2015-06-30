// $Id: AttrGlobalM.nc,v 1.3 2003/10/07 21:46:16 idgay Exp $

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
 * Date:     7/1/2002
 *
 */

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */

includes AM;

// component to expose certain global variables as attributes
module AttrGlobalM
{
	provides interface StdControl;
	uses
	{
		interface AttrRegister as NodeIdAttr;
		interface AttrRegister as GroupAttr;
	}
}
implementation
{
	command result_t StdControl.init()
	{
		if (call NodeIdAttr.registerAttr("nodeid", UINT16, 2) != SUCCESS)
			return FAIL;
		if (call GroupAttr.registerAttr("group", UINT8, 1) != SUCCESS)
			return FAIL;
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

	event result_t NodeIdAttr.startAttr()
	{
		return call NodeIdAttr.startAttrDone();
	}

	event result_t NodeIdAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		*errorNo = SCHEMA_RESULT_READY;
		*(uint16_t*)resultBuf = TOS_LOCAL_ADDRESS;
		return SUCCESS;
	}

	event result_t NodeIdAttr.setAttr(char *name, char *resultBuf)
	{
		TOS_LOCAL_ADDRESS = *(uint16_t*)resultBuf;
		return SUCCESS;
	}

	event result_t GroupAttr.startAttr()
	{
		return call GroupAttr.startAttrDone();
	}

	event result_t GroupAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		*errorNo = SCHEMA_RESULT_READY;
		*(uint8_t*)resultBuf = TOS_AM_GROUP;
		return SUCCESS;
	}

	event result_t GroupAttr.setAttr(char *name, char *resultBuf)
	{
		TOS_AM_GROUP = *(uint8_t*)resultBuf;
		return SUCCESS;
	}
}

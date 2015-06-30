// $Id: AttrTimeM.nc,v 1.1.1.1 2007/11/05 19:09:06 jpolastre Exp $

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
 * Date:     3/24/2003
 *
 */
// component to expose logical time as attributes


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module AttrTimeM
{
	provides interface StdControl;
	uses 
	{
		interface Time;
		interface AttrRegister as TimeLowAttr;
		interface AttrRegister as TimeHighAttr;
	}
}
implementation
{
	command result_t StdControl.init()
	{
		if (call TimeLowAttr.registerAttr("timelo", UINT32, 4) != SUCCESS)
			return FAIL;
		if (call TimeHighAttr.registerAttr("timehi", UINT32, 4) != SUCCESS)
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

	event result_t TimeLowAttr.startAttr()
	{
		return call TimeLowAttr.startAttrDone();
	}

	event result_t TimeLowAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		*(uint32_t*)resultBuf = call Time.getLow32();
		*errorNo = SCHEMA_RESULT_READY;
		return SUCCESS;
	}

	event result_t TimeLowAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t TimeHighAttr.startAttr()
	{
		return call TimeHighAttr.startAttrDone();
	}

	event result_t TimeHighAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		*(uint32_t*)resultBuf = call Time.getHigh32();
		*errorNo = SCHEMA_RESULT_READY;
		return SUCCESS;
	}

	event result_t TimeHighAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}

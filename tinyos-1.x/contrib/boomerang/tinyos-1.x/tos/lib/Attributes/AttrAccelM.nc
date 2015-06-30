// $Id: AttrAccelM.nc,v 1.1.1.1 2007/11/05 19:09:04 jpolastre Exp $
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
 * Date:     8/6/2002
 *
 */
// component to expose Accelerometer readings as an attribute


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module AttrAccelM
{
	provides interface StdControl;
	uses 
	{
		interface ADC as AccelX;
		interface ADC as AccelY;
		interface StdControl as AccelControl;
		interface AttrRegister as AttrAccelX;
		interface AttrRegister as AttrAccelY;
	}
}
implementation
{
	char *resultX;
	char *attrNameX;
	char *resultY;
	char *attrNameY;
	task void getAccelXDone();
	task void getAccelYDone();
	
	command result_t StdControl.init()
	{
		if (call AttrAccelX.registerAttr("accel_x", UINT16, 2) != SUCCESS)
			return FAIL;
		if (call AttrAccelY.registerAttr("accel_y", UINT16, 2) != SUCCESS)
			return FAIL;
		return call AccelControl.init();
	}

	command result_t StdControl.start()
	{
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return call AccelControl.stop();
	}

	event result_t AttrAccelX.startAttr()
	{
		result_t res = call AccelControl.start();
		call AttrAccelX.startAttrDone();
		return res;
	}

	event result_t AttrAccelX.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{

	  atomic {
	    resultX = resultBuf;
	    attrNameX = name;
	  }
	  if (call AccelX.getData() != SUCCESS)
	    return FAIL;
	  *errorNo = SCHEMA_RESULT_PENDING;
	  return SUCCESS;
	}

	event result_t AttrAccelX.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	async event result_t AccelX.dataReady(uint16_t data)
	{
		*(uint16_t*)resultX = data;
		post getAccelXDone();
		return SUCCESS;
	}

	event result_t AttrAccelY.startAttr()
	{
		result_t res = call AccelControl.start();
		call AttrAccelY.startAttrDone();
		return res;
	}

	event result_t AttrAccelY.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
	  atomic {
		resultY = resultBuf;
		attrNameY = name;
	  }
		if (call AccelY.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t AttrAccelY.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	async event result_t AccelY.dataReady(uint16_t data)
	  {
		*(uint16_t*)resultY = data;
		post getAccelYDone();
		return SUCCESS;
	}

	task void getAccelYDone() {
	  call AttrAccelY.getAttrDone(attrNameY, resultY, SCHEMA_RESULT_READY);
	}

	task void getAccelXDone() {
	  call AttrAccelX.getAttrDone(attrNameX, resultX, SCHEMA_RESULT_READY);
	}
}

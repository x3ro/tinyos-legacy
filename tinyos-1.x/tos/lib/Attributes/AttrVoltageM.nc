// $Id: AttrVoltageM.nc,v 1.7 2004/07/14 16:40:35 idgay Exp $
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
// component to expose Temperature sensor reading as an attribute


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module AttrVoltageM
{
	provides interface StdControl;
	uses 
	{
		interface StdControl as SubControl;
		interface ADC;
		interface AttrRegister;
	}
}
implementation
{
	char *result;
	char *attrName;
	task void getDoneTask();

	command result_t StdControl.init()
	{
	  if (call AttrRegister.registerAttr("voltage", UINT16, 2) != SUCCESS)
			return FAIL;

#ifdef PLATFORM_MICA2DOT
	  //need to disable this guy initially
	  TOSH_MAKE_PW7_OUTPUT();
	  TOSH_SET_PW7_PIN();
#endif

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
	  atomic {
		result = resultBuf;
		attrName = name;
	  }
#ifdef PLATFORM_MICA2DOT
		TOSH_CLR_PW7_PIN();
		TOSH_MAKE_PW7_OUTPUT();
		TOSH_CLR_PW6_PIN();
		TOSH_MAKE_PW6_INPUT();
#endif
#ifdef PLATFORM_MICA2
	TOSH_MAKE_BAT_MON_OUTPUT();
	TOSH_SET_BAT_MON_PIN();
#endif
		if (call ADC.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	async event result_t ADC.dataReady(uint16_t data)
	{
		*(uint16_t*)result = data;
#ifdef PLATFORM_MICA2DOT
		TOSH_SET_PW7_PIN();
		TOSH_MAKE_PW7_INPUT();
#endif
		post getDoneTask();
		return SUCCESS;
	}

	task void getDoneTask() {
	  call AttrRegister.getAttrDone(attrName, result, SCHEMA_RESULT_READY);
	}

	event result_t AttrRegister.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}

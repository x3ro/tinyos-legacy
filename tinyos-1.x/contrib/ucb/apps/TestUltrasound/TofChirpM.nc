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
 * Authors:  Kamin Whitehouse
 *           Intel Research Berkeley Lab
 * 	     UC Berkeley
 * Date:     8/20/2002
 *
 */

includes TofRanging;
includes SchemaType;


// register command to tell mote to chirp for TOF ranging
// TofChp(uint8_t numChirps, uint16_t freq, uint8_t receiveAction): chirp numChirps times with frequency freq and the receiver should do action receiveAction

module TofChirpM
{
	provides interface StdControl;
	uses
	{
		interface StdControl as TimerControl;
		interface StdControl as CommControl;
		interface StdControl as CommandControl;
		interface StdControl as AttrControl;
		interface CommandRegister as TofChirp;
		interface CommandUse as Commands;
		interface AttrRegister as TofChirpLength;
		interface AttrRegister as USoundTxrCalibration;
		interface AttrUse as Attributes;
		interface Timer as Timer1;
		interface SendMsg as Chirp;
		interface ReceiveMsg as ChirpCommand;
		interface TofChirpControl;
		interface Leds;
	}
}
implementation
{
	TOS_Msg tosMsg;
	struct TofChirpMsg *chirpMsg;
	struct CalibrationCoefficients *sounderCoefficients;
	uint16_t chirpDestination;
	uint8_t maxNumChirps;
	uint8_t currentNumChirps;

	uint8_t chirpLength;

	result_t tofChirp();

	command result_t StdControl.init()
	{
		ParamList paramList;
		call TimerControl.init();
		call CommControl.init();
		call CommandControl.init();
		call AttrControl.init();
		paramList.numParams=4;
		paramList.params[0]=INT16;
		paramList.params[1]=INT8;
		paramList.params[2]=INT16;
		paramList.params[3]=INT16;
		memset((char*)&tosMsg, 0, sizeof(tosMsg));
		tosMsg.length=LEN_TOFCHIRPMSG;
		chirpMsg=(struct TofChirpMsg*)&tosMsg.data;
		sounderCoefficients = (struct CalibrationCoefficients*)&chirpMsg->sounderOffset;
		sounderCoefficients->a=0;
		sounderCoefficients->b=1;
		chirpMsg->receiverAction=TOS_UART_ADDR;
		chirpDestination=TOS_BCAST_ADDR;
		maxNumChirps=0;
		currentNumChirps=0;
		chirpLength=36;
		if (call TofChirp.registerCommand("TofChp", VOID, 0, &paramList) != SUCCESS)
			return FAIL;
		if (call TofChirpLength.registerAttr("TofChpLen", UINT8, 1) != SUCCESS)
			return FAIL;
		if (call USoundTxrCalibration.registerAttr("TofSndCfs", UINT8, 1) != SUCCESS)
			return FAIL;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call AttrControl.start();
		call TimerControl.start();
		call CommandControl.start();
		call CommControl.start();
//		call Timer1.start(TIMER_REPEAT,1000);
		return SUCCESS;
	}

	command result_t StdControl.stop()
        {
		return(call Timer1.stop());
	}

	event result_t TofChirp.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params)
	{
		currentNumChirps = 0;
		chirpDestination = *(uint16_t*)(params->paramDataPtr[0]);
		maxNumChirps = *(uint8_t*)(params->paramDataPtr[1]);
		chirpMsg->receiverAction = *(uint16_t*)(params->paramDataPtr[3]);
		return (call Timer1.start(TIMER_REPEAT, *(uint16_t*)(params->paramDataPtr[2])));
	}

	event TOS_MsgPtr ChirpCommand.receive(TOS_MsgPtr m){
		result_t boo;
		char resultBfr;
		SchemaErrorNo errorNo;
		boo= call Commands.invokeMsg(m, &resultBfr, &errorNo);
		if(boo==FAIL)
			call Leds.redToggle();
		return m;//should return a new buffer?
	}

	event result_t Commands.commandDone(char *commandName, char *resultBuf, SchemaErrorNo errorNo){
		return SUCCESS;
	}

	event result_t Timer1.fired()
	{
		if(currentNumChirps>=maxNumChirps){
			return(call Timer1.stop());
		}
		else{
			currentNumChirps+=1;
			return(tofChirp());
		}
	}

	event result_t TofChirpLength.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		*(uint8_t*)resultBuf = chirpLength;
		*errorNo = SCHEMA_RESULT_READY;
		return SUCCESS;
	}

	event result_t TofChirpLength.setAttr(char *name, char *attrVal)
	{
		chirpLength = *attrVal;
		return SUCCESS;
	}

	event result_t USoundTxrCalibration.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		((struct CalibrationCoefficients*)resultBuf)->a = sounderCoefficients->a;
		((struct CalibrationCoefficients*)resultBuf)->b = sounderCoefficients->b;
		*errorNo = SCHEMA_RESULT_READY;
		return SUCCESS;
	}

	event result_t USoundTxrCalibration.setAttr(char *name, char *attrVal)
	{
		sounderCoefficients->a = ((struct CalibrationCoefficients*)attrVal)->a;
		sounderCoefficients->b = ((struct CalibrationCoefficients*)attrVal)->b;
		return SUCCESS;
	}

	result_t tofChirp()
	{
//		SchemaErrorNo errorNo;

		call Leds.redToggle();
//		call Attributes.getAttrValue("nodeid", (char*)&chirpMsg->transmitterId, &errorNo);
		chirpMsg->transmitterId=TOS_LOCAL_ADDRESS;
		call TofChirpControl.enable(chirpLength);
		call Chirp.send(chirpDestination, LEN_TOFCHIRPMSG, &tosMsg);
	
		return SUCCESS;
	}




	event result_t Chirp.sendDone(TOS_MsgPtr msg, result_t success) 
	{
		return SUCCESS;
	}
  
	event result_t Attributes.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo)
	{
		return SUCCESS;
	}
}







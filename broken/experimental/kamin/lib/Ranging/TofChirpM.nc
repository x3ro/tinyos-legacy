/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redstribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
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
		interface AttrRegister as SounderCalibration;
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
		if (call SounderCalibration.registerAttr("TofSndCfs", UINT8, 1) != SUCCESS)
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

	event result_t SounderCalibration.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		((struct CalibrationCoefficients*)resultBuf)->a = sounderCoefficients->a;
		((struct CalibrationCoefficients*)resultBuf)->b = sounderCoefficients->b;
		*errorNo = SCHEMA_RESULT_READY;
		return SUCCESS;
	}

	event result_t SounderCalibration.setAttr(char *name, char *attrVal)
	{
		sounderCoefficients->a = ((struct CalibrationCoefficients*)attrVal)->a;
		sounderCoefficients->b = ((struct CalibrationCoefficients*)attrVal)->b;
		return SUCCESS;
	}

	result_t tofChirp()
	{
		SchemaErrorNo errorNo;

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





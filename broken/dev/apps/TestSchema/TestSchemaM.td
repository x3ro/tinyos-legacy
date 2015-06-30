module TestSchemaM
{
	provides interface StdControl;
	uses
	{
		interface Clock;
		interface CommandUse;
		interface AttrUse;
		interface SendMsg;
		interface StdControl as CommControl;
	}
}
implementation
{
	uint16_t attr;
	SchemaErrorNo errorNo;
	TOS_Msg msg;
	bool pending;
	bool sounderOn;
	command result_t StdControl.init()
	{
		call CommControl.init();
		memset((char*)&msg, 0, sizeof(msg));
		pending = FALSE;
		sounderOn = FALSE;
		return SUCCESS;
	}
	command result_t StdControl.start()
	{
		return call Clock.setRate(TOS_I1PS, TOS_S1PS);
	}
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}
	event result_t Clock.fire()
	{
		if (pending)
			return SUCCESS;
		else
			pending = TRUE;
		call AttrUse.getAttrValue("nodeid", (char*)&attr, &errorNo);
		/*
		if (attr == 13)
		{
				ParamVals params;
				uint8_t arg = 2;
				params.numParams = 1;
				params.paramDataPtr[0] = (char*)&arg;
				call CommandUse.invoke("SetLedY", NULL, &errorNo, &params);
		}
		*/
		*(uint16_t*)(&msg.data[0]) = attr;
		return call AttrUse.getAttrValue("accel_x", (char*)&attr, &errorNo);
	}
	event result_t AttrUse.getAttrDone(char *name, char *resultBuf, SchemaErrorNo errNo)
	{
		if (strcmp(name, "accel_x") == 0)
		{
			*(uint16_t*)(&msg.data[2]) = *(uint16_t*)resultBuf;
			return call AttrUse.getAttrValue("accel_y", (char*)&attr, &errorNo);
		}
		*(uint16_t*)(&msg.data[4]) = *(uint16_t*)resultBuf;
		/*
		if (attr > 0)
		{
			ParamVals params;
			uint8_t arg = 2;
			params.numParams = 1;
			params.paramDataPtr[0] = (char*)&arg;
			call CommandUse.invoke("SetLedG", NULL, &errorNo, &params);
		}
		*/
		msg.data[6] = 0xaa;
		msg.data[7] = 0xbb;
		msg.data[8] = 0xcc;
		return call SendMsg.send(TOS_BCAST_ADDR, 29, &msg);
	}
	event result_t CommandUse.commandDone(char *commandName, char *resultBuf, SchemaErrorNo errNo)
	{
		return SUCCESS;
	}
	event result_t SendMsg.sendDone(TOS_MsgPtr data, result_t success)
	{
		ParamVals params;
		uint8_t arg = 2;
		params.numParams = 1;
		params.paramDataPtr[0] = (char*)&arg;
		if (success)
		{
			call CommandUse.invoke("SetLedR", NULL, &errorNo, &params);
			/*
			if (sounderOn)
			{
				arg = 0;
				call CommandUse.invoke("SetSnd", NULL, &errorNo, &params);
				sounderOn = FALSE;
			}
			else
			{
				arg = 1;
				call CommandUse.invoke("SetSnd", NULL, &errorNo, &params);
				sounderOn = TRUE;
			}
			*/
		}
		pending = FALSE;
		return success;
	}
}

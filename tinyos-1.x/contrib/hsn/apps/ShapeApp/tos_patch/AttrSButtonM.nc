/*								
 * 
 *
 *  Orriginall taken from AttrTemp* code. - Martin Lukac
 */
// component to expose Stargate button sensor reading as an attribute

module AttrSButtonM
{
	provides interface StdControl;
	uses 
	{
		interface AttrRegister;
		interface StdControl as SButtonCtl;
		interface SButton;
		/*
		  interface StdControl as SubControl;
		  interface ADC;
		  interface AttrRegister;
		*/
	}
}
implementation
{
	char *result;
	char *attrName;
	task void getAttrDone();
	task void dataReady();

	command result_t StdControl.init()
	{
	  if (call AttrRegister.registerAttr("sbutton", UINT8, 1) != SUCCESS)
	  {
	    return FAIL;
	  }
	  if (call SButtonCtl.init() != SUCCESS) {
	    return FAIL;
	  }
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


	result_t getButtonData() {
	  post dataReady();
	  return SUCCESS;
	}


	task void dataReady() {
	  //	  call sensor client code
	  *(uint16_t*)result = call SButton.getButton();
//#else
//	  *(uint16_t*)result = 0;
//#endif
	  post getAttrDone();
	}

	event result_t AttrRegister.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
	  atomic {
		result = resultBuf;
		attrName = name;
	  }
	  if (getButtonData() != SUCCESS)
	    return FAIL;
	  *errorNo = SCHEMA_RESULT_PENDING;
	  return SUCCESS;
	}


	// change local post after getAttr is done
	//	async event result_t ADC.dataReady(uint16_t data)
	//	{
	//		*(uint16_t*)result = data;
	//		post getAttrDone();
	//		return SUCCESS;
	//	}


	task void getAttrDone() {
	  call AttrRegister.getAttrDone(attrName, result, SCHEMA_RESULT_READY);
	}

	event result_t AttrRegister.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}


	/*
	char *result;
	char *attrName;
	task void getAttrDone();

	command result_t StdControl.init()
	{
	  call SubControl.init();
	  if (call AttrRegister.registerAttr("sbutton", UINT8, 1) != SUCCESS)
			return FAIL;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
	  call SubControl.start();
	  return SUCCESS;
	}

	command result_t StdControl.stop()
	{
	  call SubControl.stop();
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
		if (call ADC.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	async event result_t ADC.dataReady(uint16_t data)
	{
		*(uint16_t*)result = data;
		post getAttrDone();
		return SUCCESS;
	}

	task void getAttrDone() {
	  call AttrRegister.getAttrDone(attrName, result, SCHEMA_RESULT_READY);
	}

	event result_t AttrRegister.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
	*/
}

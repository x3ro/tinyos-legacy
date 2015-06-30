/*
 * Copyright (c) 2007, RWTH Aachen University
 */
 
/**
 *
 * Condition Operator
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes UllaQuery;

module ConditionM {
  provides {
    interface Condition;
  }

} 

implementation {

	void getIndexOfSelectedAttribute(ResultTuplePtr rtp, Cond *c, int8_t *attrIndex)
	{
		uint8_t i;
		
		*attrIndex = -1; // not found
		
		for (i=0; i<MAX_ATTR; i++)
		{	
			if (c->field == rtp->fields[i])
				*attrIndex = i;
		}
		
		return;
	}
	
  command bool Condition.processCondition(ResultTuplePtr rtp, Cond *c, char idx) {
  
    bool result = FALSE;
    uint16_t fieldValue;
		int8_t attrIndex;
		
		// check which attribute is being processed. Map attribute in the condition to rtp index.
		
		getIndexOfSelectedAttribute(rtp, c, &attrIndex);
		if (attrIndex>=0) {
			fieldValue = rtp->data[attrIndex];
    
    dbg(DBG_USR1, "FieldVal = %d\n", fieldValue);
    //switch (c->opval.op) {
			switch (c->op) {
				case OP_EQ:
			//result = (fieldValue == c->opval.value);
			result = (fieldValue == c->value);
			break;
				case OP_NEQ:
			//result = (fieldValue != c->opval.value);
			result = (fieldValue != c->value);
			break;
				case OP_GT:
			//result = (fieldValue > c->opval.value);
			result = (fieldValue > c->value);
			break;
				case OP_GE:
			//result = (fieldValue >= c->opval.value);
			result = (fieldValue >= c->value);
			break;
				case OP_LT:
			//result = (fieldValue < c->opval.value);
			result = (fieldValue < c->value);
			break;
				case OP_LE:
			//result = (fieldValue <= c->opval.value);
			result = (fieldValue <= c->value);
			break;
			} 
		}
		else {
			result = TRUE; // not found in the condition 
		}
  
    return result;
  
  }

}

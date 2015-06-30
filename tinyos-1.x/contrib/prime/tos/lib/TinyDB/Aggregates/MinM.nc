/**
 * Implements MIN aggregate
 *
 * Author:	Eugene Shvets
 */
includes Aggregates;
//includes TinyDB;

module MinM {
	provides {
		interface Aggregate;
	}
}

implementation {

	command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		AlgebraicData *dest  = (AlgebraicData *)destdata;
		AlgebraicData *merge = (AlgebraicData *)mergedata;

		if (dest->value > merge->value) {
			dest->value = merge->value;
			dest->id    = merge->id;
		}
		
		return SUCCESS;
	}
	
	//we'll probably get rid of this later
	command result_t Aggregate.update(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		AlgebraicData *dest  = (AlgebraicData *)destdata;
		int16_t val = *(int16_t *)value;
		
		if (dest->value > val) {
			dest->value = val;
			dest->id    = TOS_LOCAL_ADDRESS;
		}
		
		return SUCCESS;
	}

	//doubles as startEpoch right now? might separate the two
	command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		AlgebraicData *mydata = (AlgebraicData *)data;
		
		mydata->value = kMAX_SHORT;
		mydata->id    = TOS_LOCAL_ADDRESS;
		
		return SUCCESS;
	}

	command uint16_t Aggregate.stateSize(ParamList *params, ParamVals *paramValues) {
		return sizeof(AlgebraicData);
	}

	command bool Aggregate.hasData(char *data, ParamList *params, ParamVals *paramValues) {
		return TRUE;
	}

	command TinyDBError Aggregate.finalize(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
		AlgebraicData *mydata = (AlgebraicData *)data;
		*(int16_t *)result_buf = mydata->value;
		
		return err_NoError;
	}
	
	command AggregateProperties Aggregate.getProperties() {
		return kEXEMPLARY_PROPERTY | kMONOTONIC_PROPERTY | kDUPLICATE_INSENSITIVE_PROPERTY;
	}
	
}


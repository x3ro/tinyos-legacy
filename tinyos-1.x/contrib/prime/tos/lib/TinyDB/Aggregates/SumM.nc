/**
 * Implements SUM aggregate
 *
 * Author:	Eugene Shvets
 */
includes Aggregates;
//includes TinyDB;

module SumM {
	provides {
		interface Aggregate;
	}
}

implementation {

	command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		AlgebraicData *dest  = (AlgebraicData *)destdata;
		AlgebraicData *merge = (AlgebraicData *)mergedata;

		dest->value += merge->value;
		
		return SUCCESS;
	}
	
	//we'll probably get rid of this later
	command result_t Aggregate.update(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		AlgebraicData *dest  = (AlgebraicData *)destdata;
		int16_t val = *(int16_t *)value;
		dest->value += val;
		
		return SUCCESS;
	}

	//doubles as startEpoch right now? might separate the two
	command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		AlgebraicData *mydata = (AlgebraicData *)data;
		
		mydata->value = 0;
		
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
		return 0;
	}
}
		
		
		
		
		
		
		   







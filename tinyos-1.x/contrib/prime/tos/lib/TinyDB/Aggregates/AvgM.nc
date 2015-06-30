/**
 * Implements AVG aggregate
 *
 * Author:	Eugene Shvets
 */
includes Aggregates;

module AvgM {
	provides {
		interface Aggregate;
	}
}

implementation {

	command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		AverageData *dest  = (AverageData *)destdata;
		AverageData *merge = (AverageData *)mergedata;

		dest->sum += merge->sum;
		dest->count += merge->count;
		
		return SUCCESS;
	}
	
	command result_t Aggregate.update(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		AverageData *dest  = (AverageData *)destdata;
		int16_t val = *(int16_t *)value;
		
		dest->sum += val;
		dest->count++;
		
		return SUCCESS;
	}

	command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		AverageData *mydata = (AverageData *)data;
		
		mydata->sum = 0;
		mydata->count = 0;
		
		return SUCCESS;
	}

	command uint16_t Aggregate.stateSize(ParamList *params, ParamVals *paramValues) {
		return sizeof(AverageData);
	}

	command bool Aggregate.hasData(char *data, ParamList *params, ParamVals *paramValues) {
		return TRUE;
	}

	command TinyDBError Aggregate.finalize(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
		AverageData *mydata = (AverageData *)data;
		
		*(int16_t *)result_buf = (mydata->count == 0 ? 0 : mydata->sum / mydata->count );
		
		return err_NoError;
	}
	
	command AggregateProperties Aggregate.getProperties() {
		return 0;
	}
	
}
		
		
		
		
		
		
		   







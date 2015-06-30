/**
 * Implements EXPAVG aggregate
 *
 */
includes Aggregates;

module ExpAvgM {
	provides {
		interface Aggregate;
	}
}

implementation {

	typedef struct {
		int16_t value;
		uint8_t epochsLeft;
	} ExpAvgData;

	command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		ExpAvgData *dest  = (ExpAvgData *)destdata;
		ExpAvgData *merge = (ExpAvgData *)mergedata;
		
		uint8_t newBits = 16 - getNewBitsPerSample(paramValues);

		dest->value = (dest->value - (dest->value >> newBits)) + (merge->value >> newBits);
		
		return SUCCESS;
	}
	
	//we'll probably get rid of this later
	command result_t Aggregate.update(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		ExpAvgData *dest  = (ExpAvgData *)destdata;
		int16_t val = *(int16_t *)value;
		uint8_t newBits = 16 - getNewBitsPerSample(paramValues);
		
		dest->value = (dest->value - (dest->value >> newBits)) + (val >> newBits);
		
		return SUCCESS;
	}

	//doubles as startEpoch right now? might separate the two
	command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		ExpAvgData *mydata = (ExpAvgData *)data;
		
		if (isFirstTime) {
			mydata->value = 0;
			mydata->epochsLeft = 0;
		}
		return SUCCESS;
	}

	command uint16_t Aggregate.stateSize(ParamList *params, ParamVals *paramValues) {
		return sizeof(ExpAvgData);
	}

	command bool Aggregate.hasData(char *data, ParamList *params, ParamVals *paramValues) {
		return TRUE;
	}

	command TinyDBError Aggregate.finalize(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
		ExpAvgData *mydata = (ExpAvgData *)data;
		*(int16_t *)result_buf = mydata->value;
		
		return err_NoError;
	}
	
	command AggregateProperties Aggregate.getProperties() {
		return 0;
	}
	
	
}
		

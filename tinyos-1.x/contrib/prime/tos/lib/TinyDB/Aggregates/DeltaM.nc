/**
 * Implements DELTA aggregate
 *
 */
includes Aggregates;
//includes TinyDB;

module DeltaM {
	provides {
		interface Aggregate;
	}
}

implementation {

	typedef struct {
		int16_t value;
		int16_t lastValue;
		uint8_t epochsLeft;
	} DeltaData;

	command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		DeltaData *dest  = (DeltaData *)destdata;
		DeltaData *merge = (DeltaData *)mergedata;

		uint16_t threshold = getDeltaThreshold(paramValues);
		
		if (threshold > 0 && abs(dest->lastValue - merge->value) >= threshold) {
			dest->lastValue = merge->value;
			dest->epochsLeft = 0;
		} else if (abs(dest->lastValue - merge->value) >
					abs(dest->lastValue - dest->value)) {
			dest->value = merge->value;
		}
		return SUCCESS;
	}
	
	//we'll probably get rid of this later
	command result_t Aggregate.update(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		DeltaData *dest  = (DeltaData *)destdata;

		uint16_t threshold = getDeltaThreshold(paramValues);
		int16_t val = *(int16_t *)value;
		
		if (threshold > 0 && abs(dest->lastValue - val) >= threshold) {
			dest->lastValue = val;
			dest->epochsLeft = 0;
		} else if (abs(dest->lastValue - val) >
					abs(dest->lastValue - dest->value)) {
			dest->value = val;
		}
		return SUCCESS;
	}

	//doubles as startEpoch right now? might separate the two
	command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		DeltaData *mydata = (DeltaData *)data;
		
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		
		if (isFirstTime) {
			mydata->lastValue = 0;
			mydata->value = 0;
			mydata->epochsLeft = 0;
		} else if (mydata->epochsLeft == 0) {
			if (epochsPerWindow > 0) {
				mydata->epochsLeft = epochsPerWindow;
			} else {
				mydata->epochsLeft = 1;
			}
			mydata->lastValue = mydata->value;
		}
		return SUCCESS;
	}

	command uint16_t Aggregate.stateSize(ParamList *params, ParamVals *paramValues) {
		return sizeof(DeltaData);
	}

	command bool Aggregate.hasData(char* data, ParamList *params, ParamVals *paramValues) {
		DeltaData *mydata  = (DeltaData *)data;
		
		if (getEpochsPerWindow(paramValues) > 0 && mydata->epochsLeft > 0)
		 	mydata->epochsLeft--;
		if (mydata->epochsLeft == 0)	return TRUE;
		else return FALSE;
	}

	command TinyDBError Aggregate.finalize(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
		DeltaData *mydata = (DeltaData *)data;
		*(int16_t *)result_buf = mydata->value;
		
		return err_NoError;
	}
	
	command AggregateProperties Aggregate.getProperties() {
		return 0;
	}
}

/**
 * Implements WINMAX aggregate
 *
 * Author:	Eugene Shvets
 */
includes Aggregates;
//includes TinyDB;

module WinMaxM {
	provides {
		interface Aggregate;
	}
}

implementation {

	command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		TemporalAlgebraicData *dest  = (TemporalAlgebraicData *)destdata;
		TemporalAlgebraicData *merge = (TemporalAlgebraicData *)mergedata;
		
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		uint8_t slidingDist     = getSlidingDist(paramValues);
		
		if (dest->lastResult.value < merge->lastResult.value) {
			dest->lastResult.value = merge->lastResult.value;
			dest->lastResult.id    = merge->lastResult.id;
		}
		
		if (epochsPerWindow > slidingDist) {
			uint16_t i,n;
			for (i=dest->head, n = 0; n < dest->nvals;i=(i+1) % dest->size, n++) {
				if (dest->value[i] < merge->value[i])
					dest->value[i] = merge->value[i];
			}
		
		}
		
		return SUCCESS;
	}
	
	//we'll probably get rid of this later
	command result_t Aggregate.update(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		TemporalAlgebraicData *dest  = (TemporalAlgebraicData *)destdata;
		int16_t val = *(int16_t *)value;
		
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		uint8_t slidingDist     = getSlidingDist(paramValues);
		
		if (dest->lastResult.value < val) {
			dest->lastResult.value = val;
			dest->lastResult.id    = TOS_LOCAL_ADDRESS;
		}
		
		if (epochsPerWindow > slidingDist) addValueToTemporalAggState(dest,val);
		
		return SUCCESS;
	}

	//doubles as startEpoch right now? might separate the two
	command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		TemporalAlgebraicData *mydata  = (TemporalAlgebraicData *)data;
		
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		uint8_t slidingDist     = getSlidingDist(paramValues);
		
		if (mydata->epochsLeft == 0 || isFirstTime) {
			mydata->epochsLeft = slidingDist;
			mydata->lastResult.value = kMIN_SHORT;;
			
			if (isFirstTime && epochsPerWindow > slidingDist) {
				//very first time
				mydata->head = mydata->tail = 0;
				mydata->size = epochsPerWindow - slidingDist;
				mydata->nvals = 0;
			}
			
			if (epochsPerWindow > slidingDist) {
				// aggregate the remaining data from last window
				uint16_t i,n;
				for (i=mydata->head, n = 0; n < mydata->nvals; i=(i+1) % mydata->size, n++) {
					if (mydata->lastResult.value < mydata->value[i])
						mydata->lastResult.value = mydata->value[i];
				}
			}
		}
		
		return SUCCESS;
	}

	command uint16_t Aggregate.stateSize(ParamList *params, ParamVals *paramValues) {
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		uint8_t slidingDist     = getSlidingDist(paramValues);
		
		TemporalAlgebraicData tad;
		uint16_t size = sizeof(tad);
		
		if (epochsPerWindow > slidingDist)
		  size = size - sizeof(tad.value) + (epochsPerWindow - slidingDist) * sizeof(tad.value[0]);
		  
		return size;
	}

	command bool Aggregate.hasData(char *data, ParamList *params, ParamVals *paramValues) {
		TemporalAlgebraicData *mydata  = (TemporalAlgebraicData *)data;
		
		if (getEpochsPerWindow(paramValues) > 0 && mydata->epochsLeft > 0)
		 	mydata->epochsLeft--;
		if (mydata->epochsLeft == 0)	return TRUE;
		else return FALSE;
	}

	command TinyDBError Aggregate.finalize(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
	TemporalAlgebraicData *mydata  = (TemporalAlgebraicData *)data;
		*(int16_t *)result_buf = mydata->lastResult.value;
		return err_NoError;
	}
	
	command AggregateProperties Aggregate.getProperties() {
		return 0;
	}
	
	
}

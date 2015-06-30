/**
 * Implements WINAVG aggregate
 *
 * Author:	Eugene Shvets
 */
includes Aggregates;
//includes TinyDB;

module WinAvgM {
	provides {
		interface Aggregate;
	}
}

implementation {

	typedef struct {
		AverageData lastResult;
		
		uint8_t	head;
		uint8_t tail;
		uint8_t size;
		uint8_t nvals;
		
		uint8_t epochsLeft;
		
		AverageData value[1];//variable number of data readings
	} TemporalAverageData;
	
	void addData(TemporalAverageData *tad, int16_t sum, uint16_t count);
	

	command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		TemporalAverageData *dest  = (TemporalAverageData *)destdata;
		TemporalAverageData *merge = (TemporalAverageData *)mergedata;
		
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		uint8_t slidingDist     = getSlidingDist(paramValues);
		
		dest->lastResult.sum += merge->lastResult.sum;
		dest->lastResult.count += merge->lastResult.count;
		
		if (epochsPerWindow > slidingDist) {
			uint16_t i,n;
			for (i=dest->head, n=0; n < dest->nvals; i=(i+1) % dest->size, n++) {
				dest->value[i].sum += merge->value[i].sum;
				dest->value[i].count += merge->value[i].count;
			}
		}
		
		return SUCCESS;
	}
	
	//we'll probably get rid of this later
	command result_t Aggregate.update(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		TemporalAverageData *dest  = (TemporalAverageData *)destdata;
		int16_t val = *(int16_t *)value;
		
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		uint8_t slidingDist     = getSlidingDist(paramValues);
		
		dest->lastResult.sum += val;
		dest->lastResult.count++;
		
		if (epochsPerWindow > slidingDist) addData(dest, val, 1);
		
		return SUCCESS;
	}

	//doubles as startEpoch right now? might separate the two
	command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		TemporalAverageData *mydata  = (TemporalAverageData *)data;
		
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		uint8_t slidingDist     = getSlidingDist(paramValues);
		
		if (mydata->epochsLeft == 0 || isFirstTime) {
			mydata->lastResult.sum = 0;
			mydata->lastResult.count = 0;
			mydata->epochsLeft = slidingDist;
			
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
						mydata->lastResult.sum += mydata->value[i].sum;
						mydata->lastResult.count += mydata->value[i].count;
				}
			}
		}
		
		return SUCCESS;
	}

	command uint16_t Aggregate.stateSize(ParamList *params, ParamVals *paramValues) {
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		uint8_t slidingDist     = getSlidingDist(paramValues);
		
		TemporalAverageData tad;
		uint16_t size = sizeof(tad);
		
		if (epochsPerWindow > slidingDist)
		  size = size - sizeof(tad.value) + (epochsPerWindow - slidingDist) * sizeof(tad.value[0]);
		  
		return size;
	}

	command bool Aggregate.hasData(char *data, ParamList *params, ParamVals *paramValues) {
		TemporalAverageData *mydata  = (TemporalAverageData *)data;
		
		if (getEpochsPerWindow(paramValues) > 0 && mydata->epochsLeft > 0)
		 	mydata->epochsLeft--;
		if (mydata->epochsLeft == 0)	return TRUE;
		else return FALSE;
	}

	command TinyDBError Aggregate.finalize(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
		TemporalAverageData *mydata  = (TemporalAverageData *)data;
		*(uint16_t *)result_buf = (mydata->lastResult.count == 0) ?
			0 : mydata->lastResult.sum / mydata->lastResult.count;
		return err_NoError;
	}
	
	void addData(TemporalAverageData *tad, int16_t sum, uint16_t count) {
		tad->value[tad->tail].sum = sum;
		tad->value[tad->tail].count = count;
		tad->tail = (tad->tail + 1) % tad->size;
		if (tad->nvals == tad->size)
			tad->head = (tad->head + 1) % tad->size;
		else
			tad->nvals++;
	}
	
	command AggregateProperties Aggregate.getProperties() {
		return 0;
	}
	
	
}

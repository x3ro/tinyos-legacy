/**
 * Implements ADPDELTA aggregate
 *
 */
includes Aggregates;
//includes TinyDB;

module AdpDeltaM {
	provides {
		interface Aggregate;
	}
	
	uses {
		interface NetworkMonitor;
	}
}

implementation {

	enum { MAX_ADPAGG_STATE = 4 };// maximum adaptive temporal aggregate size
	
	int16_t addData(TemporalAdpDeltaData *tad, int16_t lastVal, int16_t newVal, uint16_t epoch);
	

	command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		TemporalAdpDeltaData *dest  = (TemporalAdpDeltaData *)destdata;
		TemporalAdpDeltaData *merge = (TemporalAdpDeltaData *)mergedata;
		
		int16_t curVal = dest->value[dest->lastResult.curInd].value;
		int16_t contention;
		int16_t i;
		
		dbg(DBG_USR3, "Merge called.\n");
		
		i = addData(dest, dest->lastResult.value,merge->lastResult.value, getCurrentEpoch(paramValues));
		
		if (dest->nvals == 1 || i >= 0 &&
			abs(dest->lastResult.value - merge->lastResult.value) >
			abs(dest->lastResult.value - curVal)) {
				dest->lastResult.curInd = i;
		}
		contention = call NetworkMonitor.getContention();
		
		if (contention < getContentionThreshold(paramValues)) { //ok to output this epoch
			dest->lastResult.value = dest->value[(int16_t)dest->lastResult.curInd].value;
			dest->lastResult.epoch = dest->value[(int16_t)dest->lastResult.curInd].epoch;
			// delete the value that was output
			for (i = dest->lastResult.curInd; i < dest->nvals - 1; i++) {
					dest->value[i] = dest->value[i+1];
			}
			dest->nvals--;
			
			// update next output candidate
			dest->lastResult.curInd = 0;
			for (i = 1; i < dest->nvals; i++) {
				if (abs(dest->value[i].value - dest->lastResult.value) >
					abs(dest->value[(int16_t)dest->lastResult.curInd].value - dest->lastResult.value))
					dest->lastResult.curInd = i;
			}
			
			dest->epochsLeft = 0;
		}
			
		return SUCCESS;
	}

	command result_t Aggregate.update(char *destdata, char *value, ParamList *params, ParamVals *paramValues) {
		TemporalAdpDeltaData *dest  = (TemporalAdpDeltaData *)destdata;
		
		int16_t val = *(int16_t *)value;
	
		int16_t curVal = dest->value[dest->lastResult.curInd].value;
		int16_t contention;
		int16_t i;
		
		i = addData(dest, dest->lastResult.value,
									val,
									getCurrentEpoch(paramValues));
		if (dest->nvals == 1 || i >= 0 &&
			abs(dest->lastResult.value - val) >
			abs(dest->lastResult.value - curVal)) {
				dest->lastResult.curInd = i;
		}
		contention = call NetworkMonitor.getContention();
		
		//dbg(DBG_USR3, "ADPDELTA Update: contention is %d\n", contention);
		//dbg(DBG_USR3, "ADPDELTA Update: contention threshold is %d\n", getContentionThreshold(paramValues));
		
		if (contention < getContentionThreshold(paramValues)) { //ok to output this epoch
			dest->lastResult.value = dest->value[(int16_t)dest->lastResult.curInd].value;
			dest->lastResult.epoch = dest->value[(int16_t)dest->lastResult.curInd].epoch;
			// delete the value that was output
			for (i = dest->lastResult.curInd; i < dest->nvals - 1; i++) {
					dest->value[i] = dest->value[i+1];
			}
			dest->nvals--;
			
			// update next output candidate
			dest->lastResult.curInd = 0;
			for (i = 1; i < dest->nvals; i++) {
				if (abs(dest->value[i].value - dest->lastResult.value) >
					abs(dest->value[(int16_t)dest->lastResult.curInd].value - dest->lastResult.value))
					dest->lastResult.curInd = i;
			}
			
			dest->epochsLeft = 0;
		}
			
		return SUCCESS;
	}
	//doubles as startEpoch right now? might separate the two
	command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		TemporalAdpDeltaData *mydata  = (TemporalAdpDeltaData *)data;
		
		if (isFirstTime) {
			mydata->nvals = 0;
			mydata->lastResult.value = 0;
			mydata->lastResult.curInd = 0;
			mydata->epochsLeft = 1;
	  	} else if (mydata->epochsLeft == 0)
	  				mydata->epochsLeft = 1;
		
		return SUCCESS;
	}

	command uint16_t Aggregate.stateSize(ParamList *params, ParamVals *paramValues) {
		TemporalAdpDeltaData tad;
		uint16_t size = sizeof(tad) - sizeof(tad.value) + MAX_ADPAGG_STATE * sizeof(tad.value[0]);
		  
		return size;
	}

	command bool Aggregate.hasData(char *data, ParamList *params, ParamVals *paramValues) {
		TemporalAdpDeltaData *mydata  = (TemporalAdpDeltaData *)data;
		bool result = FALSE;
		if (getEpochsPerWindow(paramValues) > 0 && mydata->epochsLeft > 0)
		 	mydata->epochsLeft--;
		if (mydata->epochsLeft == 0)	result = TRUE;
		dbg(DBG_USR3, "ADPDELTA hasData returns %d\n", result);
		return result;
	}

	command TinyDBError Aggregate.finalize(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
		TemporalAdpDeltaData *mydata  = (TemporalAdpDeltaData *)data;
		*(int16_t *)result_buf = mydata->lastResult.value;
		return err_NoError;
	}
	
	command AggregateProperties Aggregate.getProperties() {
		return 0;
	}
	
	int16_t addData(TemporalAdpDeltaData *tad, int16_t lastVal, int16_t newVal, uint16_t epoch) {
		int16_t ind;
		if (tad->nvals < MAX_ADPAGG_STATE) {
			tad->value[(int16_t)tad->nvals].value = newVal;
			tad->value[(int16_t)tad->nvals].epoch = epoch;
			ind = tad->nvals++;
		} else {
			// must pick a victim
			int16_t i, victim, victimDelta;
			victim = 0;
			victimDelta = abs(tad->value[0].value - lastVal);
			for (i = 1; i < tad->nvals; i++) {
				if (abs(tad->value[i].value - lastVal) < victimDelta) {
					victim = i;
					victimDelta = abs(tad->value[i].value - lastVal);
				}
			}
			if (abs(lastVal - newVal) < victimDelta) {
				ind = -1; // the new value is victim
			} else {
				tad->value[victim].value = newVal;
				tad->value[victim].epoch = epoch;
				ind = victim;
			}
		}
		return ind;
	}
	
}

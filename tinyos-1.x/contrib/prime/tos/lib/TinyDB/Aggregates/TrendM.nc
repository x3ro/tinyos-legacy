/**
 * Implements TREND aggregate
 *
 */
includes Aggregates;
//includes TinyDB;

module TrendM {
	provides {
		interface Aggregate;
	}
}

implementation {

	typedef struct {
		int16_t value;
		int16_t lastVal;
		int16_t trend;
		
		uint8_t epochsLeft;
	} TrendData;
	
	/**
	 * NOTE: really don't make sense to aggregate TREND across multiple nodes!
	 * We will just don't something arbitrary here.
	 */
	command result_t Aggregate.merge(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		TrendData *dest  = (TrendData *)destdata;
		TrendData *merge = (TrendData *)mergedata;

		uint8_t threshold = getDeltaThreshold(paramValues);
		
		if (dest->trend >= 0 && dest->lastVal - merge->value <= threshold) {
			if (dest->lastVal < merge->value)
				dest->lastVal = merge->value;
			dest->trend++;
		}
		else if (dest->trend < 0 && merge->value - dest->lastVal < threshold) {
			if (dest->lastVal > merge->value)
				dest->lastVal = merge->value;
			dest->trend--;
		} else {
			// direction change
			if (threshold == 0 || abs(dest->trend) >= threshold) {
				// output value at turning point
				dest->value = dest->lastVal;
				dest->epochsLeft = 0;
			}
			if (dest->trend >= 0)
				dest->trend = -1;
			else
				dest->trend = 1;
			dest->lastVal = merge->value;
		}
		
		if (dest->epochsLeft > 0)
			dest->value = merge->value;
		
		return SUCCESS;
	}
	
	//we'll probably get rid of this later
	command result_t Aggregate.update(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		TrendData *d  = (TrendData *)destdata;

		uint8_t threshold = getDeltaThreshold(paramValues);
		int16_t val = *(int16_t *)value;
		
		dbg(DBG_USR3, "TREND: state = (%d, %d, %d), merge val = %d\n", d->value, d->lastVal, d->trend, val);
		if (d->epochsLeft == 0) // only for the first time
			d->value = d->lastVal = val;
		else if (d->trend >= 0 && d->lastVal - val <= threshold) {
			if (d->lastVal < val)
				d->lastVal = val;
			d->trend++;
		} else if (d->trend < 0 && val - d->lastVal < threshold) {
			if (d->lastVal > val)
				d->lastVal = val;
			d->trend--;
		} else {
			// direction change
			if (threshold == 0 || abs(d->trend) >= threshold) {
				dbg(DBG_USR3, "TREND: direction change.\n");
				// output value at turning point
				d->value = d->lastVal;
				d->epochsLeft = 0;
			}
			if (d->trend >= 0)
				d->trend = -1;
			else
				d->trend = 1;
			d->lastVal = val;
		}
		if (d->epochsLeft > 0)
			d->value = val;
		
		return SUCCESS;
		
	}

	//doubles as startEpoch right now? might separate the two
	command result_t Aggregate.init(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		TrendData *d = (TrendData *)data;
		uint8_t epochsPerWindow = getEpochsPerWindow(paramValues);
		
		if (isFirstTime){
			d->value = 0;
			d->lastVal = 0;
			d->trend = 0;
			d->epochsLeft = 0;
	  	} else if (d->epochsLeft == 0) {
			if (epochsPerWindow > 0)
				d->epochsLeft = epochsPerWindow;
			else
				d->epochsLeft = 1;
		}
		
		return SUCCESS;
	}

	command uint16_t Aggregate.stateSize(ParamList *params, ParamVals *paramValues) {
		return sizeof(TrendData);
	}

	command bool Aggregate.hasData(char *data, ParamList *params, ParamVals *paramValues) {
		TrendData *mydata  = (TrendData *)data;
		
		if (getEpochsPerWindow(paramValues) > 0 && mydata->epochsLeft > 0)
		 	mydata->epochsLeft--;
		if (mydata->epochsLeft == 0)	return TRUE;
		else return FALSE;
	}

	command TinyDBError Aggregate.finalize(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
		TrendData *mydata = (TrendData *)data;
		*(int16_t *)result_buf = mydata->value;
		
		return err_NoError;
	}
	
	command AggregateProperties Aggregate.getProperties() {
		return 0;
	}
	
}

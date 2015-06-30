/**
 * Currently, if you want to add a custom aggregate, you have to edit this file,
 * as well as AggOperatorConf.nc
 *
 * Author:	Eugene Shvets
 */

module AggregateUseM {
	provides {
		interface AggregateUse;
	}
	
	uses { // Aggs are hooked up in AggregateOperatorConf now,
	       // but we probably want to make wiring of aggregates self-contained
		interface Aggregate as Agg[uint8_t id];
    }
}

implementation {

	command result_t AggregateUse.merge(uint8_t id, char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		return call Agg.merge[id]( destdata, mergedata, params, paramValues);
	}
	
	//we'll probably get rid of this later
	command result_t AggregateUse.update(uint8_t id, char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		return call Agg.update[id]( destdata, value, params, paramValues);
	}

	//doubles as startEpoch right now? might separate the two
	command result_t AggregateUse.init(uint8_t id, char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		return call Agg.init[id]( data, params, paramValues, isFirstTime);
	}

	command uint16_t AggregateUse.stateSize(uint8_t id, ParamList *params, ParamVals *paramValues) {
		return call Agg.stateSize[id](params,paramValues);
	}

	command bool AggregateUse.hasData(uint8_t id, char *data, ParamList *params, ParamVals *paramValues) {
		return call Agg.hasData[id](data, params, paramValues);
	}

	command TinyDBError AggregateUse.finalize(uint8_t id, char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
		return call Agg.finalize[id](data, result_buf, params, paramValues);
	}
	
	command AggregateProperties AggregateUse.getProperties(uint8_t id) {
		return call Agg.getProperties[id]();
	}
	
	/**
	 * Default implementation of Aggregate interface for id's that are not wired
	 */
	default command result_t Agg.merge[uint8_t id]
	(char *destdata, char *mergedata, ParamList *params, ParamVals *paramValues) {
		return SUCCESS;
	}
	
	default command result_t Agg.update[uint8_t id]
	(char *destdata, char* value, ParamList *params, ParamVals *paramValues) {
		return SUCCESS;
	}
	
	default command result_t Agg.init[uint8_t id]
	(char *data, ParamList *params, ParamVals *paramValues, bool isFirstTime){
		return SUCCESS;
	}
	
	default command uint16_t Agg.stateSize[uint8_t id]
	(ParamList *params, ParamVals *paramValues) {
		return 0;
	}
	
	default command bool Agg.hasData[uint8_t id]
	(char *data, ParamList *params, ParamVals *paramValues) {
		return FALSE;
	}
	
	default command TinyDBError Agg.finalize[uint8_t id]
	(char *data, char *result_buf, ParamList *params, ParamVals *paramValues) {
		return err_NoError;
	}
	
	default command AggregateProperties Agg.getProperties[uint8_t id]() {
		return 0;
	}
}


/*
 * Author: Zhigang Chen
 * Date:   March 9, 2003
 */

/*
 * interface of query processor
 * pretty much the same interface as query index since most work is done within query index for the time being
 * later other stuff other than query index may be added 
 * also provides error checking wrapper for query index
 */

includes SensorDB;

interface QueryProcessor
{
    //init data structure
    command result_t init(Role r);

    //for type-1 query
    //only pre-estimate overlap now
    //no response
    command result_t processQuery(ParsedQueryPtr query);
    event result_t processQueryComplete(ParsedQueryPtr query, result_t result);

    //for type2 query
    command result_t processQuery2(ParsedQuery2Ptr query2, QueryResponse2Ptr rsp2);
    event result_t processQuery2Complete(ParsedQuery2Ptr query2, QueryResponse2Ptr rsp2, result_t result);

    //for tuple /data
    command result_t processTuple(TuplePtr tuple, uint8_t epoch, QueryResponsePtr rsp);
    event result_t processTupleComplete(TuplePtr tuple, QueryResponsePtr rsp, result_t result);

    command result_t postProcessQuery(QueryResponse *rsp, uint8_t num_rsp);
    event result_t postProcessQueryComplete(ParsedQuery2Ptr trigger);

    command result_t restoreEpoch(uint8_t qid);
    command result_t stopTrendQuery();

    command uint8_t getQ2ID();
}

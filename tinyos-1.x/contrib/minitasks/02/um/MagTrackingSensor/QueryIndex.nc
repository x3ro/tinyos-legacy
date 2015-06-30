/*
 * Author: Zhigang Chen
 * Date:   March 11, 2003
 */

/* interface of query index
 *
 */

includes SensorDB;

interface QueryIndex {

  //init data structure
  command ErrorCode init();

  //add a query to the index trees
  command ErrorCode addQuery(ParsedQueryPtr query);
  event ErrorCode addQueryComplete(ParsedQueryPtr query, ErrorCode result);

  //delete a query from the relevant index trees
  command ErrorCode deleteQuery(uint8_t qid);
  event ErrorCode deleteQueryComplete(uint8_t qid, ErrorCode result);
    
  //probe index tree in epoch by a Tuple and find which queries match
  command ErrorCode searchTuple(TuplePtr tuple, uint8_t epoch, uint8_t *queryMatched); //figure out which query matches 
  event ErrorCode searchTupleComplete(TuplePtr tuple, uint8_t *queryMatched, uint8_t numQueryMatched, ErrorCode result);

  //estimate overlap and non-overlap of the query with indexed queries
  //  command ErrorCode estimateQueryOverlap(ParsedQueryPtr query); //figure out the overlapping probability of this interval with the indexed intervals
  //  event ErrorCode estimateQueryOverlapComplete(ParsedQueryPtr query, uint16_t totalMatch, uint16_t overlap, uint16_t nonoverlap, ErrorCode result);

  command ErrorCode updateEpoch(uint8_t qid, uint8_t new_epoch);
  event ErrorCode updateEpochComplete(uint8_t qid, ErrorCode result);

  //for coor only
  command ErrorCode saveQuery(ParsedQueryPtr query, ParsedQueryPtr* query_saved);
  command ParsedQueryPtr getQuery(uint8_t qid);
}


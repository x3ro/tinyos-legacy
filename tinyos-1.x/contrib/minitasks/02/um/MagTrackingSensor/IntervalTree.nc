/*
 * Author: Zhigang Chen
 * Date:   March 11, 2003
 */

/* interface of interval stats
 *
 */

includes SensorDB;

interface IntervalTree {
    //add the conditions of a query
    command ErrorCode init();
	
	//insert an interval of a query
    command ErrorCode insertInt(int16_t lb, int16_t rb, uint8_t qid, Attrib att, EpochLevel qlevel, uint8_t queryInfoIndex); 

	//    event ErrorCode insertIntComplete(uint8_t qid, uint8_t queryInfoIndex, ErrorCode result);

    command ErrorCode updateIntEpoch(uint8_t qid, uint8_t queryInfoIndex, uint8_t old_epoch, uint8_t new_epoch);
    event ErrorCode updateIntEpochComplete(uint8_t qid, uint8_t queryInfoIndex, ErrorCode result);

    command ErrorCode deleteInt(uint8_t qid, uint8_t queryBufIndex); //delete an interval by its subscript
    event ErrorCode deleteIntComplete(uint8_t qid, uint8_t queryBufIndex, ErrorCode result);

    command ErrorCode searchPoint(Attrib att, EpochLevel qlevel, int16_t point, uint8_t *queryMatched); //figure out which query matches 
    event ErrorCode searchPointComplete(uint8_t *queryMatched, uint8_t numQueryMatched, ErrorCode result);

    //figure out the overlapping probability of this interval with the indexed intervals
	//    command ErrorCode estimateOverlapProb(int16_t lb, int16_t rb, Attrib att, EpochLevel qlevel); 
	//    event ErrorCode estimateOverlapProbComplete(uint16_t totalMatch, uint16_t totalOverlap, uint16_t totalNonoverlap, ErrorCode result);

}



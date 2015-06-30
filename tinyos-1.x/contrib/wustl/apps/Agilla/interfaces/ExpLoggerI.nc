/**
 * Logs statistics about the directory service operations.
 *
 * @author Chien-Liang Fok
 */
interface ExpLoggerI
{
  command result_t reset();
  //command result_t incQueryMsg();
  //command result_t incNumUpdates();
  //command result_t incNumReplies();
  command result_t sendQueryLatency(uint32_t latency);
  command result_t sendTrace(uint16_t agentID, uint16_t nodeID, uint16_t action, uint16_t success, AgillaLocation loc);
  command result_t sendTraceQid(uint16_t agentID, uint16_t nodeID, uint16_t action, uint16_t qid, uint16_t success, AgillaLocation loc);
  command result_t sendGetAgentsResultsTrace(AgillaQueryReplyAllAgentsMsg* replyMsg);
  command result_t sendSetCluster(uint16_t newClusterHead);
}

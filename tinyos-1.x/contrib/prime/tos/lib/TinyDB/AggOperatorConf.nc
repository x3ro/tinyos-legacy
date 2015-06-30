/**
 * This configuration wires AggOperator to individual aggregates
 */
 
#ifndef NETWORK_MODULE
#define NETWORK_MODULE	NetworkC
#endif

includes CompileDefines;
includes Aggregates;

configuration AggOperatorConf {

provides {
    interface Operator;
    command TinyDBError addResults(QueryResult *qr, ParsedQuery *q, Expr *e);
    command TinyDBError finalizeAggExpr(QueryResult *qr, ParsedQueryPtr q, Expr *e, char *result_buf);
    command short getGroupNoFromQr(QueryResult *qr);
  }
}

implementation {
	components AggOperator, TinyAlloc, TupleRouterM, Tuple, ParsedQuery, ExprEvalC,
			   NoLeds, QueryResult;
	components AggregateUseM, MaxM, MinM, CountM, SumM, AvgM, ExpAvgM,
			   WinMinM, WinMaxM, WinCountM, WinSumM, WinAvgM;
#ifdef kFANCY_AGGS
	components WinRandM, AdpDeltaM, DeltaM, TrendM, RandomLFSR, NETWORK_MODULE;
#endif
			   
	Operator = AggOperator;
	addResults = AggOperator.addResults;
	finalizeAggExpr = AggOperator.finalizeAggExpr;
	getGroupNoFromQr = AggOperator.getGroupNoFromQr;
	
	AggOperator.MemAlloc -> TinyAlloc;
	AggOperator.QueryProcessor -> TupleRouterM;
	AggOperator.TupleIntf -> Tuple;
 	AggOperator.ParsedQueryIntf -> ParsedQuery;
	AggOperator.ExprEval -> ExprEvalC;
	AggOperator.Leds -> NoLeds;
	AggOperator.QueryResultIntf -> QueryResult;
	AggOperator.signalError -> TupleRouterM.signalError;
	
	//hook up aggregates
	AggOperator.AggregateUse -> AggregateUseM;
	
	//maybe we need a config for AggregateUse?
    MaxM.Aggregate <- AggregateUseM.Agg[kMAX];
    MinM.Aggregate <- AggregateUseM.Agg[kMIN];
    CountM.Aggregate <- AggregateUseM.Agg[kCOUNT];
    SumM.Aggregate <- AggregateUseM.Agg[kSUM];
    AvgM.Aggregate <- AggregateUseM.Agg[kAVG];
    ExpAvgM.Aggregate <- AggregateUseM.Agg[kEXP_AVG];
    WinMinM.Aggregate <- AggregateUseM.Agg[kWIN_MIN];
    WinMaxM.Aggregate <- AggregateUseM.Agg[kWIN_MAX];
    WinCountM.Aggregate <- AggregateUseM.Agg[kWIN_COUNT];
    WinSumM.Aggregate <- AggregateUseM.Agg[kWIN_SUM];
    WinAvgM.Aggregate <- AggregateUseM.Agg[kWIN_AVG];
#ifdef kFANCY_AGGS
	WinRandM.Aggregate <- AggregateUseM.Agg[kWIN_RAND];
	AdpDeltaM.Aggregate <- AggregateUseM.Agg[kADP_DELTA];
	DeltaM.Aggregate <- AggregateUseM.Agg[kDELTA];
	TrendM.Aggregate <- AggregateUseM.Agg[kTREND];
	
    WinRandM.Random -> RandomLFSR;
	AdpDeltaM.NetworkMonitor -> NETWORK_MODULE;
#endif

}
	

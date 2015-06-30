/**
 * The Aggregator is the top-level application where all the signal
 * chains, communication chains, etc are wired together
 *
 * Contact- Sandip Bapat
 */

includes OTime;
includes GridTreeMsg;

configuration Aggregator
{
}

implementation
{
    	components  Main, ClassifierC, AggregatorM, GridRouting, 			GridTree, LedsC, TsyncC, ParTunerM, GridTreeM, DetectorC;
	
	Main.StdControl -> ClassifierC;
	Main.StdControl -> AggregatorM;
	Main.StdControl -> GridTree;
	Main.StdControl -> ParTunerM;
	Main.StdControl -> DetectorC;

     	//The next 3 lines are for routing
    	AggregatorM.RoutingControl -> GridRouting.StdControl;	
	AggregatorM.Routing -> GridRouting;
    	GridRouting.GridInfo -> GridTree.GridInfo;
    
	AggregatorM.Classifier -> ClassifierC;
	AggregatorM.Detector -> DetectorC;
      AggregatorM.Leds -> LedsC;
    	AggregatorM.OTime -> TsyncC;
 
	ParTunerM.BroadcastingNP -> GridTree.BroadcastingNP;
}

#ifndef _AGGREGATOR_H
#define _AGGREGATOR_H

#define USE_SCHEDULE 1 
#define USE_KRAKEN 1
#define USE_PIR 1
#endif

configuration Aggregator
{}
implementation
{
    	components  Main, AggregatorM, 

#ifdef USE_KRAKEN
	KrakenC,
#endif

ScheduleC, PirDetectorC,
LedsC;

#ifdef USE_KRAKEN
Main.StdControl -> KrakenC;
#endif

Main.StdControl -> AggregatorM;
AggregatorM.ScheduleControl -> ScheduleC;
AggregatorM.PirControl -> PirDetectorC;
AggregatorM.PirDetector -> PirDetectorC;
AggregatorM.Leds -> LedsC;
}

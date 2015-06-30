/**
 * @author Mark Kranz
 */

includes Mate;

configuration OPradiosleep {
  provides interface MateBytecode;
}

implementation {
  components LedsC
	, OPsendlqiM
    , MStacksProxy
    , CC2420RadioC as Comm
    , OPradiosleepM
    , TimerC
    , MContextSynchProxy
    , MTypesProxy
		, MVirusProxy
    , MateEngine as VM;
  
  MateBytecode = OPradiosleepM;

  OPradiosleepM.Leds -> LedsC;
  OPradiosleepM.RadioControl -> Comm;
  OPradiosleepM.Stacks -> MStacksProxy;
  
  OPradiosleepM.SleepTimer -> TimerC.TimerMilli[unique("Timer")];
  OPradiosleepM.Types -> MTypesProxy;
  OPradiosleepM.Synch -> MContextSynchProxy;
  OPradiosleepM.EngineStatus -> VM;   

  OPradiosleepM.radioOn -> OPsendlqiM.sendDone;
	OPradiosleepM.VirusControl -> MVirusProxy;
}

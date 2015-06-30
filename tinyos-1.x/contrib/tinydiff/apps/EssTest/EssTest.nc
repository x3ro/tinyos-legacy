////////////////////////////////////////////////////////////////////////////
//
// CENS
//
// Contents: 
//
// Purpose: 
//
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

includes EssDefs;

configuration EssTest
{

}
implementation
{
  components Main, 
	     EssM, 
	     EssFilterM, 
	     TimerC, 
	     LedsC, 
	     EssTestM, 
	     CC1000ControlM,
             ExtGenericComm as GenericComm,
             RandomLFSR,
             NeighborStoreM,
	     OnePhasePullNlist as OPP;

  Main.StdControl -> CC1000ControlM.StdControl;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> GenericComm.Control;

  Main.StdControl -> OPP.StdControl; 
  // the wiring above takes care of initializing NeighborStoreM
  Main.StdControl -> EssFilterM.StdControl;
  Main.StdControl -> EssM.StdControl;
  Main.StdControl -> EssTestM.StdControl;

  // Using the standard string that is used system-wide for timers
  EssTestM.EssComm -> EssM.EssComm;
  EssTestM.Leds -> LedsC;
  EssTestM.Subscribe -> OPP.Subscribe; 
  EssTestM.Timer -> TimerC.Timer[ unique ( "Timer" ) ];
  EssTestM.InterestFilter -> OPP.Filter[1]; // comes after EssFilter's filter
  EssTestM.CC1000Control -> CC1000ControlM; 
  EssTestM.Random -> RandomLFSR;

  EssFilterM.EssState -> EssM.EssState;
  // connect it to the highest priority filter (we have only one filter
  // anyway)
  EssFilterM.Filter -> OPP.Filter[0];
 
  EssM.Timer -> TimerC.Timer[ unique( "Timer" ) ];
  EssM.Leds -> LedsC;
  EssM.Publish -> OPP.Publish;
  EssM.ReadNeighborStore -> NeighborStoreM.ReadNeighborStore;
}

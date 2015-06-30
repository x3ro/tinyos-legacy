////////////////////////////////////////////////////////////////////////////
//
// CENS
//
// Contents: 
//
// Purpose: 
//
////////////////////////////////////////////////////////////////////////////
//
// $Id: EssBasicTest.nc,v 1.1.1.2 2004/03/06 03:01:04 mturon Exp $
//
// $Log: EssBasicTest.nc,v $
// Revision 1.1.1.2  2004/03/06 03:01:04  mturon
// Initial import.
//
// Revision 1.1.1.1  2003/06/12 22:11:27  mmysore
// First check-in of TinyDiffusion
//
// Revision 1.4  2003/06/12 05:20:02  mmysore
// Fixed compilation errors
//
// Revision 1.3  2003/05/08 00:48:57  eoster
// Added code / support for member state and linked in neighbor store.
//
// Revision 1.2  2003/05/06 04:19:52  mmysore
// Checking in first-cut working versions of EssM, EssFilter and EssTest;
// Small modifications to OnePhasePull
//
// Revision 1.1  2003/04/25 23:24:52  eoster
// Initial checkin
//
////////////////////////////////////////////////////////////////////////////

includes EssDefs;

configuration EssBasicTest
{

}
implementation
{
  components Main, 
             EssM, 
             TimerC, 
             LedsC, 
             EssBasicTestM, 
             NeighborStoreM, 
             OnePhasePullNlist;

  Main.StdControl -> EssBasicTestM.StdControl;
  Main.StdControl -> EssM.StdControl;
  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> OnePhasePullNlist;

  // Using the standard string that is used system-wide for timers
  EssBasicTestM.DookTimer -> TimerC.Timer[ unique( "Timer" ) ];
  EssBasicTestM.EssState -> EssM.EssState;
  EssBasicTestM.EssComm -> EssM.EssComm;
  EssBasicTestM.Leds -> LedsC;

  EssM.Timer -> TimerC.Timer[ unique( "Timer" ) ];
  EssM.Leds -> LedsC;
  EssM.ReadNeighborStore -> NeighborStoreM.ReadNeighborStore;
  EssM.Publish -> OnePhasePullNlist;
}

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
// $Id: Ess.nc,v 1.1.1.2 2004/03/06 03:01:06 mturon Exp $
//
// $Log: Ess.nc,v $
// Revision 1.1.1.2  2004/03/06 03:01:06  mturon
// Initial import.
//
// Revision 1.1.1.1  2003/06/12 22:11:28  mmysore
// First check-in of TinyDiffusion
//
// Revision 1.2  2003/04/29 02:07:21  eoster
// Added comments and cleaned up a bit.
//
// Revision 1.1  2003/04/25 23:23:54  eoster
// Initial checkin
//
////////////////////////////////////////////////////////////////////////////

configuration EssApp {
  provides
  {
    EssState;
    EssComm;
  }
}
implementation {
  components Main, TimerC, EssAppM, LedsC;

  Main.StdControl -> EssAppM.StdControl;
}


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
// $Id: EssFilter.nc,v 1.1.1.2 2004/03/06 03:01:06 mturon Exp $
//
// $Log: EssFilter.nc,v $
// Revision 1.1.1.2  2004/03/06 03:01:06  mturon
// Initial import.
//
// Revision 1.1.1.1  2003/06/12 22:11:28  mmysore
// First check-in of TinyDiffusion
//
// Revision 1.1  2003/04/30 22:43:49  eoster
// Initial checkin.
//
////////////////////////////////////////////////////////////////////////////

configuration EssFilter
{
  provides
  {
    Filter;
  }
}
implementation
{
  components Main, Ess, EssFilter;

  Main.StdControl -> EssFilter.StdControl;
  EssFilter.EssState -> Ess.EssState;
}

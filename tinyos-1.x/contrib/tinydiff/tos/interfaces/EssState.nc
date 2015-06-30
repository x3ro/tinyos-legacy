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
// $Id: EssState.nc,v 1.1.1.2 2004/03/06 03:01:06 mturon Exp $
//
// $Log: EssState.nc,v $
// Revision 1.1.1.2  2004/03/06 03:01:06  mturon
// Initial import.
//
// Revision 1.1.1.1  2003/06/12 22:11:28  mmysore
// First check-in of TinyDiffusion
//
// Revision 1.3  2003/05/08 00:47:20  eoster
// Added interfaces for getting and setting member state.
//
// Revision 1.2  2003/05/06 04:19:52  mmysore
// Checking in first-cut working versions of EssM, EssFilter and EssTest;
// Small modifications to OnePhasePull
//
// Revision 1.1  2003/04/25 23:23:01  eoster
// Initial checkin
//
////////////////////////////////////////////////////////////////////////////

includes EssDefs;

interface EssState
{
  command result_t addClusterHead( struct ClusterHead_s *p_pClusterHead );
  command result_t getClusterHead( struct ClusterHead_s *p_pOutput );

  command uint8_t getChTimeout( );
  command result_t setChTimeout( uint8_t p_uiTimeout );

  command uint8_t getAdjListPeriod( );
  command result_t setAdjListPeriod( uint8_t p_uiPeriod );
}



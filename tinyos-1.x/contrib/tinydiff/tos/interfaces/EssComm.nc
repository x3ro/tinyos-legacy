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
// $Id: EssComm.nc,v 1.1.1.2 2004/03/06 03:01:06 mturon Exp $
//
// $Log: EssComm.nc,v $
// Revision 1.1.1.2  2004/03/06 03:01:06  mturon
// Initial import.
//
// Revision 1.1.1.1  2003/06/12 22:11:28  mmysore
// First check-in of TinyDiffusion
//
// Revision 1.2  2003/04/30 22:42:15  eoster
// Added type field to interface command.
//
// Revision 1.1  2003/04/25 23:23:01  eoster
// Initial checkin
//
////////////////////////////////////////////////////////////////////////////

interface EssComm {
	command result_t send( int8_t p_iType,
                         int16_t *p_pBuffer,
                         int16_t p_iBuffLen );
}



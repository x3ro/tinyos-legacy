////////////////////////////////////////////////////////////////////////////
//
// CENS
//
// Contents: 
//
// Purpose: THIS MODULE IS A STOP-GAP MEASURE.  IT IS NOT INTENDED TO BE USED
//          FOR VERY LONG BEFORE THE SECOND PHASE OF THE ESS!
//
////////////////////////////////////////////////////////////////////////////
//
// $Id: ServicesM.nc,v 1.2 2003/06/23 23:19:36 mmysore Exp $
//
// $Log: ServicesM.nc,v $
// Revision 1.2  2003/06/23 23:19:36  mmysore
// Fix to make tinydiff work with latest TinyOS cvs.  The new sensorIB stuff is
// (somehow :-> ) compatible with the latest mica2 stack code on cvs.
//
// Revision 1.5  2003/06/23 19:17:04  mmysore
// Checking in ServicesSMAC app
//
// Revision 1.4  2003/05/09 19:39:49  eoster
// Added call to send adj list.
//
// Revision 1.3  2003/05/09 02:30:23  mmysore
// Changed data interval in Services; changed select timeout in diffsink
//
// Revision 1.2  2003/05/09 00:28:22  mmysore
// Small changes to Services and diffsink
//
// Revision 1.1  2003/05/08 21:00:49  eoster
// Initial checkin.
//
////////////////////////////////////////////////////////////////////////////

includes IB;
includes EssDefs;

module ServicesM
{
  provides interface StdControl;

  uses
  {
    interface StdControl as SamplerControl;
    interface Sample;

    interface EssState;
    interface EssComm;

  }
}
implementation
{
  task void sendSample( );
  enum 
  {
    // "SI" stands for "Sampling Interval"
    SI_DEFAULT = 30, // 30 seconds...
    SI_DISABLE = 0
  };

  // The state of the sensor values for Sampler.
  uint8_t     m_uiDataType;
  uint16_t    m_uiData;

  command result_t StdControl.init( )
  {
    result_t tReturn = SUCCESS;

    tReturn = call SamplerControl.init( );

    m_uiDataType = 0;
    m_uiData = 0;

    return tReturn;
  }

  command result_t StdControl.start( )
  {
    result_t tReturn = SUCCESS;

    tReturn = call SamplerControl.start( );
    tReturn = call Sample.sample( 0,
                                  BATTERY,
                                  SI_DEFAULT );

    return tReturn;
  }

  command result_t StdControl.stop( )
  {
    result_t tReturn = SUCCESS;

    tReturn = call SamplerControl.stop( );
    tReturn = call Sample.sample( 6,
                                  BATTERY,
                                  SI_DISABLE );

    return tReturn;
  }

  event result_t Sample.dataReady( uint8_t p_uiChannel,
                                   uint8_t p_uiChannelType,
                                   uint16_t p_uiData )
  {
    result_t tReturn = SUCCESS;

    if ( BATTERY == p_uiChannelType )
    {
      m_uiDataType = ESS_BATTERY_KEY;
      m_uiData = p_uiData;

      tReturn = post sendSample( );
    }
    else
    {
      tReturn = FAIL;
    }

    return tReturn;
  }

  task void sendSample( )
  {
    uint8_t uiDataType = 0;
    uint16_t uiData = 0;

    uiDataType = m_uiDataType;
    uiData = m_uiData;

    call EssComm.send( uiDataType,
                       &uiData,
                       1 );
  }
}

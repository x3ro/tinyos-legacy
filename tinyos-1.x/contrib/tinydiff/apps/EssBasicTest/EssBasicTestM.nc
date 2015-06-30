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
// $Id: EssBasicTestM.nc,v 1.1.1.2 2004/03/06 03:01:04 mturon Exp $
//
// $Log: EssBasicTestM.nc,v $
// Revision 1.1.1.2  2004/03/06 03:01:04  mturon
// Initial import.
//
// Revision 1.1.1.1  2003/06/12 22:11:27  mmysore
// First check-in of TinyDiffusion
//
// Revision 1.4  2003/05/08 00:48:58  eoster
// Added code / support for member state and linked in neighbor store.
//
// Revision 1.3  2003/04/29 02:50:08  eoster
// Added comments.
//
// Revision 1.2  2003/04/29 01:32:37  eoster
// Cleaned up logic.
//
// Revision 1.1  2003/04/25 23:24:52  eoster
// Initial checkin
//
////////////////////////////////////////////////////////////////////////////

includes EssDefs;

module EssBasicTestM 
{
  provides 
  {
    interface StdControl;
  }
  uses
  {
    interface EssState;
    interface EssComm;
    interface Timer as DookTimer;
    interface Leds;
  }
}
implementation
{
  // This enum will help track the state of the LEDs.
  enum
  {
    EBT_LEDS_INIT = 0,
    EBT_LEDS_GREEN_ON,
    EBT_LEDS_RED_ON
  };

  // This is the state variable for the LEDs.
  int8_t                 m_iLeds;

  // This is member variable for the last value/current
  // value of the dummy cluster head.
  struct ClusterHead_s   m_tCh;

  task void blah( );

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init( )
  {
    m_iLeds = EBT_LEDS_INIT;
    return SUCCESS;
  }

  /**
   * Start the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start( )
  {
    m_tCh.m_iId = 0;
    m_tCh.m_iNumHops = 0;
    m_tCh.m_iLoad = 0;
    m_tCh.m_iLast = 0;

    call EssState.setChTimeout( 10 );

    call EssState.addClusterHead( &m_tCh );
    return call DookTimer.start( TIMER_REPEAT, 5000 );
  }

  /**
   * Stop the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop( )
  {
    return call DookTimer.stop( );
  }

  /**
   * Post the blah task
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t DookTimer.fired( )
  {
    post blah( );

    return SUCCESS;
  }

  /**
   * Reset the "good" values from the last addClusterHead( ) to "bad"
   * values so that we can add a new cluster head that will have "good"
   * values.
   * 
   * @return Always returns void
   **/
  task void blah( )
  {
    struct ClusterHead_s tCh;

    // Get the currently selected cluster head.
    call EssState.getClusterHead( &tCh );

    // Check to make sure this is the last cluster head we added (because
    // this driver makes it the best choice).

    // If this IS the cluster head we set last, it is the right one.
    if ( tCh.m_iId == m_tCh.m_iId )
    {
      // If the red LED was on, turn it off.
      if ( EBT_LEDS_RED_ON == m_iLeds )
      {
        call Leds.redOff( );
        m_iLeds = EBT_LEDS_INIT;
      }

      // Indicate success.
      call Leds.greenToggle( );
      m_iLeds = ( EBT_LEDS_GREEN_ON == m_iLeds ) ? EBT_LEDS_INIT : EBT_LEDS_GREEN_ON;
    }
    // Otherwise, we messed up.
    else
    {
      // If the green LED was on, turn it off.
      if ( EBT_LEDS_GREEN_ON == m_iLeds )
      {
        call Leds.greenOff( );
        m_iLeds = EBT_LEDS_INIT;
      }

      // Indicate failure.
      call Leds.redToggle( );
      m_iLeds = ( EBT_LEDS_RED_ON == m_iLeds ) ? EBT_LEDS_INIT : EBT_LEDS_RED_ON;
    }

    // Set the last cluster head's values to "bad" ones.
    m_tCh.m_iNumHops = 5;
    m_tCh.m_iLoad = 5;

    // Update the values of the last cluster head to reflect it as a poor choice.
    call EssState.addClusterHead( &m_tCh );

    // Now, make sure the next cluster head doesn't exceed our array bounds, and
    // give it much better values (to URGE the EssM to select it). ;)
    m_tCh.m_iId = ( 5 < ++m_tCh.m_iId ) ? 0 : m_tCh.m_iId;
    m_tCh.m_iNumHops = 1;
    m_tCh.m_iLoad = 1;

    // Add our new "good" cluster head.
    call EssState.addClusterHead( &m_tCh );
  }
}


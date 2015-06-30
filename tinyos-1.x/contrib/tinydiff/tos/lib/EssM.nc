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
// $Id: EssM.nc,v 1.1.1.2 2004/03/06 03:01:06 mturon Exp $
//
// $Log: EssM.nc,v $
// Revision 1.1.1.2  2004/03/06 03:01:06  mturon
// Initial import.
//
// Revision 1.1.1.1  2003/06/12 22:11:28  mmysore
// First check-in of TinyDiffusion
//
// Revision 1.11  2003/05/09 21:33:22  eoster
// Added init for adj list period.
//
// Revision 1.10  2003/05/09 19:39:35  eoster
// Unifed types for TinyDiff.
//
// Revision 1.9  2003/05/08 00:47:46  eoster
// Touched up formatting, and added support for configurable state.
//
// Revision 1.8  2003/05/07 17:30:41  eoster
// Rolled back change that added uneeded check to if-else block.
//
// Revision 1.7  2003/05/06 04:41:10  mmysore
// reinserted a few mysteriously missing lines. mabbe I'm tired! :)
//
// Revision 1.6  2003/05/06 04:19:53  mmysore
// Checking in first-cut working versions of EssM, EssFilter and EssTest;
// Small modifications to OnePhasePull
//
// Revision 1.5  2003/05/03 00:40:27  mmysore
// A bunch of small integration-related changes to Eric's Ess modules...
//
// Revision 1.4  2003/04/30 22:43:13  eoster
// Added implementation for send( ) command.
//
// Revision 1.3  2003/04/29 02:07:21  eoster
// Added comments and cleaned up a bit.
//
// Revision 1.2  2003/04/29 01:32:23  eoster
// EMO
//
// Revision 1.1  2003/04/25 23:23:54  eoster
// Initial checkin
//
////////////////////////////////////////////////////////////////////////////

includes EssDefs;
includes attribute;
includes OnePhasePull;

module EssM
{
  provides
  {
    interface StdControl;
    interface EssState;
    interface EssComm;
  }
  uses
  {
    interface Timer;
    interface Leds;
    /*
    <TODO> Don't know where to invoke Publish.publish... but anyway, for now, 
    we don't even have an implementation of Publish.publish... </TODO>
    */
    interface Publish;
    interface ReadNeighborStore;
  }
}
implementation
{
  #include "OPPLib/Debug.c"

  // This member is the array of all seen cluster heads.
  struct ClusterHead_s   m_pClusterHeadArray[ ESS_MAX_CLUSTER_HEADS ];

  // This member is the array of values that are used to weight attributes
  // of a cluster head when evaluating it as a candidate.
  int8_t                 m_pMetricArray[ ESS_NUM_METRICS ];

  // This is the most recent choice of cluster head.
  struct ClusterHead_s  *m_pCurrentClusterHead;

  // This memeber represents the current "time" on the mote, and used to
  // age-out cluster heads that have not reported recently.
  uint8_t               m_uiNow;

  // This is the amount of time the ESS will wait before deciding that a 
  // cluster head is overdue.
  uint8_t               m_uiChTimeout;

  // This is the number of seconds that the ESS will wait in between
  // sending the adjacency list of its network.
  uint8_t               m_uiAdjListPeriod;

  // Buffer for TinyDiffusion
  Attribute m_pAttrs[ ESS_ATTR_BUFF_SIZE ];

  // Handle that we'll get back from Publish.publish() (although publish() is 
  // practically empty as of 05-02-03
  PublicationHandle  m_iPubHandle;
  
  int8_t computeMetric( struct ClusterHead_s *p_pTarget );
  uint8_t computeTimeSince( uint8_t p_uiNow,
                             uint8_t p_uiThen );

  /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init()
  {
    int8_t iCount = 0;

    // Initialize the array of cluster heads to be empty.
    for ( iCount = 0;
          iCount < ESS_MAX_CLUSTER_HEADS;
          iCount++ )
    {
      m_pClusterHeadArray[ iCount ].m_iId = ESS_EMPTY;
    }

    // Use default values for the metrics of cluster head choice.
    m_pMetricArray[ ESS_LOAD_FACTOR_METRIC ] = 2;
    m_pMetricArray[ ESS_NUM_HOPS_METRIC ] = 8;

    // We have no cluster head... yet...
    m_pCurrentClusterHead = NULL;

    // The time is 0 o'clock.
    m_uiNow = 0;

    // Default the value of the cluster head timeout.
    m_uiChTimeout = ESS_CH_TIMEOUT;
    m_uiAdjListPeriod = ESS_ADJ_LIST_PERIOD;

    memset( m_pAttrs,
            0,
            sizeof( Attribute ) * ESS_ATTR_BUFF_SIZE );

    m_iPubHandle = 0;

    // <TODO> perhaps post a task or or something to call Publish.publish()...
    // this is for the long run, for now, we can even decide to omit the call
    // to Publish.publish </TODO> 

    return SUCCESS;
  }


  /**
   * Start things up.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start()
  {
    // We will fire every second to keep out clock fairly granular.
    call Timer.start( TIMER_REPEAT,
                      1000 ); 

    return SUCCESS;
  }

  /**
   * Halt execution of the application.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop()
  {
    return call Timer.stop();
  }

  /**
   * Add or update the dynamic state of a cluster head.
   * 
   * @return Returns <code>SUCCESS</code> if cluster head was successfully
   *         added, or if the cluster head was already present, if its values
   *         were successfully updated.  Returns <code>FAIL</code> neither of
   *         the above.
   **/
  command result_t EssState.addClusterHead( struct ClusterHead_s *p_pClusterHead )
  {
    int8_t iCount = 0;
    result_t tReturn = FAIL;

    // We must have a parameter.
    if ( NULL == p_pClusterHead )
    {
      tReturn = FAIL;
    }
    else
    {
      dbg( DBG_USR1, 
     "addClusterHead: called for id = %d\n", 
     p_pClusterHead->m_iId);
      // We are the only ones who know the real time, so we stamp this cluster head.
      p_pClusterHead->m_iLast = m_uiNow;
      for ( iCount = 0;
            iCount < ESS_MAX_CLUSTER_HEADS;
            iCount++ )
      {
        // If we have seen this cluster ehad before, update its values.
        if ( p_pClusterHead->m_iId == m_pClusterHeadArray[ iCount ].m_iId )
        {
          memcpy( &( m_pClusterHeadArray[ iCount ] ),
                  p_pClusterHead,
                  sizeof( *p_pClusterHead ) );
          // We were successful, and we are done.
          tReturn = SUCCESS;
          break;
        }
      }

      // If we were not able to find this cluster head in our list, it must
      // be "new".
      if ( FAIL == tReturn )
      {
        // Look for an open spot in our array for the newbie.
        for ( iCount = 0;
              iCount < ESS_MAX_CLUSTER_HEADS;
              iCount++ )
        {
          // We found an open spot, so we're putting it in.
          if ( ESS_EMPTY == m_pClusterHeadArray[ iCount ].m_iId )
          {
            memcpy( &( m_pClusterHeadArray[ iCount ] ),
                    p_pClusterHead,
                    sizeof( *p_pClusterHead ) );

            // We were successful, and we're done.
            tReturn = SUCCESS;
            break;
          }
        }
      }
    }

    return tReturn;
  }

  /**
   * Lookup the current cluster head if one has been internally selected.
   * 
   * @return Returns <code>SUCCESS</code> if there is a current cluster head
   *         selected, and returns <code>FAIL</code> if not, or if the input
   *         parameter was NULL.
   **/
  command result_t EssState.getClusterHead( struct ClusterHead_s *p_pOutput )
  {
    result_t tReturn = FAIL;

    // Make sure we have an output variable AND that we have already chosen
    // a cluster head.
    if ( NULL != p_pOutput 
         && NULL != m_pCurrentClusterHead )
    {
      p_pOutput->m_iId = m_pCurrentClusterHead->m_iId;
      p_pOutput->m_iLoad = m_pCurrentClusterHead->m_iLoad;
      p_pOutput->m_iNumHops = m_pCurrentClusterHead->m_iNumHops;
      p_pOutput->m_iLast = m_pCurrentClusterHead->m_iLast;
      tReturn = SUCCESS;
    }

    return tReturn;
  }

  /**
   * Currently a stub that will format a data buffer into a TinyDiffusion message.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t EssComm.send( int8_t p_iType,
                                 int16_t *p_pBuffer,
                                 int16_t p_iBuffLen )
  {
    int16_t iCount = 0;

    m_pAttrs[ 0 ].key = ESS_CLUSTERHEAD_KEY;
    m_pAttrs[ 0 ].op = IS;
    // we haven't yet computed a clusterhead...
    if ( NULL != m_pCurrentClusterHead )
    {
      m_pAttrs[ 0 ].value = m_pCurrentClusterHead->m_iId;
    }
    else
    {
      m_pAttrs[ 0 ].value = 0;
      dbg( DBG_USR1, 
           "EssComm.send(): m_pCurrentClusterHead is NULL(1)!\n" );
    }

    for ( iCount = 0;
          iCount < p_iBuffLen;
          iCount++ )
    {
      // - 2 because we need to add two more attributes: (1) CLASS
      // and (2) ESS_CLUSTERHEAD_KEY; we add the latter and TinyDiffusion adds
      // the former.
      if ( ESS_ATTR_BUFF_SIZE - 2 <= iCount )
      {
        dbg( DBG_USR1, 
             "EssComm.send: invoking sendData(1); CH = %d; attrs:\n", 
             m_pAttrs[0].value);
        prAttArray( DBG_USR1, 
                    TRUE, 
                    m_pAttrs, 
                    iCount + 1 );

        // Mohan's note: remember that the m_iPubHandle doesn't need to be
        // anything meaningful for version 1. of ESS -- Publish.publish()
        // needn't even be called!
        if ( FAIL == call Publish.sendData( m_iPubHandle, 
                    m_pAttrs, 
                    iCount + 1 ) )
        // Note: the "+ 1" above is because of the additional 
        // ESS_CLUSTERHEAD_KEY attribute we have added...
        {
          // for Nido debugging...
          dbg( DBG_ERROR, 
               "EssComm.send: Publish.sendData failed!\n" );
        }

        p_pBuffer = &( p_pBuffer[ iCount ] );
        p_iBuffLen -= iCount;
        iCount = 0;

        // reset the first and second attributes... although we don't really
        // need to...
        m_pAttrs[ 0 ].key = ESS_CLUSTERHEAD_KEY;
        m_pAttrs[ 0 ].op = IS;
        if ( NULL != m_pCurrentClusterHead )
        {
          m_pAttrs[ 0 ].value = m_pCurrentClusterHead->m_iId;
        }
        else
        {
          m_pAttrs[ 0 ].value = 0;
          dbg( DBG_USR1, 
               "EssComm.send(): m_pCurrentClusterHead is NULL(2)!\n" );
        }
      }

      // Note: the "+ 1" above is because of the additional 
      // ESS_CLUSTERHEAD_KEY attribute we have added...
      m_pAttrs[ iCount + 1 ].key = p_iType;
      m_pAttrs[ iCount + 1 ].op = IS;
      m_pAttrs[ iCount + 1 ].value = p_pBuffer[ iCount ];
    }

    if ( iCount > 0 )
    {
      dbg( DBG_USR1, 
           "EssComm.send: invoking sendData(2); CH = %d; attrs:\n", 
           m_pAttrs[0].value );
      prAttArray( DBG_USR1, 
                  TRUE, 
                  m_pAttrs, 
                  iCount + 1 );

      // Note: the "+ 1" above is because of the additional 
      // ESS_CLUSTERHEAD_KEY attribute we have added...
      if ( FAIL == call Publish.sendData( m_iPubHandle, 
            m_pAttrs, 
            iCount + 1 ) )
      {
        // for Nido debugging...
        dbg( DBG_ERROR, 
             "EssComm.send: Publish.sendData failed!\n" );
      }
    }

    return SUCCESS;
  }

  /**
   * Gets the amount of time a cluster head must exceed before being declared
   * overdue.
   * 
   * @return The number of seconds.
   **/
  command uint8_t EssState.getChTimeout( )
  {
    return m_uiChTimeout;
  }

  /**
   * Sets the amount of time before a cluster head is declared overdue.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t EssState.setChTimeout( uint8_t p_uiTimeout )
  {
    m_uiChTimeout = p_uiTimeout;

    return SUCCESS;
  }

  /**
   * Gets the number of seconds in between the transmission of the network
   * adjacency list.
   * 
   * @return The number of seconds.
   **/
  command uint8_t EssState.getAdjListPeriod( )
  {
    return m_uiAdjListPeriod;
  }

  /**
   * Sets the number of seconds in between the transmission of the
   * network adjacency list.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t EssState.setAdjListPeriod( uint8_t p_uiPeriod )
  {
    m_uiAdjListPeriod = p_uiPeriod;

    return SUCCESS;
  }

  /**
   * Resets the current cluster head to nothing, and then begins to examine member array.
   * Iterates over the internal list of cluster heads and evalutes them in 2 ways:
   * 1 - If the cluster head has not been updated recently enough, the cluster head
   *     is presumed to be gone, and is removed.
   * 2 - Each cluster head is evaluted against the current cluster head to see if it
   *     is a better choice.
   * 
   * @return void
   **/
  task void chooseClusterHead( )
  {
    int8_t iCount = 0;

    // Reset our cluster head so we can evaluate it from scratch.
    m_pCurrentClusterHead = NULL;

    for ( iCount = 0;
          iCount < ESS_MAX_CLUSTER_HEADS;
          iCount++ )
    {
      // If we are not at an empty spot in the array...
      if ( ESS_EMPTY != m_pClusterHeadArray[ iCount ].m_iId )
      {
        // Check and see if we need to expire this bad-boy.
        if ( computeTimeSince( m_uiNow,
                               m_pClusterHeadArray[ iCount ].m_iLast ) > m_uiChTimeout )
        {
          dbg( DBG_USR1, 
               "chooseClusterHead: expiring clusterhead : %d\n", 
               m_pClusterHeadArray[ iCount ].m_iId );
          // BAM!
          m_pClusterHeadArray[ iCount ].m_iId = ESS_EMPTY;
        }
        // If we have not chosen a cluster head yet...
        else if ( NULL == m_pCurrentClusterHead )
        {
          // Now we have!  This redundant check saves the memory needed to maintain
          // any state.
          m_pCurrentClusterHead = &( m_pClusterHeadArray[ iCount ] );
        }
        // Otherwise, we compare this cluster head to our current "leader".
        // and update if it's better one...
        else if ( computeMetric( &m_pClusterHeadArray[ iCount ] ) 
                  < computeMetric( m_pCurrentClusterHead ) )
        {
          // If this one gets a lower metric, it's better (less IS more).
          m_pCurrentClusterHead = &( m_pClusterHeadArray[ iCount ] );
        }
      }
    }
  }

  task void sendAdjList( )
  {
    uint8_t uiCount = 0;
    uint8_t uiNumNeighbors = 0;
    uint16_t pAdjList[ ESS_MAX_NEIGHBORS ];
    uint16_t uiGood = 0;

    memset( pAdjList,
            0,
            ( sizeof( uint16_t ) * ESS_MAX_NEIGHBORS ) );

    uiNumNeighbors = call ReadNeighborStore.getNeighbors( pAdjList,
                                                          ESS_MAX_NEIGHBORS );

    for ( uiCount = 0;
          uiCount < uiNumNeighbors;
          uiCount++ )
    {
      if ( ( 0xFFFF != pAdjList[ uiCount ] )
           && ( SUCCESS
                != call ReadNeighborStore.getNeighborMetric16( pAdjList[ uiCount ], 
							                                                 NS_16BIT_LINK_GOODNESS, 
							                                                 &uiGood )
                || NS_GOOD_LINK != uiGood ) )
      {
        pAdjList[ uiCount ] = 0xFFFF;
      }
    }

    for ( uiCount = 0;
          uiCount < uiNumNeighbors;
          uiCount++ )
    {
      if ( 0xFFFF == pAdjList[ uiCount ] )
      {
        if ( ( uiCount + 1 ) < uiNumNeighbors )
        {
          memmove( &( pAdjList[ uiCount ] ),
                   &( pAdjList[ uiCount + 1 ] ),
                   ( uiNumNeighbors - uiCount - 1 ) );
        }

        uiCount--;
        uiNumNeighbors--;
      }
    }

    call EssComm.send( ESS_ADJ_LIST_KEY,
                       pAdjList,
                       uiCount );
  }

  /**
   * Use member variables as weights and computes the internal "value" of
   * the cluster head parameter.
   * 
   * @return Returns <code>SUCCESS</code> if input was not NULL, and returns
   *         <code>FAIL</code> otherwise.
   **/
  int8_t computeMetric( struct ClusterHead_s *p_pTarget )
  {
    int8_t iReturn = 0;

    // Make sure we have an output parameter.
    if ( NULL != p_pTarget )
    {
      // It sure would be nice if motes could divide.  Until this is
      // worked out, we cannot normalize the values.

      // Mohan's note: the division below didn't work because the "/"
      // corresponds to the "DIV" operation on integers -- so if m_iLoad <
      // ESS_DEFAULT_MAX_LOAD_FACTOR, the DIV will always come up with 0.  So,
      // you first multiply by weight and then do a DIV
/*
      iReturn = ( p_pTarget->m_iLoad * m_pMetricArray[ ESS_LOAD_FACTOR_METRIC ] )
                / ESS_DEFAULT_MAX_LOAD_FACTOR );
      iReturn += ( p_pTarget->m_iNumHops * m_pMetricArray[ ESS_NUM_HOPS_METRIC ] )
                 / ESS_DEFAULT_MAX_HOPS );
*/
      iReturn = ( p_pTarget->m_iLoad * ( m_pMetricArray[ ESS_LOAD_FACTOR_METRIC ] ) )
                + ( p_pTarget->m_iNumHops * ( m_pMetricArray[ ESS_NUM_HOPS_METRIC ] ) );
    }

    return iReturn;
  }

  /**
   * Use the current time, and a time stamp and compute the difference (while
   * accounting for rollover).
   * 
   * @return Returns the time difference.
   **/
  uint8_t computeTimeSince( uint8_t p_uiNow,
                             uint8_t p_uiThen )
  {
    uint8_t uiReturn = 0;

    // If we have not rolled over the clock since this reading, subtract.
    if ( p_uiThen <= p_uiNow )
    {
      uiReturn = p_uiNow - p_uiThen;
    }
    // Otherwise, account for rollover.
    else
    {
      uiReturn = ( ( ( uint16_t ) -1 ) - p_uiThen ) + p_uiNow;
    }

    return uiReturn;
  }

  /**
   * Increments the current time, and chooses a cluster head.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Timer.fired( )
  {
    // The time is...
    m_uiNow = m_uiNow + 1;

    // Time to choose a "leader".
    post chooseClusterHead( );

    if ( 0 == ( m_uiNow % m_uiAdjListPeriod ) )
    {
      post sendAdjList( );
    }

    return SUCCESS;
  }
}


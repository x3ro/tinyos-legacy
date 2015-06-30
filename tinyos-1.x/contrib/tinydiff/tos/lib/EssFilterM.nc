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
// $Id: EssFilterM.nc,v 1.1.1.2 2004/03/06 03:01:06 mturon Exp $
//
// $Log: EssFilterM.nc,v $
// Revision 1.1.1.2  2004/03/06 03:01:06  mturon
// Initial import.
//
// Revision 1.1.1.1  2003/06/12 22:11:28  mmysore
// First check-in of TinyDiffusion
//
// Revision 1.5  2003/05/09 21:34:01  eoster
// Added logic to set the cluster head timeout based upon the interest timeout
// value.
//
// Revision 1.4  2003/05/06 04:19:53  mmysore
// Checking in first-cut working versions of EssM, EssFilter and EssTest;
// Small modifications to OnePhasePull
//
// Revision 1.3  2003/05/03 07:48:32  mmysore
// changed receiveMatchingMsg to copy out DiffMsg; task return value fix;
// invocation off addFilter()
//
// Revision 1.2  2003/05/03 00:40:27  mmysore
// A bunch of small integration-related changes to Eric's Ess modules...
//
// Revision 1.1  2003/04/30 22:43:50  eoster
// Initial checkin.
//
////////////////////////////////////////////////////////////////////////////

includes attribute;
includes OnePhasePull;

module EssFilterM
{
  provides
  {
    interface StdControl;
  }
  uses
  {
    interface Filter;
    interface EssState;
  }
}
implementation
{
  enum State_e
  {
    ESS_FILTER_READY = 0,
    ESS_FILTER_RUNNING
  };

  enum State_e m_eState;
  DiffMsg m_sMyDiffMsg;

  task void receiveMsg( );

  command result_t StdControl.init( )
  {
    m_eState = ESS_FILTER_READY;

    return SUCCESS;
  }

  command result_t StdControl.start( )
  {
    Attribute tAttr;
    result_t tResult;

    // Add filter for picking up OnePhasePull Interest packets... 
    tAttr.key = CLASS;
    tAttr.op = EQ;
    tAttr.value = INTEREST;

    tResult = call Filter.addFilter( &tAttr, 1 );

    if ( FAIL == tResult )
    {
      dbg( DBG_ERROR, 
	   "EssFilterM: StdControl.start: Filter.addFilter failed!\n" );
    }
    return tResult;
  }

  command result_t StdControl.stop( )
  {
    return SUCCESS;
  }

  // Mohan's note: the buffer management semantics of receiveMatchingMsg is as
  // follows:  the DiffMsg that is passed *must* be copied out -- and the the
  // pointer *must* not be held onto.  This is made to make things simple in
  // terms of buffer management.  Yes, we could have used the berkeley style
  // "give one, take one" buffer management, but would mean (1) that our
  // entire OPP code uses pointers and the "give one, take one" semantics --
  // which is infeasible in the current time scale... since it would affect
  // pretty much all the code -- sending of interests (subscription), sending
  // of data (publication), reception of interest/data, forwarding of packets
  // to/from filters (2) it's not clear how it would work if a filter
  // generated two packets at once -- then if OPP didn't have two buffers,
  // an "exchange" wouldn't be possible...
  //
  // This problem will go away if we implemented a global "buffer pool"
  // module... but not yet. :-)

  event result_t Filter.receiveMatchingMsg( DiffMsgPtr msg )
  {
    result_t tReturn = SUCCESS;

    if ( ESS_FILTER_READY != m_eState )
    {
      tReturn = FAIL;
    }
    else
    {
      m_eState = ESS_FILTER_RUNNING;
      memcpy ( &m_sMyDiffMsg, msg, sizeof( DiffMsg ) );

      post receiveMsg( );
    }

    return tReturn;
  }

  task void receiveMsg( )
  {
    result_t tReturn = SUCCESS;
    uint8_t uiCount = 0;
    uint8_t uiNumAttrs = 0;
    uint16_t uiExpr = 0;
    Attribute *pAttrs = NULL;
    struct ClusterHead_s tClusterHead;

    tClusterHead.m_iId = -1;
    tClusterHead.m_iLoad = -1;
    tClusterHead.m_iNumHops = -1;
    tClusterHead.m_iLast = -1;

    // Mohan's note: tasks have a "void" return value... so unfortunately, any
    // error cannot be returned directly from task.. So, where there was a
    // "tReturn = FAIL" I've just added dbg()s to aid testing using Nido
    if ( SUCCESS != getSink( &m_sMyDiffMsg,
				&( tClusterHead.m_iId ) ) )
    {
      tReturn = FAIL;
      dbg( DBG_ERROR, 
	   "EssFilterM: receiveMsg: getSink failed!\n" );
    }
    // Mohan's note: m_iNumHops and not m_iId
    // NOTE: also that there's no hopsToSrc field in an interest packet...
    // so we have to calculate numHops indirectly from knowing TTL
    else if ( SUCCESS != getTTL( &m_sMyDiffMsg, 
				 &( tClusterHead.m_iNumHops ) ) )
    {
      tReturn = FAIL;
      dbg( DBG_ERROR, 
	   "EssFilterM: receiveMsg: getHopsToSrc failed!\n" );
    }
    else if ( SUCCESS != getAttrs( &m_sMyDiffMsg,
				   &pAttrs,
				   &uiNumAttrs ) )
    {
      tReturn = FAIL;
      dbg( DBG_ERROR, 
	   "EssFilterM: receiveMsg: getAttrs failed!\n" );
    }
    else if ( NULL == pAttrs )
    {
      tReturn = FAIL;
      dbg( DBG_ERROR, 
	   "EssFilterM: receiveMsg: pAttrs = NULL!\n" );
    }
    else if ( SUCCESS != getExpiration( &m_sMyDiffMsg,
                                        &uiExpr ) )
    {
      tReturn = FAIL;
      dbg( DBG_ERROR,
           "EssFilterM: receiveMsg: unable to get expirtation.\n" );
    }
    else
    {
      tReturn = FAIL;
      for ( uiCount = 0;
	    uiCount < uiNumAttrs;
	    uiCount++ )
      {
        if ( ESS_LOAD_KEY == pAttrs[ uiCount ].key )
        {
          tClusterHead.m_iLoad = pAttrs[ uiCount ].value;
          tReturn = SUCCESS;
          break;
        }
      }

      if ( FAIL == tReturn )
      {
	// do we consder this to be an error, really; if so use DBG_ERROR
	dbg( DBG_USR3, 
	     "EssFilterM: receiveMsg: could not find LOAD key in interest!\n" );
      }
    }

    // convert TTL value to numHops...
    tClusterHead.m_iNumHops = TTL - tClusterHead.m_iNumHops;

    // add clusterhead only if things are ok so far...
    if ( SUCCESS == tReturn )
    {
      call EssState.setChTimeout( uiExpr );
      call EssState.addClusterHead( &tClusterHead );
    }

    tReturn = call Filter.sendMessage( &m_sMyDiffMsg,
				       F_PRIORITY_SEND_TO_NEXT );

    if ( FAIL == tReturn )
    {
      dbg( DBG_ERROR, 
	   "EssFilterM: receiveMsg: Filter.sendMessage FAILED!\n" );
    }

    m_eState = ESS_FILTER_READY;
  }
}

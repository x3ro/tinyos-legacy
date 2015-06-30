
includes MagCenter;
includes Config;

//!! MagHood = CreateNeighborhood( 4, MagCenter, BroadcastBackend, 10 );

// MagReadingAttr and MagPositionAttr are not used as actual attributes.
// They're just defined here so that MagDataAttr can expose them itself.
//!! MagReadingAttr = CreateAttribute( MagReading_t = ERROR_DO_NOT_USE_MagReadingAttrM );
//!! MagPositionAttr = CreateAttribute( MagPosition_t = ERROR_DO_NOT_USE_MagPositionAttrM );

//!! MagDataAttr = CreateAttribute[ MagAttr ]( MagData_t = { reading:{value:0,time:0}, position:{x:0,y:0} } );
//!! MagDataRefl = CreateReflection[ MagRefl ]( MagHood, MagDataAttr, FALSE, 11, 12 );

//!! Config 50 { MagValue_t MagValueThreshold = 32; }
//!! Config 51 { uint16_t MagNeighborRadius = 0x01f0; }
//!! Config 52 { MagTime_t MagReadingTimeout = MAGTIME_TIMEOUT; }
//!! Config 53 { MagTime_t MagReportTimeout = MAGTIME_TIMEOUT; }
//!! Config 56 { MagValue_t MagValueThresholdUpper = 65535u; }

//!! MagStatusCmd = CreateCommand[SystemCommand]( CommandHood, uint8_t, MagStatus_t, 58, 59 );

module MagCenterM
{
  provides interface NeighborhoodManager;
  provides interface StdControl;

  uses interface StdControl as Init[ uint8_t init ];

  uses interface Neighborhood;
  uses interface MagHood_private;
  uses interface MagDataAttr;
  uses interface Valid as MagPositionValid;
  uses interface Valid as MagDataValid;
  uses interface MagDataAttrReflection;
  uses interface MagDataAttrReflectionSnoop;

  uses interface MagCenterReport;
  uses interface TickSensor;

  uses interface MagStatusCmd;

  uses interface EvaderDemoStore;
}
implementation
{
  typedef struct
  {
    nodeID_t id;
    MagData_t data;
    MagTime_t timeout;
  } MagDataWithID_t;

  MagTime_t m_next_report_time;
  MagDataWithID_t m_nan_candidate;

  default command result_t Init.init[ uint8_t init ]() { return SUCCESS; }
  default command result_t Init.start[ uint8_t init ]() { return SUCCESS; }
  default command result_t Init.stop[ uint8_t init ]() { return SUCCESS; }

  command result_t StdControl.init()
  {
    m_next_report_time = G_Config.MagReportTimeout + G_Config.MagReadingTimeout;
    m_nan_candidate.id = 0;
    m_nan_candidate.timeout = 0;

    call Init.init[0]();
    call Init.init[1]();
    call Init.init[2]();
    call Init.init[3]();

    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    call Init.start[0]();
    call Init.start[1]();
    call Init.start[2]();
    call Init.start[3]();

    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    call Init.stop[3]();
    call Init.stop[2]();
    call Init.stop[1]();
    call Init.stop[0]();

    return SUCCESS;
  }

  MagPosition_t getMyPosition()
  {
    MagPosition_t pos = {
      x : call EvaderDemoStore.getPositionX(),
      y : call EvaderDemoStore.getPositionY(),
    };
    return pos;
  }

  // Readings older than the timeout are always worse than readings younger
  // than the timeout.  When older than the timeout, the oldest reading is the
  // worst.  If both are the same age or both are younger than the timeout,
  // the weakest reading is the worst.
  
  // (rv < 0) => (a < b)
  // (rv > 0) => (a > b)
  // (rv == 0) => (a == b)

  int8_t cmpMagData_CSS( const MagData_t* a, const MagData_t* b, MagTime_t timeout )
  {
    // If either reading is older than the timeout ...
    if( (a->reading.time < timeout) || (b->reading.time < timeout) )
    {
      // ... then the strictly oldest reading is the "least" reading.
      if( a->reading.time < b->reading.time ) return -1;
      if( b->reading.time < a->reading.time ) return 1;
    }

    // Otherwise, both readings are within the timeout (or have exactly the
    // same time); the smallest reading value is the "least" reading.
    if( a->reading.value < b->reading.value ) return -1;
    if( b->reading.value < a->reading.value ) return 1;

    // Otherwise, both readings are equal.
    return 0;
  }

  int8_t cmpMagData( const MagData_t* a, const MagData_t* b, MagTime_t timeout )
  {
    int8_t result = cmpMagData_CSS( a, b, timeout );
    dbg( DBG_USR2,
         "PEG: cmpMagData( {x=%3.1f,y=%3.1f,time=%d,value=%d}, {x=%3.1f,y=%3.1f,time=%d,value=%d}, %d ) = %d\n",
	 a->position.x/256.0, a->position.y/256.0, a->reading.time, a->reading.value,
	 b->position.x/256.0, b->position.y/256.0, b->reading.time, b->reading.value,
	 timeout,
	 result
       );
    return result;
  }

  MagDataWithID_t pickWorstNeighbor( MagTime_t timeout )
  {
    uint8_t i = 0;
    MagDataWithID_t worst;
    nodeID_t nodeID;
    worst.id = call Neighborhood.getNeighbor( i++ ); 
    worst.data = call MagDataAttrReflection.get( worst.id );

    while( (nodeID = call Neighborhood.getNeighbor( i++ )) != 0 )
    {
      MagData_t nodeData = call MagDataAttrReflection.get( nodeID );
      if( cmpMagData( &nodeData, &worst.data, timeout ) < 0 )
      {
	worst.id = nodeID;
	worst.data = nodeData;
      }
    }

    return worst;
  }

  task void reportIfLeader()
  {
    MagData_t self = call MagDataAttr.get();
    MagTime_t timeout = self.reading.time - G_Config.MagReadingTimeout;
    MagLeaderReport_t report;
    int i = 0;
    nodeID_t nodeID;

    // override the self position with the evader store
    self.position = getMyPosition();

    // Initialize the message body with our local mag data.
    report.mag_sum = (self.reading.value >= 4096) ? 4096 : self.reading.value;
    report.x_sum = report.mag_sum * self.position.x;
    report.y_sum = report.mag_sum * self.position.y;
    report.num_reporting = 1;

    while( (nodeID = call Neighborhood.getNeighbor(i++)) != 0 )
    {
      // Get a neighbor's reading.
      MagData_t md = call MagDataAttrReflection.get( nodeID );

      // The localization routine returns 65535 for an invalid position.  We
      // currently consider that "valid" throughout as much of the code as
      // possible for the purpose of debugging.  Here in the weighted sum,
      // however, we *must* consider it invalid.
      if( (md.position.x == 65535u) || (md.position.y == 65535u) )
	continue;

      // If the neighbor's reading is greater than our reading, then we are
      // not the leader: free the message buffer and abort.
      if( cmpMagData( &self, &md, timeout ) < 0 )
	return;

      // If the neighbor's reading hasn't timed out, then incorporate it into
      // the leader report message.
      if( md.reading.time >= timeout )
      {
	MagValue_t val = (md.reading.value >= 4096) ? 4096 : md.reading.value;
	report.mag_sum += val;
	report.x_sum += val * (int32_t)md.position.x;
	report.y_sum += val * (int32_t)md.position.y;
	report.num_reporting++;
      }
    }

    //dbg( DBG_USR1, "[MagCenterM] [LeaderReport] [mag_sum=%d] [x_sum=%d] [y_sum=%d] [num_reporting=%d]\n", body->mag_sum, body->x_sum, body->y_sum, body->num_reporting );

    // Send the leader report to all clients in the routing gradient. If the
    // send fails, don't forget to free the message buffer.
    call MagCenterReport.send( report );
  }

  task void addCandidate()
  {
    // If there's room in the neighborhood, just add this candidate.
    // Otherwise, change the worst neighbor to this candidate the candidate
    // is better.

    MagHood_t data = G_default_node_MagHood;
    data.data_MagDataRefl = m_nan_candidate.data;

    if( call Neighborhood.numNeighbors() < MAX_MEMBERS_MagHood )
    {
      call MagHood_private.addID( m_nan_candidate.id, &data );
    }
    else
    {
      MagDataWithID_t worst = pickWorstNeighbor( m_nan_candidate.timeout );
      if( cmpMagData( &m_nan_candidate.data, &worst.data, m_nan_candidate.timeout ) > 0 )
	call MagHood_private.changeID( worst.id, m_nan_candidate.id, &data );
    }

    // set the candidate id to zero to unblock posting this task in updatedNAN
    m_nan_candidate.id = 0;
  }

  uint16_t absdiff( int16_t a, int16_t b )
  {
    return (a<b) ? (b-a) : (a-b);
  }

  uint16_t dist( MagPosition_t a, MagPosition_t b )
  {
    uint16_t dx = absdiff( a.x, b.x );
    uint16_t dy = absdiff( a.y, b.y );
#if 0 //one norm ("diamond")
    uint32_t d = (uint32_t)dx + (uint32_t)dy;
    return (((uint16_t)(d >> 16)) != 0) ? 65535u : d;
#endif
#if 1 //infinity norm ("box")
    return (dx<dy) ? dy : dx;
#endif
  }

  bool withinMagRadius( MagPosition_t a, MagPosition_t b )
  {
    //return dist( a, b ) <= G_Config.MagNeighborRadius ? TRUE : FALSE;
    uint16_t d = dist( a, b );
    bool result = (d <= G_Config.MagNeighborRadius) ? TRUE : FALSE;
    dbg( DBG_USR2, "PEG: dist( {x=%3.1f,y=%3.1f}, {x=%3.1f,y=%3.1f} ) = %3.1f <= %3.1f == %s\n",
	 a.x/256.0, a.y/256.0, b.x/256.0, b.y/256.0, d/256.0,
	 G_Config.MagNeighborRadius/256.0, (result?"TRUE":"FALSE")
       );
    return result;
  }

  command void NeighborhoodManager.prune()
  {
  }

  command void NeighborhoodManager.pushManagementInfo()
  {
    call MagDataAttrReflection.push();
  }

  command void NeighborhoodManager.pullManagementInfo()
  {
    call MagDataAttrReflection.pull( POTENTIAL_NEIGHBORS );
  }

  event void Neighborhood.removingNeighbor( nodeID_t id )
  {
    dbg( DBG_USR1, "MagCenter DIRECTED GRAPH: remove edge %d\n", id );
  }

  event void Neighborhood.addedNeighbor( nodeID_t id )
  {
    dbg( DBG_USR1, "MagCenter DIRECTED GRAPH: add edge %d\n", id );
  }

  // this is the hook by which readings are eventually reported.  See also 
  // MagPositionM and MagReadingM which set the position and reading values
  // of the mag data, respectively.

  event void MagDataAttr.updated()
  {
    if( call MagDataValid.get() == TRUE )
    {
      MagData_t data = call MagDataAttr.get();

      // Hack override the mag data position to use the evader data store.
      // The rest of the code is depending on MagPositionAttrValid to be true,
      // even though is no longer necessary (but it *is* always true because
      // position is set to valid in MagPositionM.StdControl.init or start).
      data.position = getMyPosition();

      if( (data.reading.value >= G_Config.MagValueThreshold)
          && (data.reading.value <= G_Config.MagValueThresholdUpper)
	)
      {
	if( m_next_report_time <= data.reading.time )
	{
	  m_next_report_time = data.reading.time + G_Config.MagReportTimeout;
	  call MagDataAttrReflection.push();
	  post reportIfLeader();
	}
      }
    }
  }

  event void MagDataAttrReflection.updated( nodeID_t id, MagData_t val )
  {
    // override the reported reading time to use local time, not remote time
    MagTime_t now = call TickSensor.get();  // get the current time
    MagData_t newdata = call MagDataAttrReflection.get( id );
    newdata.reading.time = now;
    call MagDataAttrReflection.scribble( id, newdata );

    dbg( DBG_USR1, "[MagData.updated] [id=%d] [value=%d] [time=%d] [x=%d] [y=%d]\n", id, val.reading.value, val.reading.time, val.position.x, val.position.y );
  }

  // UpdatedNAN is what's called when this mote receives a magnetic report from a mote
  // this is currently NOT in this mote's mag neighborhood.  This mean the mote will
  // compare this reported mag reading and position to decide if it should eject another
  // mote from its neighborhood to keep this new one.  The mag neighborhood supports up
  // to 4 neighborhors (the 4 "best" ones).

  event void MagDataAttrReflectionSnoop.updatedNAN( RoutingDestination_t src, MagData_t val )
  {
    if( m_nan_candidate.id == 0 )  // if the candidate isn't in use
    {
      MagTime_t now = call TickSensor.get();  // get the current time
      m_nan_candidate.id = src.address;   // and mark the candidate as in-use

      if( (call MagPositionValid.get() == TRUE)  // and our mag position is good
	  && (now >= G_Config.MagReadingTimeout)  // and the timeout won't overflow
          && (withinMagRadius( (call MagDataAttr.get()).position, val.position ) == TRUE)
	)
      {
	m_nan_candidate.data = val;
	m_nan_candidate.data.reading.time = now; //override the reading time to local time
	m_nan_candidate.timeout = now - G_Config.MagReadingTimeout;
	if( post addCandidate() )
	  return;
      }

      m_nan_candidate.id = 0;
    }
  }

  enum
  {
    MAGSTATUS_STATUS = 0,
    MAGSTATUS_PURGE = 226,
  };

  event void MagStatusCmd.receiveCall( MagStatusCmdArgs_t args )
  {
    uint8_t cmd = args;
    if( cmd == MAGSTATUS_STATUS )
    {
      MagStatus_t status;
      MagData_t selfData = call MagDataAttr.get();
      MagTime_t timeout = selfData.reading.time - G_Config.MagReadingTimeout;
      uint8_t i;

      status.myMag = selfData.reading.value;
      status.timeoutFlags = 0;
      status.worseFlags = 0;

      for( i=0; i<4; i++ )
      {
	nodeID_t nodeID = call Neighborhood.getNeighbor(i);
	status.timeoutFlags <<= 1;
	status.worseFlags <<= 1;
	if( nodeID == INVALID_NEIGHBOR )
	{
	  status.nodes[i].id = 0;
	  status.nodes[i].value = 0;
	  status.timeoutFlags |= 1;
	  status.worseFlags |= 1;
	}
	else
	{
	  MagData_t nodeData = call MagDataAttrReflection.get( nodeID );
	  status.nodes[i].id = nodeID;
	  status.nodes[i].value = nodeData.reading.value;
	  if( nodeData.reading.time < timeout )
	    status.timeoutFlags |= 1;
	  if( cmpMagData( &nodeData, &selfData, timeout ) < 0 )
	    status.worseFlags |= 1;
	}
      }

      call MagStatusCmd.sendReturn( status );
    }
    else if( cmd == MAGSTATUS_PURGE )
    {
      call Neighborhood.purge();
      call MagStatusCmd.dropReturn();
    }
  }

  event void MagStatusCmd.receiveReturn( nodeID_t node, MagStatusCmdReturn_t rets )
  {
  }
}


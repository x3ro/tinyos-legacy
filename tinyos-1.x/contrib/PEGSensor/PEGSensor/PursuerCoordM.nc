
//!! Config 57 { uint8_t QuellPursuerCoord = 0; }

includes ERoute;
includes MagCenter;

module PursuerCoordM
{
  provides interface StdControl;
  provides interface MagCenterReport;

  uses interface RoutingSendByImplicit as MagLeaderToPursuer;
  uses interface RoutingReceive as PursuerToMagLeader;
  uses interface ERoute;
  uses interface MagPositionAttr;
  uses interface MsgBuffers;
}
implementation
{
  uint16_t m_best_crumb_seq_num[ MAX_MOBILE_AGENTS ];

  uint8_t get_index( EREndpoint pursuer_id )
  {
    return pursuer_id - MAX_TREES;
  }

  command result_t StdControl.init()
  {
    // FIXME overflow wrap around bullshit
    uint8_t i;
    for( i=0; i<MAX_MOBILE_AGENTS; i++ )
      m_best_crumb_seq_num[i] = 0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  
  // Receive a mag center report estimate and inform the pursuer of our leader
  // status with the intent of possibly building a crumb trail on the
  // pursuer's behalf.

  command void MagCenterReport.send( MagLeaderReport_t report )
  {
    if( G_Config.QuellPursuerCoord == 0 )
    {
      TOS_MsgPtr msg = call MsgBuffers_alloc();
      if( msg != NULL )
      {
	MagLeaderToPursuer_t* body = (MagLeaderToPursuer_t*)initRoutingMsg( msg, sizeof(MagLeaderToPursuer_t) );
	if( body != NULL )
	{
	  body->leader_pos = call MagPositionAttr.get();
	  body->event_pos.x = report.x_sum / report.mag_sum;
	  body->event_pos.y = report.y_sum / report.mag_sum;
	  body->mag_strength = report.mag_sum / report.num_reporting;
	  if( call MagLeaderToPursuer.send( msg ) == SUCCESS )
	    return;
	}
	call MsgBuffers.free( msg );
      }
    }
  }

  event result_t MagLeaderToPursuer.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call MsgBuffers.free( msg );
    return SUCCESS;
  }

  
  uint16_t absdiff( uint16_t a, uint16_t b )
  {
    return (a<b) ? (b-a) : (a-b);
  }

  event TOS_MsgPtr PursuerToMagLeader.receive( TOS_MsgPtr msg )
  {
    PursuerToMagLeader_t* body = (PursuerToMagLeader_t*)popFromRoutingMsg( msg, sizeof(PursuerToMagLeader_t) );
    if( body != NULL )
    {
      uint8_t n = get_index( body->pursuer_id );
      if( absdiff( body->crumb_seq_num, m_best_crumb_seq_num[n] ) > 1 )
	call ERoute.buildTrail( body->pursuer_id, TREE_LANDMARK, body->crumb_seq_num );
      m_best_crumb_seq_num[n] = body->crumb_seq_num;
    }

    return msg;
  }

  event result_t ERoute.sendDone( EREndpoint dest, uint8_t* data )
  {
    return SUCCESS;
  }

  event result_t ERoute.receive( EREndpoint dest, uint8_t dataLen, uint8_t* data )
  {
    return SUCCESS;
  }

  event void MagPositionAttr.updated()
  {
  }
}


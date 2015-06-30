
//!! Config 118 { uint32_t PursuerCrumbTimeout = 32768L; }
//!! Config 119 { EREndpoint PursuerId = 0; }

includes Config;
includes ERoute;
includes MagCenter;

module PursuerServiceM
{
   provides interface StdControl;
     
   uses interface RoutingReceive as MagLeaderToPursuer;
   uses interface RoutingSendByAddress as PursuerToMagLeader;
   uses interface TickSensor;
   uses interface MsgBuffers;
}
implementation
{
  uint32_t m_next_crumb_time;
  uint16_t m_crumb_seq_num;
  bool m_is_running;
  
  command result_t StdControl.init()
  {
    m_next_crumb_time = 0;
    m_crumb_seq_num = 2;
    m_is_running = FALSE;
    // lower 8 its of tos address matches crumb pursuer id
    G_Config.PursuerId = (EREndpoint)( TOS_LOCAL_ADDRESS & 0xff );
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    m_is_running = TRUE;
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    m_is_running = FALSE;
    return SUCCESS;
  }

  event TOS_MsgPtr MagLeaderToPursuer.receive( TOS_MsgPtr msg_in )
  {
    if( m_is_running == TRUE )
    {
      uint32_t now = call TickSensor.get();
      if( m_next_crumb_time < now )
      {
	TOS_MsgPtr msg_out = call MsgBuffers_alloc();
	if( msg_out != NULL )
	{
	  PursuerToMagLeader_t* body = (PursuerToMagLeader_t*)initRoutingMsg( msg_out, sizeof(PursuerToMagLeader_t) );
	  if( body != NULL )
	  {
	    body->pursuer_id = G_Config.PursuerId;
	    body->crumb_seq_num = m_crumb_seq_num++;
	    body->last_known_pos.x = 0;
	    body->last_known_pos.y = 0;
	    body->flags = 0;
	    if( call PursuerToMagLeader.send( msg_in->ext.origin, msg_out ) == SUCCESS )
	    {
	      m_next_crumb_time = now + G_Config.PursuerCrumbTimeout;
	      return msg_in;
	    }
	  }
	  call MsgBuffers.free( msg_out );
	}
      }
    }
    return msg_in;
  }

  event result_t PursuerToMagLeader.sendDone( TOS_MsgPtr msg, result_t success )
  {
    call MsgBuffers.free( msg );
    return SUCCESS;
  }
}


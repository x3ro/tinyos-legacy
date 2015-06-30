
//!! MulCmd = CreateCommand( AnchorHood, uint16_t, uint16_t, 208, 209 );

includes MulCmd;

module DomulM
{
  provides interface StdControl;
  uses interface MulCmd;
  uses interface Timer;
}
implementation
{
  MulCmdArgs_t m_args;

  command result_t StdControl.init()
  {
    return SUCCESS;
  }
  command result_t StdControl.start()
  {
    call Timer.start( TIMER_REPEAT, 5000 + TOS_LOCAL_ADDRESS * 500 );
    return SUCCESS;
  }
  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    dbg( DBG_USR2, "MulCmd.sendCall( POTENTIAL_NEIGHBORS, %d )\n", TOS_LOCAL_ADDRESS+1 );
    return call MulCmd.sendCall( POTENTIAL_NEIGHBORS, TOS_LOCAL_ADDRESS+1 );
  }

  task void docmd()
  {
    MulCmdReturn_t result = m_args * (TOS_LOCAL_ADDRESS+1);
    dbg( DBG_USR2, "MulCmd.sendReturn( %d )\n", result );
    call MulCmd.sendReturn( result );
  }

  event void MulCmd.receiveCall( MulCmdArgs_t args )
  {
    dbg( DBG_USR2, "MulCmd.receiveCall( %d )\n", args );
    m_args = args;
    post docmd();
  }

  event void MulCmd.receiveReturn( nodeID_t id, MulCmdReturn_t rets )
  {
    dbg( DBG_USR2, "MulCmd.receiveResult( %d, %d )\n", id, rets );
  }
}


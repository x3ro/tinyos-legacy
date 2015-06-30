
module CommandCommM
{
  provides interface CommandComm[ uint8_t comm ];
  uses interface RoutingSendBySimpleImplicit as SendBroadcast;
  uses interface RoutingReceive;
}
implementation
{
  typedef struct
  {
    uint8_t comm;
  } header_t;


  command result_t CommandComm.sendResult[ uint8_t comm ]( TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)pushToRoutingMsg( msg, sizeof(header_t) );

    if( head != NULL )
    {
      head->comm = comm;

      if( call SendBroadcast.send( msg ) == SUCCESS )
	return SUCCESS;

      popFromRoutingMsg( msg, sizeof(header_t) );
    }

    return FAIL;
  }


  event result_t SendBroadcast.sendDone( TOS_MsgPtr msg, result_t success )
  {
    header_t* head = (header_t*)pushToRoutingMsg( msg, sizeof(header_t) );
    if( head != NULL )
      signal CommandComm.sendDone[ head->comm ]( msg, success );
    return SUCCESS;
  }


  event TOS_MsgPtr RoutingReceive.receive( TOS_MsgPtr msg )
  {
    header_t* head = (header_t*)pushToRoutingMsg( msg, sizeof(header_t) );
    if( head != NULL )
      return signal CommandComm.receive[ head->comm ]( msg );
    return msg;
  }


  default event void CommandComm.sendDone[ uint8_t comm ]( TOS_MsgPtr msg, result_t success )
  {
  }

  default event TOS_MsgPtr CommandComm.receive[ uint8_t comm ]( TOS_MsgPtr msg )
  {
    return msg;
  }
}


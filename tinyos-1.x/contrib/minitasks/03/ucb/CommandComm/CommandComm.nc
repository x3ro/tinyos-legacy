
interface CommandComm
{
  event TOS_MsgPtr receiveCommand( TOS_MsgPtr msg );

  command result_t sendResult( TOS_MsgPtr msg );
  event void sendDone( TOS_MsgPtr msg, result_t success );
}


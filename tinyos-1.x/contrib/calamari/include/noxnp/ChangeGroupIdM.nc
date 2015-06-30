
includes ChangeGroupId;

module ChangeGroupIdM
{
  uses interface ReceiveMsg;
  //  uses interface XnpConfig;
}
implementation
{
  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg )
  {
    if( msg->length == sizeof(ChangeGroupId_t) )
    {
      ChangeGroupId_t* body = (ChangeGroupId_t*)(msg->data);
      if( body->address_verify == TOS_LOCAL_ADDRESS )
      {
	TOS_AM_GROUP = body->new_group;
	//	call XnpConfig.saveGroupID();
      }
    }

    return msg;
  }
}



configuration CommandCommC
{
  provides interface CommandComm[ uint8_t comm ];
}
implementation
{
  components CommandCommM
           , RoutingC
	   ;
  
  CommandComm = CommandCommM;

  CommandCommM.SendBroadcast -> RoutingC.SendBySingleBroadcast[ PROTOCOL_COMMANDCOMM_SENDRESULT ];
  CommandCommM.RoutingReceive -> RoutingC.RoutingReceive[ PROTOCOL_COMMANDCOMM_RECEIVECOMMAND ];
}


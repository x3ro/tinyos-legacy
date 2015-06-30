

interface RoutingSendByMobileID {
	command result_t send(RoutingAddress_t  address, TOS_MsgPtr msg);
	//event result_t sendDone(TOS_MsgPtr msg,        result_t success);
}


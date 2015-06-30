

interface RoutingSendByEventSig {
	command result_t send(uint8_t paraEventSignature,TOS_MsgPtr msg);
		event result_t sendDone(TOS_MsgPtr msg,        result_t success);
}



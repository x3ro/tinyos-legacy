
interface Interest {
	command result_t SetBroadcastPeriod(uint16_t paraShort);
	command result_t SetHopsPeriod(uint16_t paraShort);
	command result_t SetInterestSeqNum(uint16_t paraShort);

	command result_t SetPeriodHops(uint16_t paraShort);
	command result_t SetPursuer(uint8_t para);
	
	command result_t SendOneInterest(  uint8_t paraHops);
	
}


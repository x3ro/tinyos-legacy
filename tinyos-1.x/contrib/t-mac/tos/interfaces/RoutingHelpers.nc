interface RoutingHelpers
{
	/* 
	 * Will return a NULL-terminated buffer containing all of our neighbours ids
	 * May not necessarily contain all the neighbours.
	 * Some MAC layers will always return a single NULL item
	 * The calling method is responsible for the free()'ing of the array
	 */
	command uint16_t* getNeighbours();

	/* provides the id of a newly discovered neighbour, to avoid the overhead of 
	 * continually pinging getNeighbours() 
	 */

	event void newNeighbour(uint16_t id);
	
	/* 
	 * These commands override the normal MAC protocol to allow for higher knowledge
	 * further up.
	 */
	
	/*
	 * This will force a MAC into don't sleep mode for msec milliseconds.
	 * Sleep will not happen.
	 */
	command result_t forceNoSleep(uint16_t msec, bool forReply);
	event void noSleepDone(result_t success);

	/*
	 * This finishes a force and returns the MAC
	 * to normal operation
	 */
	 
	command result_t endForce();

	/* length in bytes, creates a time in milliseconds */
	command uint8_t sendTime(uint8_t length);

	/* sent when a forceNoSleep() runs out of time */
	event void forceComplete();
}
	

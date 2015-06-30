/* Like send/recv, but don't wait. no carrier sense, nothing.
 * The *only* case where we don't send immediately is if we're
 * sending something else right now, in which case we fail fast
 * MessageNow *only* works while in force mode (see RoutingHelpers)
 */

interface MessageNow
{
	/* length in bytes, creates a time in milliseconds */
	command uint8_t sendTime(uint8_t length);
	
	command result_t send(TOS_MsgPtr msg, uint8_t length);
	event result_t sendDone(TOS_MsgPtr msg, result_t success);

	event uint8_t receive(const TOS_MsgPtr msg); /* returns the number of RoutingHelpers used msecs to wait for */
}


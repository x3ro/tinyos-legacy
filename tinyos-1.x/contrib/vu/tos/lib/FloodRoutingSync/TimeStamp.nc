/**
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified Jan/05
 */

interface TimeStamp
{
    // note addStamp() and getStamp() work with uint32_t however just
    // getStampSize() bits of these 32 bit vars are defined

	/**
	 * Stores timestamp at a local variable in FloodRoutinSyncM, this timestamp
	 * is consequently added to the routing msg after FloodRouting.send() was 
	 * called. for the memory reasons just one ts value is stored, so send()
	 * command should come soon after addStamp(), otherwise TS gets overwritten
	 * and FloodRouting.send() returns FAIL. RITS post-facto time synchronization. 
	 */
	command result_t addStamp(uint32_t time, uint8_t id);

	/**
	 * Returns timestamp of a block, converted to the local time of the current mote. 
	 * it has to be called from the FloodRoutingSync.receive() event handler.
	 */
	command uint32_t getStamp();
	
	/**
	 * Returns timestamp recorded by receiver when routing msg arrived (local time of receiver).
	 * call this from FloodRoutingSync.receive() event handler. Returns the same value, as
	 * TimeStamping.getStamp() would return if called from ReceiveMsg.receive() event handler
	 */
	command uint32_t getMsgStamp();

	/**
	 * Returns timestamp taken by sender at the time when routing msg was sent (local time of sender).
	 * need to be called from FloodRoutingSync.receive() event handler. This is the value of 
	 * FloodRoutingSyncMsg.timeStamp before it was converted into the offset
	 * of sender and receiver by FloodRoutingSync engine.
	 */
	command uint32_t getMsgSenderStamp();

	/**
	 * returns the size of timestamp in bits
	 */
	command uint8_t getStampSize();
}

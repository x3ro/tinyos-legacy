
interface HPLTimer<hw_precision_t>
{
	command hw_precision_t getTime();
	command void reset();
	async event void wrapped();
	command result_t arm(hw_precision_t timeStamp, uint8_t channel);
	command result_t shortDelay(uint16_t delay, uint8_t channel);
	command result_t stop(uint8_t channel);
	async event void fired(uint8_t channel);
}

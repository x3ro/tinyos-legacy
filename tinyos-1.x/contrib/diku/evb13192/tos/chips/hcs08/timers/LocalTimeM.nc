
module LocalTimeM
{
	provides
	{
		interface LocalTime;
	}
	uses
	{
		interface HPLTimer<uint16_t> as HPLTimer;
	}

}
implementation
{
	uint16_t wrapCounter = 0;
	
	command uint32_t LocalTime.getTime()
	{
		uint32_t ret = 0;
		atomic ret = wrapCounter;
		ret <<= 16;
		ret += call HPLTimer.getTime();
		return ret<<1;
	}
	
	command uint16_t LocalTime.getHigh16()
	{
		uint16_t retval;
		// Most significant bit can't be trusted.
		// This is due to the left shifting in getTime.
		atomic retval = wrapCounter&0x7FFF;
		return retval;
	}
	
	command uint16_t LocalTime.getLow16()
	{
		return call HPLTimer.getTime();
	}
	
	command void LocalTime.reset()
	{
		call HPLTimer.reset();
		atomic wrapCounter = 0;
	}

	command bool LocalTime.isFuture(uint32_t timeStamp)
	{
	
	}
	
	command bool LocalTime.isPast(uint32_t timeStamp)
	{
	
	}

	command uint32_t LocalTime.timeDiff(uint32_t before, uint32_t after)
	{
		uint32_t diff;
		if (before > after) {
			// We have wrapping.
			diff = ~(before-after);
		} else {
			diff = after-before;
		}
		return diff;
	}

	async event void HPLTimer.wrapped()
	{
		atomic wrapCounter++;
	}
	
	async event void HPLTimer.fired(uint8_t channel)
	{
		// Not used in here.
		return;
	}

}

/*
 * Author: Miklos Maroti, Brano Kusy (kusy@isis.vanderbilt.edu)
 * Date last modified: Jan/05
 */
includes Timer;
includes TimeSyncMsg;

module TimeSyncM
{
	provides 
	{
		interface StdControl;
		interface GlobalTime;
		interface TimeSyncInfo;
	}
	uses
	{
		interface FloodRouting;
        interface TimeStamp;
		interface Leds;
        interface DiagMsg;
#ifdef TIMESYNC_SYSTIME
		interface SysTime;
#else
		interface LocalTime;
#endif	
    }
}
implementation
{

	enum {
		MAX_ENTRIES = 8,		// number of entries in the table
		ENTRY_VALID_LIMIT = 4,		// number of entries to become synchronized
        ENTRY_THROWOUT_LIMIT = 15000,
	};

	enum {
		ENTRY_EMPTY = 0,
		ENTRY_FULL = 1,
	};

	typedef struct TableItem
	{
		uint8_t		state;
		uint32_t	localTime;
		int32_t		timeOffset;	// globalTime - localTime
	} TableItem;

	TableItem	table[MAX_ENTRIES];

	enum {
		STATE_IDLE = 0x00,
		STATE_PROCESSING = 0x01,
		STATE_INIT = 0x04,
	};

	uint8_t state;
    uint8_t routingBuffer[ROUTING_BUFFER_SIZE];
    ts_data_token token;
    uint32_t arrival_ts;
	
/*
	We do linear regression from localTime to timeOffset (globalTime - localTime). 
	This way we can keep the slope close to zero (ideally) and represent it 
	as a float with high precision.
		
		timeOffset - offsetAverage = skew * (localTime - localAverage)
		timeOffset = offsetAverage + skew * (localTime - localAverage) 
		globalTime = localTime + offsetAverage + skew * (localTime - localAverage)
*/

	float		skew;
	uint32_t	localAverage;
	int32_t		offsetAverage;
	uint8_t		numEntries;	// the number of full entries in the table

	async command uint32_t GlobalTime.getLocalTime()
	{
#ifdef TIMESYNC_SYSTIME
		return call SysTime.getTime32();
#else
		return call LocalTime.read();
#endif
	}

	async command result_t GlobalTime.getGlobalTime(uint32_t *time)
	{ 
		*time = call GlobalTime.getLocalTime();
		return call GlobalTime.local2Global(time);
	}

	result_t is_synced()
	{
		return numEntries>=ENTRY_VALID_LIMIT;
	}
	
	
	async command result_t GlobalTime.local2Global(uint32_t *time)
	{
		*time += offsetAverage + (int32_t)(skew * (int32_t)(*time - localAverage));
		return is_synced();
	}

	async command result_t GlobalTime.global2Local(uint32_t *time)
	{
		uint32_t approxLocalTime = *time - offsetAverage;
		*time = approxLocalTime - (int32_t)(skew * (int32_t)(approxLocalTime - localAverage));
		return is_synced();
	}
uint8_t numEntriesTable;
	void calculateConversion()
	{
		float newSkew = skew;
		uint32_t newLocalAverage;
		int32_t newOffsetAverage;
		uint8_t newNumEntries;

		int64_t localSum;
		int64_t offsetSum;
		int32_t localSum32;
		int32_t offsetSum32;

		int8_t i;

		for(i = 0; i < MAX_ENTRIES && table[i].state != ENTRY_FULL; ++i)
			;

		if( i >= MAX_ENTRIES )	// table is empty
			return;
/*
		We use a rough approximation first to avoid time overflow errors. The idea 
		is that all times in the table should be relatively close to each other.
*/

		newNumEntries = 1;

/*		newLocalAverage = table[i].localTime;
		newOffsetAverage = table[i].timeOffset;
		localSum = 0;
		offsetSum = 0;
		while( ++i < MAX_ENTRIES )
			if( table[i].state == ENTRY_FULL ) {
				localSum += (int32_t)(table[i].localTime - newLocalAverage);
				offsetSum += (int32_t)(table[i].timeOffset - newOffsetAverage);
				++newNumEntries;
			}

		newLocalAverage += (localSum) / newNumEntries;
		newOffsetAverage += (offsetSum) / newNumEntries;
*/
		newLocalAverage = 0;
		newOffsetAverage = 0;
		localSum32 = table[i].localTime;
		offsetSum32 = table[i].timeOffset;

		while( ++i < MAX_ENTRIES )
			if( table[i].state == ENTRY_FULL ) {
			    if (localSum32 == 0){
            		localSum32 = table[i].localTime;
            		offsetSum32 = table[i].timeOffset;
            	}
            	else{
				    newLocalAverage += (int32_t)(table[i].localTime + localSum32) / numEntriesTable;
				    newOffsetAverage += (int32_t)(table[i].timeOffset + offsetSum32) / numEntriesTable;
				    localSum32 = 0;
			    }
				++newNumEntries;
			}

        if (localSum32 != 0){
            newLocalAverage += localSum32 / numEntriesTable;
            newOffsetAverage += offsetSum32 / numEntriesTable;
        }

		localSum = offsetSum = 0;
		for(i = 0; i < MAX_ENTRIES; ++i)
			if( table[i].state == ENTRY_FULL ) {
				int32_t a = table[i].localTime - newLocalAverage;
				int32_t b = table[i].timeOffset - newOffsetAverage;

    				localSum += (int64_t)a * a;
	    			offsetSum += (int64_t)a * b;
			}

		if( localSum != 0 )
			newSkew = (float)offsetSum  / (float)localSum;

		atomic
		{
			skew = newSkew;
			offsetAverage = newOffsetAverage;
			localAverage = newLocalAverage;
			numEntries = newNumEntries;
		}
	}

	void clearTable()
	{
		int8_t i;
		for(i = 0; i < MAX_ENTRIES; ++i)
			table[i].state = ENTRY_EMPTY;

		atomic numEntries = 0;
	}

#ifdef MEDIAN_ROUTING
    void task processMsg2(){
		call Leds.greenToggle();
        calculateConversion();
		state &= ~STATE_PROCESSING;
    }
    
    event result_t TimeStamp.stampChanged(uint32_t oldt, uint32_t newt, int32_t offset){

		int8_t i;

        if( (state & STATE_PROCESSING) != 0 )
            return FAIL;

		for(i = 0; i < MAX_ENTRIES; ++i) 
			if( table[i].state == ENTRY_FULL && table[i].localTime == oldt){
				atomic table[i].localTime = oldt;
				atomic table[i].timeOffset = offset;
				break;
    		}

		state |= STATE_PROCESSING;
        post processMsg2();
        return SUCCESS;
    }
#endif
	void addNewEntry()
	{
		int8_t i, freeItem = -1, oldestItem = 0;
		uint32_t age, oldestAge=0;
		int32_t timeError;

        numEntriesTable = 0;
		
		// clear table if the received entry is inconsistent
		timeError = arrival_ts;
		
		call GlobalTime.local2Global(&timeError);
		timeError -= token.sendingTime;

		if( is_synced() &&
		   (timeError > ENTRY_THROWOUT_LIMIT || timeError < -ENTRY_THROWOUT_LIMIT) ){
            clearTable();
		}

		for(i = 0; i < MAX_ENTRIES; ++i) {
		    ++numEntriesTable;
			age = arrival_ts - table[i].localTime;

            //logical time error compensation
			if( age >= 0x7FFFFFFFL )
			    table[i].state = ENTRY_EMPTY;

			if( table[i].state == ENTRY_EMPTY ){ 
				--numEntriesTable;
				freeItem = i;
			}

			if( age >= oldestAge && table[i].state == ENTRY_FULL ){
				oldestAge = age;
				oldestItem = i;
			}
		}

		if( freeItem < 0 )
			freeItem = oldestItem;
		else
		    ++numEntriesTable;

		table[freeItem].state = ENTRY_FULL;
		table[freeItem].localTime = arrival_ts;
		table[freeItem].timeOffset = token.sendingTime - arrival_ts;

	}

	void task processMsg()
	{
		addNewEntry();
		calculateConversion();

		state &= ~STATE_PROCESSING;
	}

	event result_t FloodRouting.receive(void *data){
        int8_t age = ((ts_data_token*)data)->seqNum - token.seqNum;
        if (age == 0)
            return FAIL;

		if( (state & STATE_PROCESSING) == 0) {
			arrival_ts = call TimeStamp.getStamp();
            atomic token.seqNum = ((ts_data_token*)data)->seqNum;
			atomic token.sendingTime = ((ts_data_token*)data)->sendingTime;
			state |= STATE_PROCESSING;
			post processMsg();
		}

		return SUCCESS;
	}
	
	command result_t StdControl.init() 
	{ 
		atomic{
			skew = 0.0;
			localAverage = 0;
			offsetAverage = 0;
    		token.seqNum = -1;
		};
        call Leds.init();
		clearTable();

		state = STATE_INIT;

		return SUCCESS;
	}

    command result_t StdControl.start() 
    {
        call FloodRouting.init(sizeof(ts_data_token),1,routingBuffer, sizeof(routingBuffer)); 
        call Leds.redOn();
        return SUCCESS; 
    }

	command result_t StdControl.stop() 
	{
	    call FloodRouting.stop();
		return SUCCESS; 
	}

	async command float     TimeSyncInfo.getSkew() { return skew; }
	async command uint32_t  TimeSyncInfo.getOffset() { return offsetAverage; }
	async command uint32_t  TimeSyncInfo.getSyncPoint() { return localAverage; }
	async command uint8_t   TimeSyncInfo.getSeqNum() { return token.seqNum; }
	async command uint8_t   TimeSyncInfo.getNumEntries() { return numEntries; } 
}

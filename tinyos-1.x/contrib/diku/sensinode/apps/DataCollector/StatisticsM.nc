/* Copyright (c) 2007, Marcus Chang, Klaus Madsen
   All rights reserved.

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer. 

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation 
      and/or other materials provided with the distribution. 

    * Neither the name of the Dept. of Computer Science, University of 
      Copenhagen nor the names of its contributors may be used to endorse or 
      promote products derived from this software without specific prior 
      written permission. 

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
   POSSIBILITY OF SUCH DAMAGE.
*/  

/*
        Author:         Marcus Chang <marcus@diku.dk>
                        Klaus S. Madsen <klaussm@diku.dk>
        Last modified:  March, 2007
*/

module StatisticsM {
	provides {
		interface StdControl;
		interface Statistics[uint8_t id];
		interface StatisticsReader;
	}
	
	uses {
		interface InternalFlash;
		interface Statistics as SelfCounter;
		interface StdOut;
	}

}

implementation {

#define STAT_COUNTERS uniqueCount("Statistic")
#define STAT_NAME_SIZE 8

	struct counter_t {
		char name[STAT_NAME_SIZE];
		uint32_t current;
		bool public;
	};

	enum {
		FLASH_STARTUP_ADDR = 0x0000,
		FLASH_STARTUP_SIZE = 0x04,
	};

	/**************************************************************************
	** Structure array containing the counters' name and value
	**************************************************************************/
	struct counter_t statisticCounters[STAT_COUNTERS];
		
	/**************************************************************************
	** StdControl
	**************************************************************************/
	command result_t StdControl.init()
	{
		call SelfCounter.init("Startup", TRUE);
	
		call SelfCounter.load();
		call SelfCounter.increment();		
		call SelfCounter.save();

		return SUCCESS;
	}
	
	command result_t StdControl.start()
	{
		uint8_t i;
		
		for (i = 0; i < STAT_COUNTERS; i++)
		{
			call Statistics.load[i]();

			// call StdOut.print(statisticCounters[i].name);
			// call StdOut.printHexlong(statisticCounters[i].current);
			// call StdOut.printHex(statisticCounters[i].public);
			// call StdOut.print("\n\r");
		}
				
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		uint8_t i;
		uint32_t tmp[STAT_COUNTERS];

		atomic {		
			for (i = 0; i < STAT_COUNTERS; i++)
			{
				tmp[i] = statisticCounters[i].current;
			}
		}

		call InternalFlash.write( (void*) 0, tmp, STAT_COUNTERS * 4);

		return SUCCESS;
	}

	/**************************************************************************
	** Statistics
	**************************************************************************/
	command void Statistics.init[uint8_t id](const char * name, const bool public) 
	{
		atomic {
			strncpy(statisticCounters[id].name, name, STAT_NAME_SIZE);
			statisticCounters[id].current = 0;
			statisticCounters[id].public = public;
		}
	}

	command void Statistics.load[uint8_t id]() 
	{
		uint32_t tmp;

		call InternalFlash.read( (void*)(id * 4), &tmp, 4);
		
		if (tmp != 0xFFFFFFFF)
			atomic statisticCounters[id].current = tmp;
	}

	command void Statistics.save[uint8_t id]() 
	{
		uint32_t tmp;
		atomic tmp = statisticCounters[id].current;
		call InternalFlash.write( (void*)(id * 4), &tmp, 4);
	}

	command void Statistics.set[uint8_t id](uint32_t value) 
	{
		atomic statisticCounters[id].current = value;
	}

	command uint32_t Statistics.getValue[uint8_t id]() 
	{
		uint32_t res;
		atomic res = statisticCounters[id].current; 
		return res;
	}

	command const char *Statistics.getName[uint8_t id]() 
	{
		const char *res;
		atomic res = statisticCounters[id].name;
		return res;
	}
	
	async command void Statistics.increment[uint8_t id]() 
	{
		atomic statisticCounters[id].current++;
	}

	async command void Statistics.decrement[uint8_t id]() 
	{
		statisticCounters[id].current--;
	}

	async command void Statistics.add[uint8_t id](int32_t value) 
	{
		statisticCounters[id].current += value;
	}

	/**************************************************************************
	** StatisticsReader
	**************************************************************************/
	command result_t StatisticsReader.getStatistics(uint8_t * buffer, uint16_t size) 
	{
		uint16_t i, written = 0;
		
		atomic {
			for (i = 0; i < STAT_COUNTERS; i++)
			{
				if (statisticCounters[i].public)
				{
					memcpy(buffer, &statisticCounters[i].name, STAT_NAME_SIZE);
					buffer += STAT_NAME_SIZE;
					
					*buffer++ = statisticCounters[i].current >> 24;
					*buffer++ = statisticCounters[i].current >> 16;
					*buffer++ = statisticCounters[i].current >> 8;
					*buffer++ = statisticCounters[i].current;
										
					written += STAT_NAME_SIZE + 4;
					
					if (written + STAT_NAME_SIZE + 4 > size)
						break;
				}
			}
		}

		return SUCCESS;
	}

	command uint16_t StatisticsReader.getStatisticsBufferSize()
	{
		return (STAT_COUNTERS * (STAT_NAME_SIZE + 4));
	}

	command uint32_t StatisticsReader.getStatisticByName(char * name) 
	{
		uint8_t id;
		uint32_t retval = 0;

		atomic {		
			// walk through array and compare strings
			for (id = 0; id < STAT_COUNTERS; id++) {
				if (strcmp(name,statisticCounters[id].name) == 0) {
					retval = statisticCounters[id].current;
					break;
				}
			}
		}
	
		return retval;
	}
	
	/**************************************************************************
	** StdOut
	**************************************************************************/
	async event result_t StdOut.get(uint8_t data) {

		return SUCCESS;
	}

}

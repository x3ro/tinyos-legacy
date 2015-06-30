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
	Author:		Marcus Chang <marcus@diku.dk>
			Klaus S. Madsen <klaussm@diku.dk>
	Last modified:	March, 2007
*/

interface StatisticsReader
{
	/////////////////////////////////////////////////////////////////////////
	// Fill the memory space pointed to by buffer with a max. of size bytes
	//
	// @param uint8_t * buffer  Memory buffer to store statistics
	// @param uint16_t size     The size of the buffer in bytes
	// @return result_t         SUCCESS - the called buffer is being filled
	// @return result_t         FAIL - another buffer is being filled
	/////////////////////////////////////////////////////////////////////////
	command result_t getStatistics(uint8_t * buffer, uint16_t size);

	/////////////////////////////////////////////////////////////////////////
	// Find out how much room is needed for a copy of the statistics.
	// 
	// @return uint16_t The required buffer size to hold all stats
	/////////////////////////////////////////////////////////////////////////
	command uint16_t getStatisticsBufferSize();

	/////////////////////////////////////////////////////////////////////////
	// Get a single value 
	//
	// @param char * name       A string matching the name of the counter
	/////////////////////////////////////////////////////////////////////////
	command uint32_t getStatisticByName(char * name);
}

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


module FIFOBufferManagerM {
	provides {
		interface FIFOBufferManager;
	}
}

implementation {

#include "config.h"

	uint8_t next;
	uint8_t realBuffers[COMPRESSION_BUFFERS][FLASH_PAGE_SIZE];
	bool usedBuffers[COMPRESSION_BUFFERS];
	uint8_t * fifoBuffers[COMPRESSION_BUFFERS];
	
	int8_t free, fifo;

	/*************************************************************************/
	command result_t FIFOBufferManager.init()
	{
		uint8_t i;
		
		for (i = 0; i < COMPRESSION_BUFFERS; i++)
		{
			usedBuffers[i] = FALSE;
			fifoBuffers[i] = 0;
		}
		
		fifoBuffers[COMPRESSION_BUFFERS] = 0;
		next = 0;
		
		free = COMPRESSION_BUFFERS;
		fifo = 0;
		
		return SUCCESS;
	}

	/*************************************************************************/
	command uint8_t * FIFOBufferManager.getFreeBuffer()
	{
		uint8_t i;
		uint8_t * res = NULL;

		/* try to allocate space */
		for (i = 0; i < COMPRESSION_BUFFERS; i++) 
		{
			if (usedBuffers[i] == FALSE) 
			{
				usedBuffers[i] = TRUE;
				res = realBuffers[i];
				
				memset(res, 0, FLASH_PAGE_SIZE);

				return res;
			}
		}

		return 0;
	}

	/*************************************************************************/
	command result_t FIFOBufferManager.releaseBuffer(uint8_t * ptr)
	{
		uint8_t i;

		/* find page in buffer */
		for (i = 0; i < COMPRESSION_BUFFERS; i++) 
		{
			if (realBuffers[i] == ptr) 
			{
				usedBuffers[i] = FALSE;

				return SUCCESS;
			}
		}

		return FAIL;
	}

	/*************************************************************************/
	command result_t FIFOBufferManager.putFIFO(uint8_t * buffer)
	{	
		uint8_t i, idx;
		
		for (i = 0; i < COMPRESSION_BUFFERS; i++)
		{
			idx = (next + i) % COMPRESSION_BUFFERS;
			
			if (fifoBuffers[idx] == 0)
			{
				fifoBuffers[idx] = buffer;
				
				return SUCCESS;
			}
		}

		return FAIL;
	}

	/*************************************************************************/
	command result_t FIFOBufferManager.putFrontFIFO(uint8_t * buffer)
	{	
		uint8_t try_next;
		
		try_next = next;

		if (try_next == 0)
			try_next = COMPRESSION_BUFFERS - 1;
		else
			try_next--;
			
		if (fifoBuffers[try_next] == 0)
		{
			next = try_next;
			fifoBuffers[next] = buffer;
			
			return SUCCESS;
		}

		return FAIL;
	}

	/*************************************************************************/
	command uint8_t * FIFOBufferManager.getFIFO()
	{
		uint8_t * res;
		
		res = fifoBuffers[next];

		if (res == 0)
		{
			return 0;
		}

		/* */			
		fifoBuffers[next] = 0;
		next++;

		if (next == COMPRESSION_BUFFERS)
			next = 0;

		return res;
	}

}

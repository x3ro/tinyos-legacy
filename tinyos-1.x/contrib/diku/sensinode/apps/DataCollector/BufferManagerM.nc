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


module BufferManagerM {
	provides {
		interface BufferManager;
	}
}

implementation {

#define BUFFERS 6

	page_t realBuffers[BUFFERS];
	bool usedBuffers[BUFFERS];

	command void BufferManager.clear()
	{
		uint8_t i;
		
		for (i = 0; i < BUFFERS; i++) 
		{
			realBuffers[i].pageNumber = 0xFFFF;
			realBuffers[i].status = 0;
			realBuffers[i].crc = 0;
			
			usedBuffers[i] = FALSE;
		}
	}

	command page_t * BufferManager.get(uint16_t page)
	{
		uint8_t i;
		page_t * res = NULL;

		/* see if page is already in buffer */
		for (i = 0; i < BUFFERS; i++) 
		{
			if (realBuffers[i].pageNumber == page) 
			{
				return &realBuffers[i];
			}
		}

		/* page not in buffer - try to allocate space */
		for (i = 0; i < BUFFERS; i++) 
		{
			if (usedBuffers[i] == FALSE) 
			{
				usedBuffers[i] = TRUE;
				res = &realBuffers[i];
				res->pageNumber = page;

				return res;
			}
		}

		return 0;
	}

	command result_t BufferManager.free(uint16_t page)
	{
		uint8_t i;

		/* find page in buffer */
		for (i = 0; i < BUFFERS; i++) 
		{
			if (realBuffers[i].pageNumber == page) 
			{
				usedBuffers[i] = FALSE;

				realBuffers[i].pageNumber = 0xFFFF;
				realBuffers[i].status = 0;
				realBuffers[i].crc = 0;

				return SUCCESS;
			}
		}

		return FAIL;
	}

	command uint8_t BufferManager.freeBuffers()
	{
		uint8_t i;
		uint8_t res = 0;

		for (i = 0; i < BUFFERS; i++) 
		{
			if (usedBuffers[i] == FALSE)
				res++;
		}

		return res;
	}

}

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

module DatasetManagerM {
	provides {
		interface DatasetManager;
	}
	uses {
		interface BufferManager;
		interface StdOut;
	}
}

implementation {

#define DATASET_SIZE 256
#define PREVIOUS_SETS_CACHE 10

	/* current dataset status */
	uint8_t datastruct[DATASET_SIZE];

	bool isInSet(uint16_t page);
	void putInSet(uint16_t page);
	void removeFromSet(uint16_t page);
	void clearSet();

	/* previous completed datasets */
	dataset_t previousSets[PREVIOUS_SETS_CACHE];
	uint8_t previousPtr;

	/* used for joining fragments */
	dataset_t currentSet;
	uint8_t currentPageBuffer[256];
	uint8_t * currentPageBufferPtr;
	uint16_t currentPageNumber; 
	uint8_t expectedPageFragment;

	/**************************************************************************
	** 
	**************************************************************************/
	command void DatasetManager.clear()
	{
		currentPageBufferPtr = currentPageBuffer;

		currentSet.source = 0xFFFF;
		currentSet.number = 0xFFFFFFFF;
		currentSet.size = 0;

		clearSet();
		call BufferManager.clear();

		call StdOut.print("DBM - free buffers: ");
		call StdOut.printHex(call BufferManager.freeBuffers());
		call StdOut.print("\r\n");			
	}
		
	/**************************************************************************
	** 
	**************************************************************************/
	command void DatasetManager.insertFragment(dataset_t * set, fragment_t * part)
	{
		uint16_t i;
		page_t * bufferPage = 0;

		/* consistency check */
		if ( (set->source != currentSet.source) || (set->number != currentSet.number) )
			return;
		
		/* get buffer */
		bufferPage = call BufferManager.get(part->pageNumber);

		/* buffer allocation successfull */	
		if (bufferPage != 0)
		{
			/* copy page fragment to buffer */
			for (i = 0; i < part->length; i++)
			{
				bufferPage->page[i + part->start] = part->pagePtr[i];
			}

			/* flag current fragment as received */
			bufferPage->status |= (0x01 << (part->fragment - 1));

			//call StdOut.print("MAN - page status: ");
			//call StdOut.printHexword(bufferPage->pageNumber);
			//call StdOut.printHex(bufferPage->status);
			//call StdOut.printHex( (0xFF >> (8 - part->total)) );
			//call StdOut.print("\r\n");			
			//call StdOut.print("\r\n");			

			/* all fragments received */
			if ( bufferPage->status == (0xFF >> (8 - part->total)) )
			{
				putInSet(part->pageNumber);

				call BufferManager.free(part->pageNumber);

				//for (i = 0; i < 256; i++)
				//{
				//		call StdOut.printHex(bufferPage->page[i]);
				//}
				//call StdOut.print("\r\n");			

				call StdOut.print("Page complete: ");			
				call StdOut.printHex(bufferPage->page[0]);
				call StdOut.printHex(bufferPage->page[1]);
				call StdOut.print("\r\n");			

				call StdOut.print("MAN - free buffers: ");
				call StdOut.printHex(call BufferManager.freeBuffers());
				call StdOut.print("\r\n");			
			}			
		}	
		else
		/* all buffers full - use running fragment collection */
		{
			/* first fragment of page or fragment was expected */
			if ((part->fragment == 1) || 
				(part->fragment == expectedPageFragment && currentPageNumber == part->pageNumber))
			{
				/* reset current page number */
				currentPageNumber = part->pageNumber;

				/* copy page fragment to buffer */
				for (i = 0; i < part->length; i++)
				{
					currentPageBufferPtr[i + part->start] = part->pagePtr[i];
				}

				/* all fragments in buffer */
				if (part->fragment == part->total)
				{
					expectedPageFragment = 1;

					putInSet(part->pageNumber);

					//for (i = 0; i < 256; i++)
					//{
					//	call StdOut.printHex(currentPageBufferPtr[i]);
					//}
					//call StdOut.print("\r\n");			

					call StdOut.print("Page complete: ");			
					call StdOut.printHex(bufferPage->page[0]);
					call StdOut.printHex(bufferPage->page[1]);
					call StdOut.print("\r\n");			

					call StdOut.print("MAN - free buffers: ");
					call StdOut.printHex(call BufferManager.freeBuffers());
					call StdOut.print("\r\n");			
				}
				else
					/* increment expected page fragment */
					expectedPageFragment = part->fragment + 1;

			}
		}
	}

	/**************************************************************************
	** 
	**************************************************************************/
	command void DatasetManager.checkDataset(dataset_t * set, intervals_t * list, uint8_t * statistics)
	{
		uint8_t size;
		uint32_t tmp;
		
		uint16_t i;
		bool start = TRUE;

		list->length = 0;

		size = statistics[0];
		for (i = 1; i < size; i += 12)
		{
			call StdOut.print(&(statistics[i]));
			call StdOut.print(" ");
			tmp = statistics[i + 8];
			tmp = (tmp << 8) + statistics[i + 9];
			tmp = (tmp << 8) + statistics[i + 10];
			tmp = (tmp << 8) + statistics[i + 11];
			call StdOut.printHexlong(tmp);
			call StdOut.print("\n\r");
		}

		/* check if dataset is different than the current one */
		if ( (set->source != currentSet.source) || (set->number != currentSet.number) )
		{
			/* check if dataset is in cache */
			for (i = 0; i < PREVIOUS_SETS_CACHE; i++)
			{
				/* dataset found -> complete */
				if ( (set->source == previousSets[i].source) && (set->number == previousSets[i].number) )
				{
					return;
				}
			}
			
			/* clear dataset */
			call DatasetManager.clear();
			
			/* set new set as current */
			currentSet.source = set->source;
			currentSet.number = set->number;
			currentSet.size = set->size;

			/* set interval to entire set */
			list->length = 1;
			list->intervalPtr[0] = set->size - 1;
			
			return;
		}

		/* step through pages in set */		
		for (i = 0; i < set->size; i++)
		{
			if (start)
			{
				/* find start */
				if (!isInSet(i))
				{
					list->length++;
					list->intervalPtr[list->length-1] = i;
					
					start = FALSE;
				}
			}
			else
			{	
				/* find end */
				if (isInSet(i))
				{
					list->intervalPtr[list->length-1] = 
									(list->intervalPtr[list->length-1] << 16) + (i - 1);
										
					/* interval buffer full? */
					if (list->length == list->max)
						return;

					/* restart search */
					start = TRUE;
				} 
			}
		}

		/* check if end was ever found */
		if (!start)
			list->intervalPtr[list->length-1] = 
							(list->intervalPtr[list->length-1] << 16) + (set->size - 1);

		/* dataset complete */
		if (list->length == 0)
		{
			/* put set information in cache */
			previousSets[previousPtr].source = set->source;
			previousSets[previousPtr].number = set->number;
			previousSets[previousPtr].size = set->size;
			
			previousPtr = (previousPtr + 1) % PREVIOUS_SETS_CACHE;
		}
	
		return;
	}

	/**************************************************************************
	** Internal functions
	**************************************************************************/
	bool isInSet(uint16_t page)
	{
		uint8_t bitIndex, byte, bit;
		uint16_t byteIndex;
		
		byteIndex = page >> 3;
		bitIndex = page & 0x0007;
		
		byte = datastruct[byteIndex];
		
		bit = byte & (0x01 << bitIndex);

		return bit;
	}

	void putInSet(uint16_t page)
	{
		uint8_t bitIndex;
		uint16_t byteIndex;
		
		byteIndex = page >> 3;
		bitIndex = page & 0x0007;
				
		datastruct[byteIndex] |= (0x01 << bitIndex);

	}
	
	void removeFromSet(uint16_t page)
	{
		uint8_t bitIndex;
		uint16_t byteIndex;
		
		byteIndex = page >> 3;
		bitIndex = page & 0x0007;
					
		datastruct[byteIndex] &= ~(0x01 << bitIndex);
	
	}

	void clearSet()
	{
		uint16_t i;
		
		for (i = 0; i < DATASET_SIZE; i++)
		{
			datastruct[i] = 0;
		}
	}
	
	/**************************************************************************
	** StdOut
	**************************************************************************/
	async event result_t StdOut.get(uint8_t data) {

		return SUCCESS;
	}
	
}

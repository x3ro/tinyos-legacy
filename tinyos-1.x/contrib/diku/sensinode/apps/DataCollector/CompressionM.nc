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



module CompressionM {
	provides {
		interface StdControl as CompressionControl;
		interface Compression;
	}

	uses {
		interface FlashManagerWriter;
		interface FIFOBufferManager;
		interface StdOut;
	}
}

implementation {

#include "config.h"

	bool lossyCompression = FALSE, lossyInProgress = FALSE;

	uint16_t average[3][COMPRESSION_SAMPLES_IN_AVERAGE];
	uint8_t averageIndex;
	
	uint16_t last_x = 0, last_y = 0, last_z = 0;
	
	uint8_t * bufferPtr, * bufferPos;

	task void writeFifoToFlash();
	bool postWriteTask = FALSE, writeTaskInProgress = FALSE;

	uint8_t find_incommon_bits(uint16_t x, uint16_t y, uint16_t z);
	void write_sample_to_buffer(uint16_t x, uint16_t y, uint16_t z, uint8_t flag, uint8_t size);

	/**************************************************************************
	** CompressionControl
	**************************************************************************/
	command result_t CompressionControl.init() 
	{
		call FIFOBufferManager.init();
				
		averageIndex = 0;
		bufferPtr = 0;
		bufferPos = 0;

		return SUCCESS;
	}

	command result_t CompressionControl.start() 
	{
		return SUCCESS;
	}

	command result_t CompressionControl.stop() 
	{
		return SUCCESS;
	}


	/**************************************************************************
	** Compresssion
	**************************************************************************/
	command result_t Compression.insertData(uint16_t x, uint16_t y, uint16_t z, uint32_t stamp) 
	{
        uint8_t errors_detected = 0;
		uint8_t i, this_size, this_average = 0;
		uint16_t this_x, this_y, this_z;
		uint32_t sum_x = 0, sum_y = 0, sum_z = 0;

		/* store local copy */
		this_x = x;
		this_y = y;
		this_z = z;

		/* perform lossy compression when flash is stretched */		
		if (lossyInProgress || lossyCompression)
		{
			/* store value for later averaging */
			average[0][averageIndex] = this_x;
			average[1][averageIndex] = this_y;
			average[2][averageIndex] = this_z;
			averageIndex++;

			/* if this is not the last sample in average, return */			
			if (averageIndex != COMPRESSION_SAMPLES_IN_AVERAGE)
			{
				lossyInProgress = TRUE;

				return SUCCESS;

			} else {

				/* reset lossy compression */
				lossyInProgress = FALSE;
				averageIndex = 0;
				
				/* calculate average */
                /* errornous samples are discarded and not included in average */
				for (i = 0; i < COMPRESSION_SAMPLES_IN_AVERAGE; i++)
				{
                    /* check if any of the samples are errornous */
                    /* and keep count of discarded samples       */
                    if ((average[0][i] == 0xFFFF) 
                     && (average[1][i] == 0xFFFF) 
                     && (average[2][i] == 0xFFFF))
                    {
                        errors_detected++;
                    } 
                    else {
    					sum_x += average[0][i];
    					sum_y += average[1][i];
    					sum_z += average[2][i];
                    }
				}

                /* set averages as working copy */                
                this_x = sum_x / (COMPRESSION_SAMPLES_IN_AVERAGE - errors_detected);
                this_y = sum_y / (COMPRESSION_SAMPLES_IN_AVERAGE - errors_detected);
                this_z = sum_z / (COMPRESSION_SAMPLES_IN_AVERAGE - errors_detected);

                /* do base-10 rounding */
                if ( ((sum_x * 10) / (COMPRESSION_SAMPLES_IN_AVERAGE - errors_detected)) % 10 >= 5)
                    this_x += 1;

                if ( ((sum_y * 10) / (COMPRESSION_SAMPLES_IN_AVERAGE - errors_detected)) % 10 >= 5)
                    this_y += 1;

                if ( ((sum_z * 10) / (COMPRESSION_SAMPLES_IN_AVERAGE - errors_detected)) % 10 >= 5)
                    this_z += 1;

				/* mark this sample as being an average */				
				this_average = 1;
			}
		}

		/* find how many bits that have been changed */
        this_size = find_incommon_bits(x, y, z);

		/* currently holding a buffer page ? */
		if (bufferPtr != 0)
		{
		
			/* holding buffer page - enough room for this sample? */
			if (this_size <= (FLASH_PAGE_SIZE - (bufferPos - bufferPtr)))
			{

				/* enough room in buffer - write sample and return call */
				write_sample_to_buffer(this_x, this_y, this_z, this_average, this_size);

				return SUCCESS;
			} else {

				/* not enough room - send page to FIFO */				
				call FIFOBufferManager.putFIFO(bufferPtr);

				/* post write task if not already posted */
				if (!writeTaskInProgress)
				{
					writeTaskInProgress = TRUE;
					post writeFifoToFlash();
				}
			}
		}
		
		/* currently not holding a buffer page - so get one */
		bufferPtr = call FIFOBufferManager.getFreeBuffer();
			
		/* was buffer allocation not successful? - then panic */
		if (bufferPtr == 0)
		{
			/* no more space to store samples */
			/* possible action: stop sampling */
			/* possible action: raise alarm   */
			/* possible action: keep spamming */
			
			/* post write task if not already posted */
//			if (!writeTaskInProgress)
//			{
//				writeTaskInProgress = TRUE;
//				post writeFifoToFlash();
//			}
			
			return FAIL;
		} else {

			/* buffer allocated - initialize new page - insert timestamp */
			bufferPos = bufferPtr;	
			*bufferPos++ = stamp >> 24;
			*bufferPos++ = stamp >> 16;
			*bufferPos++ = stamp >> 8;
			*bufferPos++ = stamp;
			
			/* force first data sample to be written fully to buffer */
			this_size = 5;

			/* write data to buffer */
			write_sample_to_buffer(this_x, this_y, this_z, this_average, this_size);

			return SUCCESS;
		}
		
	}

	task void writeFifoToFlash()
	{
		result_t res;
		uint8_t * pagePtr;

		/* get next page from FIFO */		
		pagePtr = call FIFOBufferManager.getFIFO();

		/* page available? */		
		if (pagePtr == 0)
		{
			/* no more pages in FIFO - do not repost write task */
			writeTaskInProgress = FALSE;
			return;
		}

		/* write page to flash */
		res = call FlashManagerWriter.writePage(pagePtr);
			
		/* write failed? - flash either full or already writing */
		if (res == FAIL)
		{
			/* set task to be reposted when either writepagedone or status is signaled */
			postWriteTask = TRUE;

			/* put page back in FIFO, but re-insert at old place in front */
			call FIFOBufferManager.putFrontFIFO(pagePtr);

			writeTaskInProgress = FALSE;
		} else {
    		/* repost task until either flash is full or fifo is empty */
    		post writeFifoToFlash();
        }
	}

	/**************************************************************************
	** FlashManagerWriter
	**************************************************************************/
	event void FlashManagerWriter.writePageDone(uint8_t * pagePtr)
	{
		call StdOut.print("COMP: writepageDone: ");
		call StdOut.printHexword((uint16_t) pagePtr);
		call StdOut.print("\n\r");

		/* buffer successfully written to flash - release buffer */
		call FIFOBufferManager.releaseBuffer(pagePtr);

		/* FIFO contains pages - post write task */
		if (postWriteTask && !writeTaskInProgress)
		{
			postWriteTask = FALSE;
			writeTaskInProgress = TRUE;
			post writeFifoToFlash();
		}

		return;
	}

	event void FlashManagerWriter.status(uint16_t pages_used, uint16_t pages_left) 
	{
		call StdOut.print("COMP: status: ");
		call StdOut.printHexword(pages_used);
		call StdOut.print(" ");
		call StdOut.printHexword(pages_left);
		call StdOut.print("\n\r");

		/* determing from the flash status if lossy compression is needed */
		if (pages_left < COMPRESSION_LOSSY_LIMIT)
			lossyCompression = TRUE;
		else
			lossyCompression = FALSE;

		/* if FIFO contains pages and there are free space in flash - post write task */			
		if (pages_left > 0 && postWriteTask && !writeTaskInProgress)
		{
			postWriteTask = FALSE;
			writeTaskInProgress = TRUE;
			post writeFifoToFlash();
		}

		return;
	}

	/**************************************************************************
	** Helper functions
	**************************************************************************/

    uint8_t find_incommon_bits(uint16_t x, uint16_t y, uint16_t z)
	{
		uint8_t res;
        int16_t diff_x, diff_y, diff_z;

        /* calculate difference between this dataset and the previous */
        diff_x = last_x - x;
        diff_y = last_y - y;
        diff_z = last_z - z;
				
		/* 4 bit signed => [-8;7] */
		if ( ((-8 <= diff_x) && (diff_x <= 7)) 
		  && ((-8 <= diff_y) && (diff_y <= 7))
		  && ((-8 <= diff_z) && (diff_z <= 7)) )
			
			res = 2;

		/* 7 bit signed => [-64;63] */
        else if ( ((-64 <= diff_x) && (diff_x <= 63)) 
               && ((-64 <= diff_y) && (diff_y <= 63))
               && ((-64 <= diff_z) && (diff_z <= 63)) )

			res = 3;
		
		/* 9 bit signed => [-256;255] */
        else if ( ((-256 <= diff_x) && (diff_x <= 255)) 
               && ((-256 <= diff_y) && (diff_y <= 255))
               && ((-256 <= diff_z) && (diff_z <= 255)) )

			res = 4;
		
		/* 12 bit - default */
		else
			res = 5;

		return res;
	}

	void write_sample_to_buffer(uint16_t x, uint16_t y, uint16_t z, uint8_t flag, uint8_t size)
	{
        int16_t diff_x, diff_y, diff_z;

        /* calculate difference between this dataset and the previous */
        diff_x = last_x - x;
        diff_y = last_y - y;
        diff_z = last_z - z;

		/* switch/case between the four different compression modes */
		switch(size) 
		{
            /* difference less than 4 bits - store difference */
			case 2:
				*bufferPos++ = 0xC0 
							 | (flag << 5) 
							 | (diff_x & 0x000F) << 1 
                             | (diff_y & 0x000F) >> 3;

                *bufferPos++ = (diff_y & 0x000F) << 5
                             | (diff_z & 0x000F) << 1;
				
				break;

            /* difference less than 7 bits - store difference */
			case 3:
				*bufferPos++ = 0x80 
							 | (flag << 5) 
                             | (diff_x & 0x007F) >> 2;
							 
                *bufferPos++ = (diff_x & 0x007F) << 6
                             | (diff_y & 0x007F) >> 1;

                *bufferPos++ = (diff_y & 0x007F) << 7
                             | (diff_z & 0x007F);

				break;

            /* difference less than 9 bits - store difference */
			case 4:
				*bufferPos++ = 0x40 
							 | (flag << 5) 
                             | (diff_x & 0x01FF) >> 4;
							 
                *bufferPos++ = (diff_x & 0x01FF) << 4
                             | (diff_y & 0x01FF) >> 5;

                *bufferPos++ = (diff_y & 0x01FF) << 3
                             | (diff_z & 0x01FF) >> 6;

                *bufferPos++ = (diff_z & 0x01FF) << 2;

				break;

            /* difference more than 9 bits - store original */
			case 5:
				*bufferPos++ = 0x00 
							 | (flag << 5) 
							 | (x & 0x0FFF) >> 7;
							 
				*bufferPos++ = (x & 0x0FFF) << 1
							 | (y & 0x0FFF) >> 11;

				*bufferPos++ = (y & 0x0FFF) >> 3;

				*bufferPos++ = (y & 0x0FFF) << 5
							 | (z & 0x0FFF) >> 7;

				*bufferPos++ = (z & 0x0FFF) << 1;

				break;
			default:
				break;
		}

        /* update values for next pass-through */
        last_x = x;
        last_y = y;
        last_z = z;
	}
	
    /**************************************************************************
    ** StdOut
    **************************************************************************/
    async event result_t StdOut.get(uint8_t data) 
    {
        return SUCCESS;
    }

}

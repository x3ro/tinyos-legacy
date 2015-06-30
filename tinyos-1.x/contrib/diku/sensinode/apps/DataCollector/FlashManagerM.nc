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


module FlashManagerM {
	provides {
		interface StdControl as FlashManagerControl;
		interface FlashManagerWriter;
		interface FlashManagerReader;
	}

	uses {
		interface StdControl as FlashControl;
		interface FlashAccess;
		interface ProtocolStarter;
        interface Timer;
		interface StdOut;
	}
}

implementation {

#include "config.h"

#define TIME_OFFLOAD_RETRY 2*60*1000UL

	// Flash state. This needs to be kept during reboots.
	int16_t flash_head;
	uint16_t flash_tail;

	// flash-boundries
	uint16_t flash_start, flash_end;
    uint16_t flash_size;

	bool writePageInProgress = FALSE;
	bool readPageInProgress = FALSE;
	bool clearSectorInProgress = FALSE;

	task void pageReadyTask();
	task void writePageTask();
	task void readPageTask();

	uint16_t clearSectorStart, clearSectorEnd;
	task void clearSectorTask();

	bool inc_head();
	void inc_tail(uint16_t acked_pages);
	uint16_t used_pages();
	uint16_t free_pages();

	uint16_t threshold_used_pages, threshold_previous_increment, threshold_flash_pages;

	/**************************************************************************
	** FlashManagerControl
	**************************************************************************/
	command result_t FlashManagerControl.init() {
		
		/* set flash-boundries */
		flash_start = call FlashAccess.firstUsablePage();
		flash_end = call FlashAccess.lastUsablePage();
                        
		// Set flash_head = -1 to indicate empty flash
		flash_head = -1;
		flash_tail = flash_start;
        flash_size = flash_end - flash_start + 1;

		/* initiate offload when this threshold has been reached */
        /* use a different value at startup to facilitate deployment */
        threshold_used_pages = CRITICAL_PAGE_LIMIT_STARTUP;
        threshold_previous_increment = CRITICAL_PAGE_LIMIT_STARTUP;
		threshold_flash_pages = flash_end - flash_start + 1;

		return SUCCESS;
	}

	command result_t FlashManagerControl.start() 
	{
		/* cascading erase of all sectors */
		clearSectorStart = flash_start & 0xFF00;
		clearSectorEnd = clearSectorStart;

		clearSectorInProgress = TRUE;
		post clearSectorTask();
	
		return SUCCESS;
	}

	command result_t FlashManagerControl.stop() {

		return SUCCESS;
	}



	/**************************************************************************
	** FlashManagerWriter
	**************************************************************************/
	command result_t FlashManagerWriter.writePage(uint8_t * pagePtr) {

        if (writePageInProgress || clearSectorInProgress)
		{
			call StdOut.print("FLASH: Error - flash is busy!\n\r");

			return FAIL;
		}

		/* Find next available page in flash */
		if (inc_head()) {
			call StdOut.print("FLASH: Writing Page: ");
			call StdOut.printHexword(flash_head);
			call StdOut.print("\r\n");

			/* block other calls */
			writePageInProgress = TRUE;

            /* Save data in flash */
            call FlashAccess.write(flash_head, pagePtr);

		} else {

			/* Flash memory full - cannot write page */
			call StdOut.print("FLASH: Error! - flash full\r\n");
			
			return FAIL;
		}

		return SUCCESS;
	}
	
	event void FlashAccess.writeDone(uint16_t page_no, void *page)
	{
		// If there are less than the specified free pages - start offload
		if (free_pages() < (threshold_flash_pages - threshold_used_pages) )
		{
			// Check if protocol is already at work
            if (call ProtocolStarter.startOffload() == SUCCESS)
            {
				call StdOut.print("FLASH: Start offloading\n\r");
				call StdOut.print("FLASH: head: ");
				call StdOut.printHexword(flash_head);
				call StdOut.print("\r\n");
				call StdOut.print("FLASH: tail: ");
				call StdOut.printHexword(flash_tail);
				call StdOut.print("\r\n");
			
			} else {

				call StdOut.print("FLASH: Offloading in progress\n\r");
			}
		} 		

		/* unblock for other write calls */
		writePageInProgress = FALSE;

		if (clearSectorInProgress)
			post clearSectorTask();

		signal FlashManagerWriter.writePageDone(page);

		/* notify module writing to flash about the status of free/full pages */
		signal FlashManagerWriter.status(used_pages(), free_pages());
	}


	/**************************************************************************
	** FlashManagerReader
	**************************************************************************/
	command uint16_t FlashManagerReader.getPagesInUse()
	{	
		return used_pages();
	}

	command result_t FlashManagerReader.getPage(uint16_t page_no, uint8_t *output_buf)
	{
		uint16_t tmp; 
		
		// Already reading page from flash?
		// Consistency check - is flash full?
		// Consistency check - is index within bounds?
		if (readPageInProgress || (flash_head == -1) || (page_no + 1 > used_pages() )) {

			call StdOut.print("FLASH: Error! - cannot read page\n\r");
			return FAIL;
		} 
		
		/* Set flag to block other getPages from queueing up */
		readPageInProgress = TRUE;
		
		/* Check if flash has wrapped */
		tmp = flash_tail + page_no;
		if (tmp > flash_end) 
			tmp = tmp - flash_end + flash_start - 1;

        call StdOut.print("FLASH: Getting page: ");
        call StdOut.printHexword(tmp);
        call StdOut.print("\n\r");

		/* Read flash page into buffer */
		call FlashAccess.read(tmp, output_buf);

		return SUCCESS;
	}



	/**************************************************************************
	** FlashAccess
	**************************************************************************/
	event void FlashAccess.readReady(uint16_t page_no, void *page, uint16_t length)
	{
		/* Release hold on flash */
		readPageInProgress = FALSE;

		signal FlashManagerReader.pageReady(page_no);
	}

	/**************************************************************************
	** ProtocolStarter
	**************************************************************************/	
	event void ProtocolStarter.offloadLater()
	{	
		/* half the last increment and add it to the threshold */
		threshold_previous_increment >>= 1;
		threshold_used_pages += threshold_previous_increment;
		
		call StdOut.print("FLASH: Offloading later: ");
		call StdOut.printHexword(threshold_used_pages);
		call StdOut.print("\r\n");

        /* no more free pages i.e. flash is full - use timer */
        if (free_pages() == 0)
        {
            call StdOut.print("FLASH: Flash full - using timer\r\n");

            call Timer.start(TIMER_ONE_SHOT, TIME_OFFLOAD_RETRY);
        }
	}
	
	event void ProtocolStarter.offloadFinished(uint16_t acked_pages)
	{
		/* consistency check */
		if ( acked_pages > used_pages() )
			return;

		/* reset number of pages to initiate offload */			
		threshold_used_pages = CRITICAL_PAGE_LIMIT;
		threshold_previous_increment = CRITICAL_PAGE_LIMIT;

		clearSectorStart = flash_tail & 0xFF00;
		inc_tail(acked_pages);
		clearSectorEnd = flash_tail & 0xFF00;
		
        if ( (clearSectorStart != clearSectorEnd) || (used_pages() == 0) )
		{
    		clearSectorInProgress = TRUE;
			post clearSectorTask();
		} else {
            /* notify module writing to flash about the status of free/full pages */
            signal FlashManagerWriter.status(used_pages(), free_pages());
        }

		call StdOut.print("FLASH: head: ");
		call StdOut.printHexword(flash_head);
		call StdOut.print("\r\n");

		call StdOut.print("FLASH: tail: ");
		call StdOut.printHexword(flash_tail);
		call StdOut.print("\r\n");

		call StdOut.print("FLASH: Free pages: ");
		call StdOut.printHexword(free_pages());
		call StdOut.print("\r\n");

		call StdOut.print("FLASH: Used pages: ");
		call StdOut.printHexword(used_pages());
		call StdOut.print("\r\n");

		call StdOut.print("FLASH: Offload finished\n\r\n\r");
	}
	
	
	task void clearSectorTask()
	{
		call StdOut.print("FLASH: Erasing sector: ");
		call StdOut.printHexword(clearSectorStart);
		call StdOut.print("\r\n");

		/* erase sector */
		call FlashAccess.erase(clearSectorStart);

		/* update sector pointers */
		if (clearSectorStart == (flash_end & 0xFF00) )
		{
			clearSectorStart = flash_start & 0xFF00;
		}
		else
		{
			clearSectorStart += 0x0100;
		}

		
	}

    /**************************************************************************
    ** Timer
    **************************************************************************/
    event result_t Timer.fired()
    {
        /* panic - initate offload */
        call ProtocolStarter.startOffload();

        return SUCCESS;
    }


	/**************************************************************************
	** FlashAccess
	**************************************************************************/
	event void FlashAccess.eraseDone(uint16_t page_no)
	{
		/* repost task if there are still sectors that need to be cleared */
		if (clearSectorStart != clearSectorEnd)
		{
			if (!writePageInProgress)
				post clearSectorTask();
		} 
		else 
		{
            /* all free sectors have been cleared */
            clearSectorInProgress = FALSE;

            /* notify module writing to flash about the status of free/full pages */
            signal FlashManagerWriter.status(used_pages(), free_pages());
		}
	}

	event void FlashAccess.eraseAllDone()
	{
		;
	}

	/**************************************************************************
	** Cyclic flash_buffer management
	**************************************************************************/
	
	/* Increment head pointer */
	bool inc_head() {
		uint16_t tmp;

		/* Special case - cyclic buffer is empty */ 
		if (flash_head == -1) {
		
			/* Initialize head pointer */
			flash_head = flash_tail;

			return TRUE;

		} else {

			/* Buffer is not empty - increment head pointer */
			tmp = flash_head + 1;
			
			/* Check for buffer wrapping */
			if (tmp > flash_end)
				tmp = flash_start;

			/* Check if head pointer is on same sector as tail pointer */
			if ( (tmp <= flash_tail) && ((tmp & 0xFF00) == (flash_tail & 0xFF00)) ) {

				return FALSE;
			} else {
			
				/* Return new head pointer */
				flash_head = tmp;

				return TRUE;
			}
		} 
	}

	/* Calculate the number of used pages */
	uint16_t used_pages() 
	{
	
		if (flash_head == -1) {
		
			// Head pointer not set - flash is empty
			return 0;

		} else if (flash_head < flash_tail) {

			// Flash wrapped 
			return flash_end - flash_tail + flash_head - flash_start + 2;

		} else {

			// Linear flash
			return flash_head - flash_tail + 1;
		}
	}

	/* Calculate the number of free pages */
	uint16_t free_pages() 
	{
		uint16_t locked_by_sector;

		/* check if tail pointer is on same sector as start */		
		if ( (flash_tail & 0xFF00) == (flash_start & 0xFF00) )
		{
			locked_by_sector = flash_tail - flash_start;
		}else
		{
			locked_by_sector = flash_tail & 0x00FF;
		}
		
		return flash_size - used_pages() - locked_by_sector;
	}

	/* Increment a tail-pointer */
	void inc_tail(uint16_t acked_pages) {
		atomic 
		{
			/* reset head pointer if buffer is empty */
			if (used_pages() == acked_pages)
				flash_head = -1;
			
			/* increment tail pointer */
			flash_tail += acked_pages;

			/* wrap around if necessary */
			if (flash_tail > flash_end)
				flash_tail = flash_tail - flash_end + flash_start - 1;
		}
		
		return;
	}
	
	/**************************************************************************
	** StdOut
	**************************************************************************/
	async event result_t StdOut.get(uint8_t data) {

		return SUCCESS;
	}


}

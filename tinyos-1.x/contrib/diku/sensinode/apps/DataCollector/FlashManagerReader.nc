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


interface FlashManagerReader
{
	/////////////////////////////////////////////////////////////////////////
	// Retrieves the number of pages currently in use, by the flash
	// manager.
	//
	// @return uint16_t The number of pages in currently in use.
	/////////////////////////////////////////////////////////////////////////
	command uint16_t getPagesInUse();

	/////////////////////////////////////////////////////////////////////////
	// Retrieve a logical page from the flash manager. The first page in
	// the circular buffer is page 0. The page is stored in the memory
	// pointed to by buffer, but is not accessible until a pageReady()
	// event have been received for the requested page.
	//
	// @param uint16_t  page_no  The number of the page to retrieve.
	// @param uint8_t*  buffer   A buffer to retrieve the page into.
	// @return result_t          SUCCESS if the page can be retrieved.
	/////////////////////////////////////////////////////////////////////////
	command result_t getPage(uint16_t page_no, uint8_t *buffer);

	/////////////////////////////////////////////////////////////////////////
	// pageReady is signalled when the page requested by a call to
	// getPage have been retrieved.
	//
	// @param uint16_t  page_no
	/////////////////////////////////////////////////////////////////////////
	event void pageReady(uint16_t page_no);
}

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

interface Statistics
{
	/////////////////////////////////////////////////////////////////////////
	// Initialize the counter inside the statistical module. The counter
	// starts at zero.
	//
	// @param const char * name  The name of the counter
	/////////////////////////////////////////////////////////////////////////
	command void init(const char *name, const bool public);

	command void load();
	command void save();


	/////////////////////////////////////////////////////////////////////////
	// Set the counter to a specific value. 
	//
	// @param uint32_t value    The value for the counter
	/////////////////////////////////////////////////////////////////////////
	command void set(uint32_t value);


	/////////////////////////////////////////////////////////////////////////
	// Get value of counter. 
	//
	// @return uint32_t         The counter's value
	/////////////////////////////////////////////////////////////////////////
	command uint32_t getValue();


	/////////////////////////////////////////////////////////////////////////
	// Get name of counter. 
	//
	// @return const char *           The counter name
	/////////////////////////////////////////////////////////////////////////
	command const char *  getName();


	/////////////////////////////////////////////////////////////////////////
	// Increment counter by 1. 
	/////////////////////////////////////////////////////////////////////////
	async command void increment();


	/////////////////////////////////////////////////////////////////////////
	// Decrement counter by 1. 
	/////////////////////////////////////////////////////////////////////////
	async command void decrement();


	/////////////////////////////////////////////////////////////////////////
	// Change counter by a variable value. 
	//
	// @param int32_t value     The (pos/neg)value to be added to the counter
	/////////////////////////////////////////////////////////////////////////
	async command void add(int32_t value);

}

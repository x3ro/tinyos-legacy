/*
 * Copyright (c) 2009 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 */

	------------------------------------------------------------
    TinyHop: An end-to-end on-demand reliable ad hoc routing 
	         protocol for Wireless Sensor Networks for TinyOS 2.x.
			 https://www.cs.tcd.ie/~carbajrs/tinyhop/index.html
	------------------------------------------------------------

****************************************************************************
For further information contact Ricardo Simon Carbajo (carbajor at {tcd.ie})
and check the paper:
		"An end-to-end routing protocol for peer-to-peer communication 
		in wireless sensor networks"
		    http://portal.acm.org/citation.cfm?id=1435467.1435469
****************************************************************************

TinyHop has been designed to control reliability with end-to-end 
acknowledgements in bidirectional transmission paths and be easily 
configured with different routing decision metrics. 
Its memory footprint and scalability factor depends on the size of
the routing table.

A demo application has been created under the folder apps/ including
topologies and a script to run the simulation.
The codebase for the TinyHop routing protocol is placed under the 
folder /tos/lib/TinyHop-v.1.0.

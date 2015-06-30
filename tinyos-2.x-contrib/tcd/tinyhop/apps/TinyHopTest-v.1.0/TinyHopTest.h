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

/**
 * @author Ricardo Simon Carbajo <carbajor {tcd.ie}>
 * @date   February 13 2009 
 * Computer Science
 * Trinity College Dublin
 */
 
/****************************************************************/
/* Demo application on how to use the TinyHop routing layer     */
/*															    */
/* TinyHop:														*/
/* An end-to-end on-demand reliable ad hoc routing protocol		*/
/* for Wireless Sensor Networks intended for P2P communication	*/
/* See: http://portal.acm.org/citation.cfm?id=1435467.1435469   */
/*--------------------------------------------------------------*/
/* This version has been tested with TinyOS 2.1.0 and 2.1.1     */
/****************************************************************/

typedef nx_struct TOS_TinyHopTestMsg {
  nx_uint8_t type;
  nx_uint16_t reading;
  nx_uint16_t seqControl;
} TOS_TinyHopTestMsg;

enum {
	TEMPERATURE=0x1,
	PRESSURE=0x2,
	HUMIDITY=0x3,
	POSITION_CHANGE=0x4
};

enum {
  AM_TOS_TINYHOPTESTMSG = 17
};


/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti, Gabor Pap
 * 	   Brano Kusy, kusy@isis.vanderbilt.edu	
 * Date last modified: 06/30/03
 */

#include "AM.h"

enum
{
	AM_FLOODROUTING = 0x82, //TOSMSG AM_HANDLER for routing msg
	FLOODROUTING_HEADER = 3,//size of a header required for the FLoodRouting
				//size of appId and location bytes
	FLOODROUTING_MAXDATA =  //how many bytes are available in TOSMSG for data packets
		TOSH_DATA_LENGTH - FLOODROUTING_HEADER, 
};

typedef struct FloodRoutingMsg
{
	uint8_t appId;		// the application id, distinguishes different applications
				// using FloodRouting parametrized interface
	uint16_t location;	// see RoutingPolicy
	uint8_t data[0];	// actual packets, max length is FLOODROUTING_MAXDATA
} FloodRoutingMsg;

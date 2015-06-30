/*
 * Copyright (c) 2004, Vanderbilt University
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
 * Author: Miklos Maroti
 * Date last modified: 02/22/04
 */

#ifndef __ATOMICSECTIONMONITOR_H
#define __ATOMICSECTIONMONITOR_H

inline uint16_t getCurrentTime()
{
	return inw(TCNT3L);
}

inline void startSectionTimer()
{
	if( (inb(TCCR3B) & 0x07) == 0 )
	{
		outb(TCCR3A, 0x00);
		outb(TCCR3B, 0x01);
	}
}

enum
{
	// more does not fit into a message
	ATOMICSECTIONMONITOR_MAXID = 12,
};

struct atomicSectionMonitor
{
	uint16_t startTime;
	uint16_t maxDuration;
	uint8_t nested;
};

struct atomicSectionMonitor atomicSectionMonitors[ATOMICSECTIONMONITOR_MAXID];

inline void enterAtomicSection(uint8_t sectionId)
{
	if( sectionId < ATOMICSECTIONMONITOR_MAXID )
	{
		struct atomicSectionMonitor *p = atomicSectionMonitors + sectionId;
		if( (p->nested)++ == 0 )
			p->startTime = getCurrentTime();
		else if( p->nested == 0xFF )
			p->maxDuration = 0xFFFF;
	}
}

inline void leaveAtomicSection(uint8_t sectionId)
{
	if( sectionId < ATOMICSECTIONMONITOR_MAXID )
	{
		struct atomicSectionMonitor *p = atomicSectionMonitors + sectionId;
		if( --(p->nested) == 0 )
		{
			uint16_t duration = getCurrentTime() - p->startTime;
			if( duration > p->maxDuration )
				p->maxDuration = duration;
		}
		else if( p->nested == 0xFF )
			p->maxDuration = 0xFFFF;
	}
}

#endif//__ATOMICSECTIONMONITOR_H

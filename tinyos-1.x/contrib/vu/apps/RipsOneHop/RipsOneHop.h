/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy,	modify,	and	distribute this	software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided	that the above copyright notice, the following
 * two paragraphs and the author appear	in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT	UNIVERSITY BE LIABLE TO	ANY	PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS	ANY	WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF	MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR	PURPOSE.  THE SOFTWARE PROVIDED	HEREUNDER IS
 * ON AN "AS IS" BASIS,	AND	THE	VANDERBILT UNIVERSITY HAS NO OBLIGATION	TO
 * PROVIDE MAINTENANCE,	SUPPORT, UPDATES, ENHANCEMENTS,	OR MODIFICATIONS.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 */
struct Measurement{
    uint16_t period;
    uint8_t phaseOffset;
};

enum{
	START_MEASUREMENT_CMD = 0x12,
	RIPSAPP_ID = 0x11,
	ROUTING_UNIQUE_SIZE = 5,
	NUM_MEASUREMENTS = 23/sizeof(struct Measurement),
};

struct RoutingPacket{
    uint8_t seqNumber;
    uint16_t slaveID;
    struct Measurement measurements[NUM_MEASUREMENTS];
};

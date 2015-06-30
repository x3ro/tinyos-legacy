/*
 * @(#)INTERSEMA_LOWER.c
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Author:  Robert Szewczyk
 *
 * $\Id$
 */

#include "tos.h"
#include "INTERSEMA_LOWER.h"

#define CDATA1 0
#define CDATA2 1
#define CDATA3 2
#define CDATA4 3
#define DATA1  4
#define DATA2  5
#define RESET  6
#define READ   7

#define IDLE   8
#define POWER_OFF 9

#define SW_ADDRESS 73

// These are the codes to be written out to the Intersema
#define TOS_FRAME_TYPE INTERSEMA_LOWER_frame
TOS_FRAME_BEGIN(INTERSEMA_LOWER_frame) {
    unsigned char state;
    unsigned char ptr; 
    unsigned char nbytes;
    unsigned char cin;
    unsigned short data;
}
TOS_FRAME_END(INTERSEMA_LOWER_frame);


unsigned char codes[] = {
    0xaa, 0xaa, 0x00, 0xea, 0x80, 0x00, 0x00, 
    0xaa, 0xaa, 0x00, 0xeb, 0x00, 0x00, 0x00,
    0xaa, 0xaa, 0x00, 0xec, 0x80, 0x00, 0x00, 
    0xaa, 0xaa, 0x00, 0xed, 0x00, 0x00, 0x00,
    0xaa, 0xaa, 0x00, 0xf4, 0x00,
    0xaa, 0xaa, 0x00, 0xf2, 0x00, 
    0xaa, 0xaa, 0x00,
    0x00, 0x00};

int codePtrs[] =    { 0, 7, 14, 21, 28, 33, 38, 41};
int codeLengths[] = { 7, 7,  7,  7,  5,  5,  3,  2};

TOS_TASK(intersema_next_byte) {
    unsigned char cin = VAR(cin);
    unsigned char state;

    //deal with the incoming byte; simple for now, will get more complex
    //later (check out the commented out section below
    if (VAR(state) < 4) {
	if (VAR(nbytes) == 2) {
	    VAR(data) = cin & 0x7;
	} else if (VAR(nbytes) == 1) {
	    VAR(data) <<= 8;
	    VAR(data) |= cin & 0xff;
	} else if (VAR(nbytes) == 0) {
	    VAR(data) <<= 5; 
	    VAR(data) |= ((cin >> 3) & 0x1f);
	}
    } else {
	if (VAR(nbytes)==1)
	    VAR(data) = (cin << 8 ) & 0xff00;
	else if (VAR(nbytes) == 0)
	    VAR(data) |= cin & 0xff;
    }

    //dispatch the next byte

    if (VAR(nbytes) > 0) {
	TOS_CALL_COMMAND(SPI_SUB_BYTE)(codes[VAR(ptr)]);
	VAR(ptr)++;
	VAR(nbytes)--;
    } else {
	state = VAR(state);
	VAR(state) = IDLE;
	TOS_SIGNAL_EVENT(INTERSEMA_COMMAND_DONE)(VAR(data));
    }
}


char TOS_COMMAND(INTERSEMA_INIT)() {
    TOS_CALL_COMMAND(SPI_SUB_INIT)();
    TOS_CALL_COMMAND(SWITCH_SUB_INIT)();
    VAR(state) = POWER_OFF;
    return 1;
}

char TOS_COMMAND(INTERSEMA_POWER)(char state) {
    if (VAR(state) < IDLE) {
	return 0;
    }
    if (state == 0) { // turn off
	if (VAR(state) == IDLE) {
	    return TOS_CALL_COMMAND(SWITCH_SUB_SET_ALL)(SW_ADDRESS, 0x00);
	} 
    } else { //turn on 
	if (VAR(state) == POWER_OFF) {
	    return TOS_CALL_COMMAND(SWITCH_SUB_SET_ALL)(SW_ADDRESS, 0x11); 
	}
    }
    return 0;
}

char TOS_EVENT(INTERSEMA_SET_SWITCH_ALL_DONE) (char success) {
    if (VAR(state) == POWER_OFF) 
	VAR(state) = IDLE;
    else if (VAR(state) == IDLE)
	VAR(state) = POWER_OFF;
    TOS_SIGNAL_EVENT(INTERSEMA_POWER_DONE)(success);
    return 1;
}

char TOS_COMMAND(INTERSEMA_COMMAND)(unsigned char cmd) {
    if ((VAR(state) == IDLE) && (cmd < IDLE) ) {
	VAR(state) = cmd;
	VAR(ptr) = codePtrs[cmd];
	VAR(nbytes) = codeLengths[cmd];
	VAR(cin) = 0;
	TOS_POST_TASK(intersema_next_byte);
	return 1;
    } 
    return 0;
}

char TOS_EVENT(INTERSEMA_SET_SWITCH_DONE)(char success) {
    return 1;
}

char TOS_EVENT(INTERSEMA_GET_SWITCH_DONE)(char value) {
    return 1;

}

char TOS_EVENT(INTERSEMA_SPI_DONE)(unsigned char spi_in) {
    VAR(cin) = spi_in;
    TOS_POST_TASK(intersema_next_byte); 
    return 1;
}

#if 0
    switch (VAR(state)) {
    case CDATA1:
    case CDATA2:
    case CDATA3:
    case CDATA4:
	if (VAR(nbytes) == 1) {
	    VAR(calib)[VAR(state)<< 1] = cin;
	} else if (VAR(nbytes) == 0) {
	    VAR(calib)[(VAR(state)<<1) +1] = cin;
	}
	break;
    case READ:
	if (VAR(nbytes) == 1) {
	    VAR(data) = (cin << 8) & 0xff00;
	} else if (VAR(nbytes) == 0) {
	    VAR(data) += cin & 0xff;
	}
	break;
    default:
	break;
    }
#endif
	

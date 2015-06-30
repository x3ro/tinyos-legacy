/*
 * @(#)SOFTSPI.c
 *
 * "Copyright (c) 2002 and The Regents of the University 
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
#include "SOFTSPI.h"

#define IDLE    0
#define BUSY    1

static inline wait() {
    asm volatile("nop" "\n\t");
    asm volatile("nop" "\n\t");
}

#define SPIOUTPUT     if (spi_out & 0x80) {	\
                           SET_FLASH_OUT_PIN();	\
                      } else {			\
	                   CLR_FLASH_OUT_PIN();	\
                      } 			\
                      spi_out <<=1;

#define SPIINPUT          spi_in <<= 1;			\
                          if (READ_FLASH_IN_PIN()) {	\
                        	spi_in |= 1;		\
                          } else {			\
                         	wait();			\
                          }

#define TOS_FRAME_TYPE SPI_frame
TOS_FRAME_BEGIN(SPI_frame) {
        char state;
	char spi_out;
}
TOS_FRAME_END(SPI_frame);

char TOS_COMMAND(SPI_INIT)() {
    CLR_FLASH_CLK_PIN();
    MAKE_FLASH_CLK_OUTPUT();
    SET_FLASH_OUT_PIN();
    MAKE_FLASH_OUT_OUTPUT();
    CLR_FLASH_IN_PIN();
    MAKE_FLASH_IN_INPUT();
    return 1;
}


TOS_TASK(SPI_TASK) {
    unsigned char i;
    unsigned char spi_out = VAR(spi_out);
    unsigned char spi_in = 0;
    for (i=0; i < 8; i++) {
	SPIOUTPUT;
	SET_FLASH_CLK_PIN();
	wait();
	SPIINPUT;
	CLR_FLASH_CLK_PIN();
	wait();
    }
    VAR(state) = IDLE;
    TOS_SIGNAL_EVENT(SPI_DONE)(spi_in);
}


char TOS_COMMAND(SPI_BYTE)(unsigned char out) {
    if (VAR(state) == IDLE) {
	VAR(state) = BUSY;
	VAR(spi_out) = out;
	TOS_POST_TASK(SPI_TASK);
	return 1;
    }
    return 0;
}

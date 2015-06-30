/* 
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Source: /cvsroot/tinyos/tinyos-1.x/contrib/handhelds/tos/platform/zap/hwportdefs.h,v $
 * $Revision: 1.1 $           $Author: adchristian $
 * $State: Exp $      $Locker:  $
 * $Date: 2005/07/29 18:29:30 $
 */
#ifndef HARDWARE_H
#define HARDWARE_H

#define CHIP_5509 1
#include <csl.h>
#include <csl_mcbsp.h>
#include <csl_dma.h>
#include <csl_irq.h>
#include <csl_std.h>
#define _INLINE /* use inline GPIO functions */
#include <csl_gpio.h>  /* for GPIO support */

#define GPIO_A21		(1 << 0)
#define GPIO_A22		(1 << 1)
#define GPIO_LED		(1 << 2)
#define GPIO_BACKLIGHT	0 //(1 << 3)
#define GPIO_RESET		(1 << 4)
#define GPIO_FLASH		(1 << 5)
#define GPIO_CODEC		(1 << 6)
#define GPIO_ZIGBEE		(1 << 7)

#define LCD_BASE	(((volatile short *)(0xc00000+LCD_A0))-1)
#define FRAME_SIZE	37000	/* length of a DMA region */

#define UARTHW_MCBSP_IER_MASK_DEFAULT 1

/************************** memory map ******************/
/* the following are 16-bit _word_ addresses */
#define SPARE_ADDR	0x020000 /* CE0 */
#define FLASH_ADDR	0x200000 /* CE1 */
#define LAN_ADDR	0x400000 /* CE2 */
#define LCD_ADDR	0x600000 /* CE3 */

/************************** UART port ******************/
#define BT_DMA_RX_PORT		DMA_CHA4
#define BT_DMA_TX_PORT		DMA_CHA5
#define BT_BAUD					230400
#define BT_MULTIPLIER			5
#define SINGLE_CHAR_RX_LENGTH	3 /* in 'unsigned short' words in rxBuffer */
#define UART_FIFO_CHAR	10
#define UART_BUFFER_LENGTH     (SINGLE_CHAR_RX_LENGTH * UART_FIFO_CHAR)

#define OVERFLOW_CHECK {}
extern unsigned short *rxcount, *rxindex, *rxend, *rxstart;
#define BYTES_AVAIL ((*(rxindex+2) & 0xffff) != 0xffff) /* check for end of Rx char! */
#define NEXT_BYTE	{value = SERIAL_TO_DATA(*rxindex, *(rxindex+1), *(rxindex+2)); \
			*rxindex++ = 0xffff; \
			*rxindex++ = 0xffff; \
			*rxindex++ = 0xffff; \
			if (rxindex > rxend) \
				rxindex = rxstart; \
			}

#if (BT_MULTIPLIER == 3)
#define SERIAL_TO_DATA(A) \
    ((unsigned char)( (((A) & 0x2000000) >> 25) | (((A) & 0x400000) >> 21) \
    | (((A) & 0x080000) >> 17) | (((A) & 0x010000) >> 13) \
    | (((A) & 0x002000) >> 9) | (((A) & 0x000400) >> 5) \
    | (((A) & 0x000080) >> 1) | (((A) & 0x000010) << 3) ))
#define DATA_TO_SERIAL(A) (\
      (((A) & 0x80)? 0x000000e0: 0) \
    | (((A) & 0x40)? 0x00000700: 0) \
    | (((A) & 0x20)? 0x00003800: 0) \
    | (((A) & 0x10)? 0x0001c000: 0) \
    | (((A) & 0x08)? 0x000e0000: 0) \
    | (((A) & 0x04)? 0x00700000: 0) \
    | (((A) & 0x02)? 0x03800000: 0) \
    | (((A) & 0x01)? 0x1c000000: 0) \
    | 0x1f /* 1-2/3 stop bits */)
#elif (BT_MULTIPLIER == 5)
#define SERIAL_TO_DATA(A1,A2,A3) \
    ((unsigned char)( (((A1) & 0x0400) >> 10) | (((A1) & 0x0020) >> 4) \
    | (((A1) & 0x0001) << 2) | (((A2) & 0x0800) >> 8) \
    | (((A2) & 0x0040) >> 2) | (((A2) & 0x0002) << 4) \
    | (((A3) & 0x0100) >> 2) | (((A3) & 0x0008) << 4) ))
#define DATA_TO_SERIAL1(A) (\
      (((A) & 0x80)? 0x00000000: 0) \
    | (((A) & 0x40)? 0x00000000: 0) \
    | (((A) & 0x20)? 0x00000003: 0) \
    | (((A) & 0x10)? 0x0000007c: 0) \
    | (((A) & 0x08)? 0x00000f80: 0) \
    | (((A) & 0x04)? 0x0001f000: 0) \
    | (((A) & 0x02)? 0x003e0000: 0) \
    | (((A) & 0x01)? 0x07c00000: 0) \
    | 0 /* stop bits */)
#define DATA_TO_SERIAL2(A) (\
      (((A) & 0x80)? 0x00f80000: 0) \
    | (((A) & 0x40)? 0x1f000000: 0) \
    | (((A) & 0x20)? 0xe0000000: 0) \
    | (((A) & 0x10)? 0x00000000: 0) \
    | (((A) & 0x08)? 0x00000000: 0) \
    | (((A) & 0x04)? 0x00000000: 0) \
    | (((A) & 0x02)? 0x00000000: 0) \
    | (((A) & 0x01)? 0x00000000: 0) \
    | 0x0007ffff /* stop bits */)
#else    /* unknown multiplier, can't process */
#endif

void led_set (int arg_on);
void init_debug(void);
void DEBUG_putc(unsigned char arg_byte);
void DEBUG_puts(char *arg_string);

#endif //HARDWARE_H

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
 */

#include <hwportdefs.h>
#include "zapcfg.h"
#include <hwi.h>


volatile unsigned char tx_busy = 0;
unsigned short *rxcount, *rxindex, *rxend, *rxstart;
volatile int delayi, bozoj;

/* rxBuffer and txBuffer must be aligned for the DMA to work correctly */
#pragma DATA_ALIGN(rxBuffer, 32)
#pragma DATA_ALIGN(txBuffer, 32)
unsigned short rxBuffer[UART_BUFFER_LENGTH * 2];
unsigned long txBuffer[UART_BUFFER_LENGTH * 2];
static int rxId, txId;
static int use_uart_tx_dma = 0;
static unsigned long *txpoint;
static int tx_control = 0;

unsigned char spiTransferByte(unsigned char arg_byte)
{
     unsigned char i;
     MCBSP_write(C55XX_SPI_hMcbsp, arg_byte);
     while (!MCBSP_xrdy(C55XX_SPI_hMcbsp));
     i = MCBSP_read(C55XX_SPI_hMcbsp);
#if 0
     if (arg_byte == 0 && i == 0) hpprintf ("*"); else
	  hpprintf("(%x)=%x\n", arg_byte, i);
#endif
     return i;
}

void spiStartTransfer(void)
{
     while (!MCBSP_xrdy(C55XX_SPI_hMcbsp));
     _GPIO_IODATA &= ~(GPIO_ZIGBEE);
}

void spiEndTransfer(void)
{
     while (!MCBSP_xempty(C55XX_SPI_hMcbsp));
     _GPIO_IODATA |= GPIO_ZIGBEE;
}




static void rxIsr(void)
{
     volatile Uns temp = DMA_RGETH(hDmaRx, DMACSR);   /* DMA_RGET clears interrupt flag */
}

static void txIsr(void)
{
     volatile Uns temp = DMA_RGETH(hDmaTx, DMACSR);   /* DMA_RGET clears interrupt flag*/
     if (tx_control) {
	  if (--tx_control == 2) {
	       _DMA_DMACEN(BT_DMA_TX_PORT) = txpoint - txBuffer;
	       //_DMA_DMACCR(BT_DMA_TX_PORT) |= 0x0800;
	       return;
	  }
	  _DMA_DMACEN(BT_DMA_TX_PORT) = 4;
	  if (!tx_control) {
	       _DMA_DMACICR(BT_DMA_TX_PORT) = 0;
	       tx_busy = 0;
	  }
     }
}

void init_dma(void)
{
     HWI_Attrs hwiAttrs;
     Uns dmaTxSynEvt, dmaRxSynEvt;
     Uint32 dmaTxDest, dmaRxSrc;
     LgUns tempAdd;
     DMA_Config dmaTxCfg, dmaRxCfg;

     DMA_FSET(DMAGCR,FREE,0); 
     DMA_getConfig(hDmaTx, &dmaTxCfg); 
     dmaTxDest = MCBSP_ADDR(DXR21) << 1;
     /* Setup Tx Side addresses based on MCBSP port */
     dmaTxCfg.dmacdsal = (DMA_AdrPtr)(dmaTxDest & 0xFFFF);
     dmaTxCfg.dmacdsau = ((dmaTxDest >> 15) & 0xFFFF);
     tempAdd = (LgUns)(&txBuffer[0]) << 1; /* byte address */
     dmaTxCfg.dmacssal = (DMA_AdrPtr)(tempAdd & 0xFFFF);
     dmaTxCfg.dmacssau = ((tempAdd >> 15) & 0xFFFF); 
     dmaTxSynEvt = DMA_DMACCR_SYNC_XEVT1;
     dmaTxCfg.dmaccr |= DMA_FMK(DMACCR,SYNC,dmaTxSynEvt); 
     DMA_config(hDmaTx,&dmaTxCfg); 

     /* Setup Rx Side addresses based on MCBSP port */
     DMA_getConfig(hDmaRx, &dmaRxCfg);
     dmaRxSrc  = MCBSP_ADDR(DRR11) << 1; 
     dmaRxCfg.dmacssal = (DMA_AdrPtr)(dmaRxSrc & 0xFFFF);
     dmaRxCfg.dmacssau = ((dmaRxSrc >> 15) & 0xFFFF);
     tempAdd = (LgUns)(rxstart) << 1; /* byte address */
     dmaRxCfg.dmacdsal = (DMA_AdrPtr)(tempAdd & 0xFFFF);
     dmaRxCfg.dmacdsau = ((tempAdd >> 15) & 0xFFFF); 
     dmaRxSynEvt = DMA_DMACCR_SYNC_REVT1;
     dmaRxCfg.dmaccr |= DMA_FMK(DMACCR,SYNC,dmaRxSynEvt); 
     DMA_config(hDmaRx,&dmaRxCfg); 

     /* Configure DMA to be free running */
     DMA_FSET(DMAGCR,FREE,1); 
     /* Obtain Interrupt IDs for Tx and Rx DMAs */
     rxId = DMA_getEventId(hDmaRx);
     txId = DMA_getEventId(hDmaTx); 
     /* plug in the ISR */
     hwiAttrs.ier0mask = UARTHW_MCBSP_IER_MASK_DEFAULT;
     hwiAttrs.ier1mask = UARTHW_MCBSP_IER_MASK_DEFAULT;
     hwiAttrs.arg = NULL;
     HWI_dispatchPlug(rxId, (Fxn)rxIsr, &hwiAttrs);
     hwiAttrs.ier0mask = UARTHW_MCBSP_IER_MASK_DEFAULT;
     hwiAttrs.ier1mask = UARTHW_MCBSP_IER_MASK_DEFAULT;
     HWI_dispatchPlug(txId, (Fxn)txIsr, &hwiAttrs); 
     IRQ_enable(txId); 
     IRQ_enable(rxId);
}

#define MAX_PUTB	90
unsigned long putb_data[MAX_PUTB];
unsigned int putb_index = 0;
static void DEBUG_putb_flush()
{
     int i = 0;
     while (i < putb_index) {
	  while (!MCBSP_xrdy(C55XX_UART_hMcbsp));
	  MCBSP_write32(C55XX_UART_hMcbsp, putb_data[i++]);
     }
     putb_index = 0;
}

static void DEBUG_putb(unsigned long arg_bit)
{
     putb_data[putb_index++] = arg_bit;
}

void DEBUG_putc(unsigned char arg_byte)
{
     txpoint = &txBuffer[4];
     *txpoint++ = 0xffffffff;
     *txpoint++ = DATA_TO_SERIAL1(arg_byte);
     *txpoint++ = DATA_TO_SERIAL2(arg_byte);
     *txpoint++ = 0xffffffff; //extra
     *txpoint = 0xffffffff; //extra
     tx_busy = 1;
     if (use_uart_tx_dma) {
	  _DMA_DMACICR(BT_DMA_TX_PORT) = 0x0008;
	  tx_control = 3;
     }
     else {
	  unsigned long *temp = &txBuffer[4];
	  while (temp <= txpoint)
	       DEBUG_putb(*temp++);
	  DEBUG_putb_flush();
	  tx_busy = 0;
     }
     while (tx_busy)
	  ;
}

void DEBUG_puts(char *arg_string)
{
     while(*arg_string)
	  DEBUG_putc(*arg_string++);
}

void init_uart()
{
     DMA_start(hDmaRx);
     /* Start the MCBSP and Sample Rate Generator */
     MCBSP_start(C55XX_UART_hMcbsp, MCBSP_SRGR_START, 0xFFFF);
     /* Take MCBSP receive and transmit out of reset */
     MCBSP_start(C55XX_UART_hMcbsp, MCBSP_XMIT_START | MCBSP_RCV_START, 0xFFFF);
     MCBSP_write32(C55XX_UART_hMcbsp, 0xffffffff); /* kickstart the serial port */
     DEBUG_putc('d');
     DEBUG_puts("ebug_printf_ok\r\n");

}



volatile unsigned int global_clock = 0;
long clock_time = 0;
int clock_event = 0;

long timerm_clock_time = 0;
int timerm_clock_event = 0;

extern volatile unsigned KNL_curtime;
#define TSK_time()		KNL_curtime

void clock_update(void)
{
     static unsigned long clklast = 0;
     unsigned long clkcurrent = TSK_time();
     unsigned long clkdiff = (clkcurrent - clklast); // / 10;
     global_clock += clkdiff;
     clock_time -= clkdiff;
     timerm_clock_time -= clkdiff;
     clklast = clkcurrent;
}


#include <stdarg.h>

volatile char *printf_bufferp;
volatile char *printf_buffer_endp;
static void xxputchar(char temp)
{
     if (printf_bufferp < printf_buffer_endp)
	  *printf_bufferp++ = temp;
}

static char digits[] = "0123456789abcdef";

void printf_number(unsigned long ul, unsigned int base)
{
     unsigned char buf_number[sizeof(long) * 3 + 1+10];
     unsigned char *p = buf_number;
     unsigned long temp;
     do {
	  temp = ul & 0xf;
	  ul >>= 4;
	  *p++ = digits[temp];
     } while (ul);
     do {
	  xxputchar(*--p);
     } while (p > buf_number);
     *printf_bufferp = 0;
}

typedef unsigned char *str_t;

int vsnprintf (char *buffer, int bufferlen, char *fmt, va_list args)
{
     unsigned long ul;
     unsigned char *str, ch, base, size, lflag;

     printf_bufferp = buffer;
     printf_buffer_endp = buffer + bufferlen;
     while(1) {
	  while ((ch = *fmt++) != '%') {
	       if (ch == '\0')
		    goto return_label;
	       xxputchar(ch);
	       if (ch == '\n')
		    xxputchar('\r');
	  }
	  ch = *fmt++;
	  lflag = 0;
	  if (ch == 'l') {
	       lflag = sizeof(long) - sizeof(int);
	       ch = *fmt++;
	  }
	  base = 10;
	  size = 0;
	  switch (ch) {
	  case 'c':
	       ch = va_arg(args, char);
	       xxputchar(ch);
	       size = sizeof(int);
	       break;
	  case 's':
	       str = va_arg(args, str_t);
	       while ((ch = *str++))
		    xxputchar(ch);
	       size = sizeof(char *);
	       break;
	  case 'x':
	  case 'p':
	       base = 16;
	  case 'd':
	       if (lflag)
		    ul = va_arg(args, long);
	       else
		    ul = va_arg(args, int);
	       if ((long)ul < 0 && base == 10) {
		    xxputchar('-');
		    ul = -(long)ul;
	       }
	       printf_number(ul, base);
	       size = sizeof(int);
	       break;
	  case 'u':
	       if (lflag)
		    ul = va_arg(args, long);
	       else
		    ul = va_arg(args, unsigned);
	       printf_number(ul, base);
	       size = sizeof(int);
	       break;
	  default:
	       xxputchar('%');
	       if (lflag)
		    xxputchar('l');
	       xxputchar(ch);
	  }
	  args += size + lflag;
     }
 return_label:
     *printf_bufferp = 0;
     return printf_bufferp - buffer;
}


int snprintf (char *buffer, int bufferlen, char *fmt, ...)
{
     int count;
     va_list args;
     va_start(args, fmt);
     count = vsnprintf(buffer, bufferlen, fmt, args);
     va_end(args);
     return count;
}

int printf(char *fmt, ...)
{
     char msg[128];
     int count;
     va_list args;
     va_start(args, fmt);
     count = vsnprintf(msg, sizeof(msg), fmt, args);
     va_end(args);
     DEBUG_puts(msg);
     return count;
}

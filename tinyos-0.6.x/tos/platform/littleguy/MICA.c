/*
 * @(#)MICA.c
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

#include <io.h>

#define RENE_LITTLEGUY 1
#ifdef FULLPC

#include <time.h>
int a_holder_val;
#define inp(x...) a_holder_val = 1
#define outp(x...) a_holder_val = 1
#define sbi(x...) a_holder_val = 1
#define cbi(x...) a_holder_val = 1
#define cli() a_holder_val = 1
#define sei() a_holder_val = 1

#else //FULLPC
#include "io.h"
#include "sig-avr.h"
#include "interrupt.h"


//this macro automatically drops any printf statements if not
//compiling for a PC
#define printf(x...) ;
#define strcat(x...) ;


#endif //FULLPC

#define ASSIGN_PIN(name, port, bit) \
static inline void SET_##name##_PIN() {sbi(PORT##port , bit);} \
static inline void CLR_##name##_PIN() {cbi(PORT##port , bit);} \
static inline char READ_##name##_PIN() {return 0x01 & (inp(PIN##port) >> bit);} \
static inline void MAKE_##name##_OUTPUT() {sbi(DDR##port , bit);} \
static inline void MAKE_##name##_INPUT() {cbi(DDR##port , bit);} 

#define ALIAS_PIN(alias, connector) \
static inline void SET_##alias##_PIN() {SET_##connector##_PIN();} \
static inline void CLR_##alias##_PIN() {CLR_##connector##_PIN();} \
static inline char READ_##alias##_PIN() {return READ_##connector##_PIN();} \
static inline void MAKE_##alias##_OUTPUT() {MAKE_##connector##_OUTPUT();} \
static inline void MAKE_##alias##_INPUT()  {MAKE_##connector##_INPUT();} 

ASSIGN_PIN(BIG_GUY_RESET, B, 4);
ASSIGN_PIN(FLASH_CLK, B, 3);
ASSIGN_PIN(SCK, B, 2);
ASSIGN_PIN(MISO, B, 1);
ASSIGN_PIN(MOSI, B, 0);

#define IDLE    0
#define BUSY    1

static inline void wait() {
    asm volatile("nop" "\n\t");
    asm volatile("nop" "\n\t");
}

#define SPIOUTPUT     if (spi_out & 0x80) {	\
                           SET_MOSI_PIN();	\
                      } else {			\
	                   CLR_MOSI_PIN();	\
                      } 			\
                      spi_out <<=1;

#define SPIINPUT          spi_in <<= 1;			\
                          if (READ_MISO_PIN()) {	\
                        	spi_in |= 1;		\
                          } else {			\
                         	wait();			\
                          }


unsigned char last_b, last_f;

char spi_init() {
    CLR_FLASH_CLK_PIN();
    MAKE_FLASH_CLK_OUTPUT();
    CLR_SCK_PIN();
    MAKE_SCK_OUTPUT();
    SET_MOSI_PIN();
    MAKE_MOSI_OUTPUT();
    CLR_MISO_PIN();
    MAKE_MISO_INPUT();
    return 1;
}

// single byte transaction with the main processor

unsigned char bg_spi(unsigned char spi_out) {
    unsigned char i;
    unsigned char spi_in = 0;
    for (i=0; i < 8; i++) {
	CLR_SCK_PIN();
	SPIOUTPUT;
	SET_SCK_PIN();
	SPIINPUT;
    }
    if (last_f)
	spi_in = ~spi_in;
    last_b = spi_in & 1;
    return spi_in;
}


// single byte transaction with the flash

unsigned char flash_spi(unsigned char spi_out) {
    unsigned char i;
    unsigned char spi_in = 0;
    for (i=0; i < 8; i++) {
	CLR_FLASH_CLK_PIN();
	SPIOUTPUT;
	SET_FLASH_CLK_PIN();
	SPIINPUT;
    }
    if (last_b)
	spi_in = ~spi_in;
    last_f = spi_in & 1;
    return spi_in;
}


// issue a single 4byte comamnd to the flash

void flash_cmd(char cmd, char p1, char p2, char p3) {
    flash_spi(cmd);
    flash_spi(p1);
    flash_spi(p2);
    flash_spi(p3);
}

// pulse the reset pin; the name is slightly misleading in that it pulses both
// the chip select line on the flash and the RESET pin on the big guy. 

void pulse_flash_cs() {
    unsigned char end;
    SET_BIG_GUY_RESET_PIN();
    wait_ms(1);
    CLR_BIG_GUY_RESET_PIN();
    last_b = 1;
    last_f = 1;
}
// Page programming algorithm: 
// -- set up the flash
// -- read in a byte from flash
// -- add this byte to a running checksum
// -- load that byte into the big guy
// -- repeat 256 times 
// -- issue a page write to the big guy
// -- read in a checksum, compare. 

//#define ARRAY_READ  0x68
#define ARRAY_READ 0xe8
#define PAGE_TO_BUFFER_XFER 0x53
#define BUFFER_WRITE 0x82
#define BUFFER_TO_MEM 0x88

// enable the main processor for programming

char program_enable() {
    int ntries, end,i;
    unsigned char foo;
    unsigned char resp[6];
#ifdef FULLPC
    __sda_string_[0] = 0;
    __mosi_string_[0] = 0;
#endif
    MAKE_BIG_GUY_RESET_OUTPUT();
    CLR_SCK_PIN();
    CLR_BIG_GUY_RESET_PIN();
    wait();
    wait();
    i = 0;
    pulse_flash_cs();
    for (end=0; end < 5000; end++) {
	wait();
    }
    for(end = 0, ntries = 32; (end == 0) && (ntries >0); ntries--) {
	bg_spi(0xac);
	bg_spi(0x53);
	foo = bg_spi(0x00);
	if (foo == 0x53) { 
	    end = 1;
	} else {
	    CLR_SCK_PIN();
	    wait();
	    wait();
	    SET_SCK_PIN();
	    wait();
	    wait();
	}	    
	bg_spi(0x00);
	if (i <6)
	    resp[i++] = foo;
    }
    if (end == 0) {
	flash_cmd(BUFFER_WRITE, 0,0,10);
	for (i=0; i < 6; i++)
	    flash_spi(resp[i]);
	pulse_flash_cs();
	wait_ms(20);
	return 0;
    }
    printf("%s\n", __mosi_string_);
    printf("%s\n", __sda_string_);
    return 1;
}

// erase the flash
    
void program_erase() {
#ifdef FULLPC
    __sda_string_[0] = 0;
    __mosi_string_[0] = 0;
#endif
    bg_spi(0xac);
    bg_spi(0x80);
    bg_spi(0x00);
    bg_spi(0x00);
    printf("%s\n", __mosi_string_);
    printf("%s\n", __sda_string_);
}

int page_to_flash(int atmel_page) {
    return (atmel_page + 1) << 1;
}


// program a single page of Atmega 103, 256 bytes.

void program_page(int page) {
    int flash_addr = page_to_flash(page);
    unsigned int i;
    unsigned char data;
    unsigned char data1;
    flash_spi(ARRAY_READ);
    flash_spi((flash_addr >> 8) & 0xff);
    flash_spi(flash_addr & 0xff);
    for (i=0; i < 5; i++) {
	flash_spi(0);
    }
    for (i = 0; i < 128; i++) {
	data = flash_spi(0);
	data1 = flash_spi(0);
	bg_spi(0x40);
	bg_spi(0x00); 
	bg_spi(i);
	bg_spi(data);
	bg_spi(0x48);
	bg_spi(0x00); 
	bg_spi(i);
	bg_spi(data1);
    }

    bg_spi(0x4c);
    bg_spi((page >> 1) & 0xff);
    bg_spi((page << 7) & 0xff );
    bg_spi(0x00);

}


//routine: wait for about 1ms (actually takes more on the order of 1.1. sec.

void wait_ms(char n) {
    char i;
    int j;
    for (i=0; i< n; i++) {
	for (j=0; j < 98; j++) {
	    asm volatile("nop"::);
	}
    }
}

// read the parameters from the flash; right now just reads the length of the
// program. 
int read_params() {
    int i;
    int retval;
    flash_cmd(ARRAY_READ, 0,0, 4);
    /*    flash_spi(ARRAY_READ);
    flash_spi(0);
    flash_spi(0);
    flash_spi(4);*/
    for (i=0; i < 4; i++) {
	flash_spi(0);
    }
    retval = flash_spi(0) & 0xff;
    retval += (flash_spi(0) << 8);
    return retval;
}

int error_code(short errno) {
    pulse_flash_cs();
    flash_cmd(PAGE_TO_BUFFER_XFER,0,0,0);
    pulse_flash_cs();
    flash_cmd(BUFFER_WRITE, 0,0,8);
    flash_spi(errno & 0xff);
    flash_spi((errno >> 8) & 0xff);
    return 1;
}

void hibernate() {
    CLR_SCK_PIN();
    SET_BIG_GUY_RESET_PIN();
    outp(0, DDRB);
    outp(0x00, PORTB);
    outp(0x22, MCUCR); 
    outp(0x00, GIMSK);
    while(1) {
    asm volatile("sleep");
    asm volatile("nop");
    asm volatile("nop");
    }
}

int main() {
    unsigned int i=0;
    unsigned int num_pages;
    // Initial state: flash is insactive, and the big guy just pulled down the
    // MISO pin. 
    last_f = 1;
    if (READ_MISO_PIN())
	last_b = 0;
    else 
	last_b = 1;
    if (last_b == 0) {
	CLR_BIG_GUY_RESET_PIN();
	MAKE_BIG_GUY_RESET_OUTPUT();
	spi_init();
	CLR_SCK_PIN();
	MAKE_BIG_GUY_RESET_OUTPUT();
       	pulse_flash_cs();
	wait_ms(20);
	// read the program legth
	num_pages = read_params();
	//num_pages=575;
	num_pages += 0xff;
	num_pages >>= 8;
	error_code(num_pages);
	if (program_enable()) {
	    program_erase();
	} else {
	    error_code(0x10);
	    hibernate();
	}
	// wait a little bit
	wait_ms(120);
	pulse_flash_cs();
	// pulse the reset pin
	//wait_ms(20);
	// upload the program
	if (program_enable()) {
	    for (i=0; i < num_pages; i++) {
	    program_page(i);
	    wait_ms(56);
	    }
	} else {
	    error_code(0x20);
	}
	
    }
    SET_BIG_GUY_RESET_PIN();
    //}
    hibernate();
    return 0;
}

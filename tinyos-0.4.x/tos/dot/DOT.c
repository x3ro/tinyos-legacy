/*									tab:4
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:		Robert Szewczyk
 *
 *
 */

/* Bootloader for the Atmel atmega 163 processor. The function is very
   simple: main function reads out the new program from the I2C EEPROM 1
   page at a time, and writes it out to the program memory. When the
   process has completed, it sets up the watchdog timer, and loops until
   the watchdog reset.  Eventually it should go to sleep.  

   The _start function needs to be relocated to an address in the 
   bootloader, and the TinyOS kernel needs to be informed about the
   location of that symbol. Right now I believe that it ought to be
   possible to fit most bootloader functionality in 1Kbyte of code, which
   implies the booloader address at 0x3C00.  That's what the Makefiles are
   set to.

   TODO: 
    - Split off I2C functionality into a separate file, 
    - start using modified hardware.h to allow for multiple 163-based motes
    - define hardware I2C abstraction 
*/


#include "io.h"
#include "inttypes.h"
#define PAGE_ERASE 0x03
#define PAGE_LOAD  0x01
#define PAGE_WRITE 0x05
#define APP_ENABLE 0x11
#define PAGESIZE 128
#define PROG_LENGTH 0x0004

#include <io.h>
#include <hardware.h>
#include <wdt.h>
#define strcat(...)
#define dbg(...)
#if 0
#define SET_CLOCK() sbi(PORTD, 3)
#define CLEAR_CLOCK() cbi(PORTD, 3)
#define MAKE_CLOCK_OUTPUT() sbi(DDRD, 3)
#define MAKE_CLOCK_INPUT() cbi(DDRD, 3)
#define SET_DATA() sbi(PORTD, 4)
#define CLEAR_DATA() cbi(PORTD, 4)
#define MAKE_DATA_OUTPUT() sbi(DDRD, 4)
#define MAKE_DATA_INPUT() cbi(DDRD, 4)
#define GET_DATA() (inp(PIND) >> 4) & 0x1
#endif
#define SET_CLOCK SET_I2C_BUS1_SCL_PIN
#define CLEAR_CLOCK CLR_I2C_BUS1_SCL_PIN
#define MAKE_CLOCK_OUTPUT MAKE_I2C_BUS1_SCL_OUTPUT
#define MAKE_CLOCK_INPUT MAKE_I2C_BUS1_SCL_INPUT

#define SET_DATA SET_I2C_BUS1_SDA_PIN
#define CLEAR_DATA CLR_I2C_BUS1_SDA_PIN
#define MAKE_DATA_OUTPUT MAKE_I2C_BUS1_SDA_OUTPUT
#define MAKE_DATA_INPUT MAKE_I2C_BUS1_SDA_INPUT
#define GET_DATA READ_I2C_BUS1_SDA_PIN
void wait(char n);
#define __SPM(a, c) ({			\
    unsigned short __addr16 = (unsigned short) a; 	\
    unsigned char __cmd = (unsigned char) c;	\
    __asm__  __volatile__ (				\
			  "out %2, %0" "\n\t"	\
			  "spm" "\n\t"			\
                          ".short 0xffff" "\n\t"        \
			  "nop" "\n\t"			\
			  :				\
			  : "r" (__cmd), "z" (__addr16), "I" (SPMCR)\
			  );				\
})

void page_erase(unsigned short addr);
void page_write(unsigned short addr);
void page_load(unsigned short instr, unsigned short addr);
void I2C_SetAddr(int addr);
unsigned short get_next_instr(char ack);

//__asm__(".org 0x3c00, 0xff" "\n\t");

void _start() {
    int i;
    unsigned short instr;
    unsigned short proglen, page;
    unsigned short j;
    unsigned short pg[64];
    cli();
    outp(0x00, DDRA);
    outp(0x00, DDRD);
    outp(0x00, DDRC);
    outp(0x00, DDRB);
    outp(0x00, PORTA);
    outp(0x00, PORTD);
    outp(0x00, PORTC);
    outp(0x00, PORTB);
    
    SET_RED_LED_PIN();
    SET_YELLOW_LED_PIN();
    SET_GREEN_LED_PIN();
    MAKE_RED_LED_OUTPUT();
    MAKE_YELLOW_LED_OUTPUT();
    MAKE_GREEN_LED_OUTPUT();
    SET_CLOCK();
    SET_DATA();
    MAKE_CLOCK_OUTPUT();
    MAKE_DATA_OUTPUT();
    
    I2C_SetAddr(PROG_LENGTH);
    while (i == 0) {
	i2c_start();
	if ((i = i2c_write(0xa1)) != 0) {
	    SET_GREEN_LED_PIN();
	} else {
	    CLR_GREEN_LED_PIN();
	}
    }
    proglen = get_next_instr(0);
    i2c_end();
    I2C_SetAddr(64);
    CLR_GREEN_LED_PIN();
    for (j = 0;  j < proglen; j+=128) {
	page = j;
	page_erase(page);
	i = 0;
	while (i == 0) {
	    i2c_start();
	    if ((i = i2c_write(0xa1)) != 0) {
		SET_GREEN_LED_PIN();
	    } else {
		CLR_GREEN_LED_PIN();
	    }
	}
	for (i = 0; i < 64; i++) {
	    pg[i] = get_next_instr(i!=63);
	}
	wait(2);
	i2c_end();
	for (i = 0; i < PAGESIZE; i+=2) {
	    page_load(pg[i>>1], page);
	    page+=2;
	}
	page_write(j);

    }
    while (inp(SPMCR) & (1<<ASB)) {
	__SPM(page, APP_ENABLE);
    }
    //    sei();
    SET_GREEN_LED_PIN();
    wdt_enable(1);
    while(1){
	CLR_GREEN_LED_PIN();
	for (i=1; i != 0; i++);
	SET_GREEN_LED_PIN();
	for (i=1; i != 0; i++);
    }
}

void wait(char n) {
    char i;
    for (i =0; i < 20; i++) {
	__asm__ __volatile__ ("nop" "\n\t"::);
    }
}

static inline void pulse_clock(){
	wait(4);
	SET_CLOCK();
	wait(4);
	CLEAR_CLOCK();
}

char read_bit(){
	char i;
	MAKE_DATA_INPUT();
	wait(4);
	SET_CLOCK();
	wait(4);
	i = GET_DATA();
	CLEAR_CLOCK();
	return i;
}
char i2c_read(){
	char data = 0;
	char i = 0;
	for(i = 0; i < 8; i ++){
		data = (data << 1) & 0xfe;
		if(read_bit() == 1){
			data |= 0x1;
		}
	}
	dbg(DBG_I2C, ("r"));
	return data;
}


char i2c_write(char c){ 
	int i;
	MAKE_DATA_OUTPUT();
	for(i = 0; i < 8; i ++){
		if(c & 0x80){
			dbg(DBG_I2C, ("1"));
			SET_DATA();
		}else{
			dbg(DBG_I2C, ("0"));
			CLEAR_DATA();
		}
		pulse_clock();
		c = c << 1;
	}
 	i = read_bit();	
	dbg(DBG_I2C, ("%x ", c & 0xff));
	return i == 0;
} 
void i2c_start(){
	SET_DATA();
	SET_CLOCK();
	MAKE_DATA_OUTPUT();
	wait(4);
	CLEAR_DATA();
	wait(4);
	CLEAR_CLOCK();
	dbg(DBG_I2C, (" i2c_start\n"));
}
void i2c_ack(){
	MAKE_DATA_OUTPUT();
	CLEAR_DATA();
	pulse_clock();
	dbg(DBG_I2C, (" i2c_ack\n"));
}
void i2c_nack(){
	MAKE_DATA_OUTPUT();
	SET_DATA();
	pulse_clock();
	dbg(DBG_I2C, (" i2c_nack\n"));
}
void i2c_end(){
	MAKE_DATA_OUTPUT();
	CLEAR_DATA();
	wait(4);
	SET_CLOCK();
	wait(4);
	SET_DATA();
	dbg(DBG_I2C, (" i2c_end\n"));
}

unsigned short get_next_instr(char ack) {
    int i;
    char i2cin = 0;
    unsigned short retval;

    i2cin = i2c_read();
    i2c_ack();
    retval = i2cin & 0xff;
    wait(2);
    i2cin = i2c_read();
    if (ack)
	i2c_ack();
    else
	i2c_nack();
    retval += (i2cin & 0xff) << 8;
    wait(2);
    return retval;
}

static void I2C_SetAddr(int addr) {
    i2c_start();
    if (i2c_write(0xa0) == 0) {
	SET_GREEN_LED_PIN();
    } else {
	CLR_GREEN_LED_PIN();
    }
    i2c_write( (addr >> 8) &0xff);
    i2c_write(addr &0xff);
    i2c_end();
}


void page_erase(unsigned short addr) {
    __SPM(addr, PAGE_ERASE);
    while(inp(SPMCR) & 0x01);
}

void page_write(unsigned short addr) {
    __SPM(addr, PAGE_WRITE);
    while(inp(SPMCR) & 0x01);
}

void page_load(unsigned short instr, unsigned short addr) {
    __asm__ __volatile__ ("movw r0, %0" "\n\t"::"r" (instr):"r0", "r1");
    __SPM(addr, PAGE_LOAD);
    __asm__ __volatile__ ("clr r1" "\n\t"::);
    while(inp(SPMCR) & 0x01);
}




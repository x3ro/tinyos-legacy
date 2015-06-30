// $Id: I2CSPI.c,v 1.2 2003/10/07 21:44:52 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
#include <io.h>
#include <hardware.h>
unsigned char spi_out;
unsigned char spi_in;

#ifdef FULLPC
#include <stdlib.h>
#include <stdio.h>

char __sda_string_[80];
char __mosi_string_[80];
int READ_I2C_SDA_PIN() {
    return 1;
}
void CLR_I2C_SDA_PIN() {
    strcat(__sda_string_, "0");
}
void SET_I2C_SDA_PIN() {
    strcat(__sda_string_, "1");
}

void SET_MOSI_PIN() {
    strcat(__mosi_string_, "1");
}

void CLR_MOSI_PIN() {
    strcat(__mosi_string_, "0");
}

int READ_MISO_PIN() {
    return 1;
}

void MAKE_I2C_SDA_INPUT() {
}

void MAKE_I2C_SDA_OUTPUT() {
}

void SET_CLOCK_PIN() {
}

void CLR_CLOCK_PIN() {
}
#else 
static inline void wait() {
    asm volatile ("nop"::);
}
#endif
#define PROG_LENGTH 0x0004
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

char SPI_I2CRead() {
    char ret;
    strcat(__sda_string_, "r");
    MAKE_I2C_SDA_INPUT();
    SPIOUTPUT;
    wait();
    wait();
    SET_CLOCK_PIN();
    wait();
    wait();
    wait();
    SPIINPUT;
    ret = READ_I2C_SDA_PIN();
    CLR_CLOCK_PIN();
    return ret;
}

void SPI_I2CWrite(char i2c_out) {
    MAKE_I2C_SDA_OUTPUT();
    SPIOUTPUT;
    if (i2c_out & 0x80) {
	SET_I2C_SDA_PIN();
    } else {
	CLR_I2C_SDA_PIN();
    }
    SET_CLOCK_PIN();
    wait();
    wait();
    wait();
    SPIINPUT;
    CLR_CLOCK_PIN();
}

void SPI_I2CStart() {
    SET_I2C_SDA_PIN();
    MAKE_I2C_SDA_OUTPUT();
    SPIOUTPUT;
    wait();
    wait();
    SET_CLOCK_PIN();
    wait();
    wait();
    CLR_I2C_SDA_PIN();
    SPIINPUT;
    CLR_CLOCK_PIN();
#ifdef FULLPC    
    __sda_string_[strlen(__sda_string_) - 2] = 0;
    strcat(__sda_string_, "s");
#endif
}

void SPI_I2CStop() {
    CLR_I2C_SDA_PIN();
    MAKE_I2C_SDA_OUTPUT();
    SPIOUTPUT;
    wait();
    wait();
    SET_CLOCK_PIN();
    wait();
    wait();
    SET_I2C_SDA_PIN();
    SPIINPUT;
    CLR_CLOCK_PIN();
#ifdef FULLPC
    __sda_string_[strlen(__sda_string_) - 2] = 0;
    strcat(__sda_string_, "p");
#endif
}

void SPI_byte() {
    int i; 
    for (i = 0; i < 8; i++) {
	SPI_I2CRead();
    }
}
char I2C_WriteByte(char i2cout) {
    int i;
    for (i = 0; i< 8; i++) {
	SPI_I2CWrite(i2cout);
	i2cout <<=1;
    }
    return SPI_I2CRead();
}

char I2C_ReadByte() {
    int i;
    char i2cin = 0;
    spi_out = 0;
    SPI_I2CStart();
    I2C_WriteByte(0xa1);
    for (i = 0; i < 8; i++) {
	i2cin <<= 1;
	i2cin += SPI_I2CRead();
    }
    SPI_I2CWrite(0x80);
    SPI_I2CStop();
    return i2cin;
}

void I2C_SetAddr(int addr) {
    spi_out = 0;
    SPI_I2CStart();
    I2C_WriteByte(0xa0);
    I2C_WriteByte( (addr >> 8) &0xff);
    I2C_WriteByte(addr &0xff);
    SPI_I2CStop();
}

unsigned char program_byte(int addr) {
    unsigned char i2cout = 0xa1;
    unsigned char i; 
#ifdef FULLPC
    __sda_string_[0] = 0;
    __mosi_string_[0] = 0;
#endif
    if (addr & 0x01)
	spi_out = 0x48;
    else 
	spi_out = 0x40;
    addr >>= 1;
    SPI_I2CStart();
    for (i = 0; i < 7; i++) {
	SPI_I2CWrite(i2cout);
	i2cout<<=1;
    }
    spi_out = (addr >> 8) & 0x0f;
    SPI_I2CWrite(i2cout);
    SPI_I2CRead();
    for (i = 0; i < 6; i++) {
	i2cout <<= 1;
        if (SPI_I2CRead())
	    i2cout |= 1;
    }
    spi_out = addr & 0xff;
    i2cout <<= 1;
    if (SPI_I2CRead())
	i2cout |= 1;
    i2cout <<= 1;
    if (SPI_I2CRead())
	i2cout |= 1;
    SPI_I2CWrite(0x80);
    SPI_I2CStop();
    for (i = 0; i < 4; i++) {
	SPI_I2CRead();
    }
    spi_out = i2cout;
    SPI_byte();
#ifdef FULLPC
    printf("%s\n", __mosi_string_);
    printf("%s\n", __sda_string_);
#endif
    return i2cout;
}

void program_poll(int addr) { 
    int i;
#ifdef FULLPC
    __sda_string_[0] = 0;
    __mosi_string_[0] = 0;
#endif
    if (addr &0x01) {
	spi_out = 0x28;
    } else {
	spi_out = 0x20;
    }
    addr >>= 1;
    for (i = 0; i < 8; i++) {
	SPI_I2CRead();
    }
    spi_out  = (addr >> 8) & 0x0f;
    for (i = 0; i < 8; i++) {
	SPI_I2CRead();
    }
    spi_out = (addr & 0xff);
    for (i = 0; i < 8; i++) {
	SPI_I2CRead();
    }
    spi_out = 0;
    for (i = 0; i < 8; i++) {
	SPI_I2CRead();
    }
#ifdef FULLPC
    printf("%s\n", __mosi_string_);
    printf("%s\n", __sda_string_);
#endif
}   

char program_enable() {
    int ntries, end;
#ifdef FULLPC
    __sda_string_[0] = 0;
    __mosi_string_[0] = 0;
#endif
    MAKE_BIG_GUY_RESET_OUTPUT();
    CLR_BIG_GUY_RESET_PIN();
    wait();
    wait();
    SET_BIG_GUY_RESET_PIN();
    for (end=0; end < 10; end++) {
	wait();
    }
    CLR_BIG_GUY_RESET_PIN();
    for (end=0; end < 5000; end++) {
	wait();
    }
    
    for(end = 0, ntries = 32; (end == 0) && (ntries >0); ntries--) {
	spi_out = 0xac;
	SPI_byte();
	spi_out = 0x53;
	SPI_byte();
	SPI_byte();
	if (spi_in == 0x53) {
	    end = 1;
	} else {
	    SPI_I2CRead();
	}	    
	SPI_byte();
    }
    if (end == 0) {
	return 0;
    }
    printf("%s\n", __mosi_string_);
    printf("%s\n", __sda_string_);
    return 1;
}
    
void program_erase() {
#ifdef FULLPC
    __sda_string_[0] = 0;
    __mosi_string_[0] = 0;
#endif
    spi_out = 0xac;
    SPI_byte();
    spi_out = 0x80;
    SPI_byte();
    SPI_byte();
    SPI_byte();
    printf("%s\n", __mosi_string_);
    printf("%s\n", __sda_string_);
}

void upload_program(int start_addr, int length) {
    int addr;
    unsigned char instr;
    int i;
    for (addr = start_addr; addr < start_addr+length; addr++){
	printf("Address: %04x\n", addr);
	instr = (unsigned char)program_byte(addr);
	spi_in = 0xff;
	if (instr== 0xff) {
	    for (i = 0; i < 6000; i++) {
		asm volatile("nop"::);
	    }
	    continue;
	}
	while(spi_in == 0xff) {
	    program_poll(addr);
	    printf("Instruction: %02x, Read: %02x\n",instr&0xff, spi_in&0xff);
	}
    }
}

void program_chip() { 
    // set the eeprom address

    // reset the chip 

    // program enable

    // program erase

    // pulse the reset 

    // program enable

    // program upload
}

#ifdef FULLPC
void main(){
    int i;
    upload_program(0, 16);
}
#else 
int main() {
    char i;
    int j;
    int proglen;
    MAKE_I2C_SDA_INPUT();
    i = READ_I2C_SDA_PIN(); 
    if (i == 0) {
	MAKE_CLOCK_OUTPUT();
	CLR_CLOCK_PIN();
	MAKE_BIG_GUY_RESET_OUTPUT();
	CLR_BIG_GUY_RESET_PIN();
	MAKE_MOSI_OUTPUT();
	MAKE_MISO_INPUT();
	CLR_MISO_PIN();
	I2C_SetAddr(PROG_LENGTH);
	proglen = (I2C_ReadByte() & 0xff);
	j = (I2C_ReadByte() & 0xff) ;
	j <<= 8;
	proglen += j;
	I2C_SetAddr(64);
	SET_BIG_GUY_RESET_PIN();
	wait();
	wait();
	CLR_BIG_GUY_RESET_PIN();
	if (program_enable()) {
	program_erase();
	}
	for (j = 0; j < 12000; j++) {
	    asm volatile("nop"::);
	}
	SET_BIG_GUY_RESET_PIN();
	wait();
	wait();
	CLR_BIG_GUY_RESET_PIN();
	if (program_enable()) {
	    upload_program(0, proglen);
	}
	
    }
    CLR_CLOCK_PIN();
    SET_BIG_GUY_RESET_PIN();
    outp(0, DDRB);
    outp(0x00, PORTB);
    outp(0x22, MCUCR); 
    outp(0x00, GIMSK);
    asm volatile("sleep");
    asm volatile("nop");
    asm volatile("nop");
    return 0;
}
#endif

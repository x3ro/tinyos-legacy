// $Id: pavr.c,v 1.3 2003/10/07 21:46:13 idgay Exp $

/*
 * $Id: pavr.c,v 1.3 2003/10/07 21:46:13 idgay Exp $
 *
 ****************************************************************************
 *
 * pAVR Project - Atmel AVR serial programmer
 * Copyright (C) 2000 Jason Kyle <jpk@jpk.co.nz>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 ****************************************************************************
 */

/*
avrprog-0.1.c

Compiled with GCC  20001101   Binutils 001025   Libc 20000730
Target = Atmel AVR AT90S2313

Changed MOSI and MISO around, error in AVR910 app note. Fixed

AT89S53 device probably needs some work. >8kB flash is in same location as
EEPROM in 89S8252 so will need special handling??

Notes:
Device ID's AVR Prog V1.31 knows about
0x10  AT90S1200 Rev A
0x11  AT90S1200 Rev B
0x12  AT90S1200 Rev C
0x13  AT90S1200 Rev D (current)
0x20  AT90S2313
0x28  AT90S4414  (End Of Line)
0x30  AT90S4433
0x34  AT90S2333  (End Of Line)
0x38  AT90S8515
0x41  ATmega103
0x42  ATmega603  (End Of Line)
0x48  AT90S2323
0x4c  AT90S2343
0x50  ATtiny11
0x51  ATtiny10 (vapourware)
0x55  ATtiny12
0x56  ATtiny15
0x58  ATtiny19 (vapourware. NB ATtiny22 missing)
0x5c  ATtiny28 (?)
0x60  ATmega161 (vapourware?)
0x64  ATmega163
0x65  ATmega83  (vapourware?)
0x68  AT90S8535
0x70  AT90C8534 (parallel pgm only)
0x72  ATmega323  (vapourware?)
0x80  AT89C1051 (parallel pgm only)
0x81  AT89C2051 (parallel pgm only)
0x86  AT89S8252
0x87  AT89S53

AT89Sxxxx Subset:
0x86  AT89S8252
0x87  AT89S53

AT90S(non-EOL), ATmega(non-vapourware) Subset:
0x13  AT90S1200
0x20  AT90S2313
0x48  AT90S2323
0x4c  AT90S2343
0x30  AT90S4433
0x38  AT90S8515
0x68  AT90S8535
0x41  ATmega103
0x64  ATmega163

*/

/*
   Hacked a little by Marek Michalkiewicz <marekm@amelek.gda.pl>

   20010909:
   - ATmega163 support
   - device features as bits in dev_flags (page write, AT89S*)
   - fix a few gcc warnings
   - make a few global variables local, smaller code (SRAM -> registers)
   - add erased EEPROM detection
 */

#include <inttypes.h>
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/eeprom.h>
#include <avr/wdt.h>

#define F_CPU			4000000
#define UART_BAUD_RATE		19200

#define ATmega103 0x41
#define ATmega163 0x64
#define ATmega323 0x72
#define AT89S8252 0x86
#define AT89S53   0x87

#define SCK   PB7  //Connects to SCK (slave) on target
#define MISO  PB6  //Connects to MISO (slave) on target
#define MOSI  PB5  //Connects to MOSI (slave) on target
#define RESET PB4  //Connects to !RESET on target
#define LED   PD6  //LED Indicator on target
#define SCK1  PD3  //SCK to AT45D081 SCK pin
#define MISO1 PD5  //MISO to AT45D081 SO pin
#define MOSI1 PD4  //MOSI to AT45D081 SI pin
#define CSn   PD2  //CSn to AT45D081 CSn pin

const char __attribute__((progmem)) sw_version[]="20\0";
const char __attribute__((progmem)) hw_version[]="10\0";

#define ResetDelay 21  //Period = 21ms Active + 21ms Inactive
#define ErasePeriod 102  //Longest time to wait for Chip Erase (mega103L@3.2V)
#define FuseLockPeriod 56  //No real info on this one, used page pgm from mega103L@3.2V - longest

const char __attribute__((progmem)) flashPeriod[] = {4,   //AT90Sxxxx @ 5.0V
						     9,   //AT90Sxxxx @ 3.2V
						     16,  //ATmega163 @ any voltage
						     22,  //ATmega103 @ 5.0V
						     56}; //ATmega103 @ 3.2V

const char __attribute__((progmem)) eepromPeriod[] = {4,  //AT90Sxxxx @ 5.0V
						      9,  //AT90Sxxxx @ 3.2V
						      4,  //ATmega163 @ any voltage
						      4,  //ATmega103 @ 5.0V
						      9}; //ATmega103 @ 3.2V

const char __attribute__((progmem)) sckPeriod[] = {1,  //1us (XTAL > 4MHz) Actually about 4us (1MHz)
						   4,  //4us (XTAL > 0.5MHz)
						   63};  //63us (XTAL > 32kHz)

const char __attribute__((progmem)) devID[] = {0x13,  //AT90S1200
					       0x20,  //AT90S2313
					       0x48,  //AT90S2323
					       0x4c,  //AT90S2343
					       0x30,  //AT90S4433
					       0x38,  //AT90S8515
					       0x68,  //AT90S8535
					       0x41,  //ATmega103
					       0x64,  //ATmega163
					       0x72,  //ATmega323
					       0x86,  //AT89S8252
					       0x87,  //AT89S53
					       0x00};  //NULL terminated (treated as string)

void send_prog_str(const char *buf);
void putc(uint8_t);
uint8_t getc(void);
void put_nibble(uint8_t);
void put_hex(uint8_t);
void spi_clk(void);
void spi_wr(uint8_t);
uint8_t spi_rd(void);
void delay_100us(uint8_t);
void delay_1ms(uint8_t);
void terminal_mode(void) __attribute__((noreturn));
uint8_t get_number(void);
uint8_t get_digit(uint8_t);
void put_number(uint8_t);

union addr_u {
  uint16_t word;
  uint8_t byte[2];
};

uint8_t fPeriod,ePeriod,cPeriod;

#define DEV_PAGE 0x01
#define DEV_AT89 0x02

int main(void)
{
uint8_t ch,i;
uint8_t device = 0, dev_flags = 0;
union addr_u addr;

 addr.word = 0x0000;
 outp(BV(CSn)|BV(LED),PORTD);  //CSn and LED set high
 outp(BV(SCK1)|BV(MISO1)|BV(MOSI1)|BV(CSn)|BV(LED),DDRD);  //Driven outputs
 outp((F_CPU/(UART_BAUD_RATE*16L)-1), UBRR);
 outp(BV(TXEN)|BV(RXEN),UCR);
 outp(BV(CS01),TCCR0);  //TC0 source CK/8
 wdt_enable(4);
 wdt_reset();
 putc('\0');

#if 0
 //Should probably add some checking for 0xff in eeprom (i.e. device erased/reprogrammed)
 fPeriod = PRG_RDB(flashPeriod + eeprom_rb(0x0001));
 ePeriod = PRG_RDB(eepromPeriod + eeprom_rb(0x0001));
 cPeriod = PRG_RDB(sckPeriod + eeprom_rb(0x0002));
#else
 i = eeprom_rb(0x0001);
 if (i >= sizeof(flashPeriod))
  i = 0;
 fPeriod = PRG_RDB(flashPeriod + i);
 ePeriod = PRG_RDB(eepromPeriod + i);
 i = eeprom_rb(0x0002);
 if (i >= sizeof(sckPeriod))
  i = 0;
 cPeriod = PRG_RDB(sckPeriod + i);
#endif

 for (;;) {
   ch = getc();
   switch(ch)
     {
     case 'T':  //Set device type
       device=getc();
       dev_flags = 0;
       if (device == ATmega103 || device == ATmega163 || device == ATmega323)
	 dev_flags |= DEV_PAGE;
       if (device == AT89S8252 || device == AT89S53)
	 dev_flags |= DEV_AT89;
       putc(0x0d);
       break;
     case 'S':
       send_prog_str(PSTR("AVR ISP"));
       break;
     case 'V':
       send_prog_str(sw_version);
       break;
     case 'v':
       send_prog_str(hw_version);
       break;
     case 't':
       send_prog_str(devID);  //Return supported devices
       putc(0x00);  //NULL terminate supported devices array
       break;
     case 'p':
       putc('S');  //Return programmer type (serial)
       break;
     case 'x':
       getc();
       cbi(PORTD,LED);
       putc(0x0d);  //Set LED
       break;
     case 'y':
       getc();
       sbi(PORTD,LED);
       putc(0x0d);  //Clear LED
       break;
     case 'P':  //Enter programming mode
       if (dev_flags & DEV_AT89) outp(BV(MISO),PORTB);
       else outp(BV(MISO)|BV(RESET),PORTB);
       outp(BV(SCK)|BV(MOSI)|BV(RESET),DDRB);
       delay_1ms(ResetDelay);
       if (dev_flags & DEV_AT89) sbi(PORTB,RESET);
       else cbi(PORTB,RESET);
       delay_1ms(ResetDelay);  //Wait 21ms (datasheet says at least 20ms)
       if (dev_flags & DEV_AT89) {
	 spi_wr(0xac);
	 spi_wr(0x53);
	 spi_wr(0x00);
       }
       else {  //AT90S device, try and sync up SPI comms if necessary
	 i=0;
	 do {
	   spi_wr(0xac);
	   spi_wr(0x53);
	   if (spi_rd() == 0x53) i=100;  //Force exit, after sending last byte
	   else spi_clk();
	   spi_wr(0x00);
	   i++;
	 } while (i < 32);
       }
       putc(0x0d);
       break;
     case 'C':  //Write program memory (high byte)
       i=getc();
       if (dev_flags & DEV_AT89) putc('?');
       else {
	 spi_wr(0x48);
	 spi_wr(addr.byte[1]);
	 spi_wr(addr.byte[0]);
	 spi_wr(i);
	 if(!(dev_flags & DEV_PAGE)) delay_1ms(fPeriod);
	 putc(0x0d);
       }
       addr.word++;
       break;
     case 'c':  //Write program memory (low byte)
       i=getc();
       if (dev_flags & DEV_AT89) {
	 spi_wr((addr.byte[1]<<3) | 0x02);
       }
       else {
	 spi_wr(0x40);
	 spi_wr(addr.byte[1]);
       }
       spi_wr(addr.byte[0]);
       spi_wr(i);
       if(!(dev_flags & DEV_PAGE)) delay_1ms(fPeriod);
       putc(0x0d);
       break;
     case 'm':  //Write page, verify this actually works
       spi_wr(0x4c);
       spi_wr(addr.byte[1]);
       spi_wr(addr.byte[0]);
       spi_wr(0x00);
       if (device == ATmega163 || device == ATmega323)
	 delay_1ms(16);
       else
	 delay_1ms(56);  // ATmega103 @ 3.2V
       putc(0x0d);
       break;
     case 'R':  //Read program memory
       if (dev_flags & DEV_AT89) {
	 spi_wr((addr.byte[1]<<3) | 0x01);
       }
       else {
	 spi_wr(0x28);
	 spi_wr(addr.byte[1]);
       }
       spi_wr(addr.byte[0]);
       putc(spi_rd());
       if (!(dev_flags & DEV_AT89)) {
	 spi_wr(0x20);
	 spi_wr(addr.byte[1]);
	 spi_wr(addr.byte[0]);
	 putc(spi_rd());
       }
       addr.word++;
       break;
     case 'A':  //Load address
       addr.byte[1]=getc();
       addr.byte[0]=getc();
       putc(0x0d);
       break;
     case 'D':  //Write data memory
       i=getc();
       if (device == AT89S8252) {
	 spi_wr((addr.byte[1]<<3) | 0x06);
       }
       else {
	 spi_wr(0xc0);
	 spi_wr(addr.byte[1]);
       }
       spi_wr(addr.byte[0]);
       spi_wr(i);
       delay_1ms(ePeriod);
       putc(0x0d);
       addr.word++;
       break;
     case 'd':  //Read data memory
       if (device == AT89S8252) {
	 spi_wr((addr.byte[1]<<3) | 0x05);
       }
       else {
	 spi_wr(0xa0);
	 spi_wr(addr.byte[1]);
       }
       spi_wr(addr.byte[0]);
       putc(spi_rd());
       addr.word++;
       break;
     case 'L':  //Leave programming mode
       outp(0x00,DDRB);   //Pins not driven
       outp(0x00,PORTB);  //No pull ups either, Hi-Z
       putc(0x0d);
       break;
     case 'e':  //Erase device
       spi_wr(0xac);
       if (!(dev_flags & DEV_AT89)) spi_wr(0x80);
       spi_wr(0x04);
       spi_wr(0x00);
       delay_1ms(ErasePeriod);  //Wait for Chip Erase
       putc(0x0d);
       break;
     case 'l':  //Write lock bits
       i=getc();
       spi_wr(0xac);
       if (dev_flags & DEV_AT89) {
	 spi_wr((i & 0xe0) | 0x07);  //Check if this is right
	 spi_wr(0x00);
       }
       else {
	 spi_wr((i & 0x06) | 0xe0);  //Check
	 spi_wr(0xff);
	 spi_wr((i >> 1) | 0xfc);  // for ATmega163 etc. (no BLBxx yet)
       }
       delay_1ms(FuseLockPeriod);  //Wait for Lock bits to program
       putc(0x0d);
       break;
     case 'f':  //Write fuse bits, parallel programmer only ?
       putc(0x0d);
       break;
     case 'F':  //Read fuse and lock bits, parallel programmer only ?
       putc(0x00);
       break;
     case 's':  //Read device signature bytes
       i=3;
       do {
	 i--;
	 spi_wr(0x30);
	 spi_wr(0x00);
	 spi_wr(i);
	 putc(spi_rd());
       } while (i);
       break;
     case ':':  //Intended for writing fuse bits on m103,8535,4433,2333 etc
       spi_wr(getc());
       spi_wr(getc());
       spi_wr(0x00);
       spi_wr(0x00);
       delay_1ms(FuseLockPeriod);  //Wait for Lock / Fuse bits to program
       outp(0x00,DDRB);   //Pins not driven. Leave programming mode
       outp(0x00,PORTB);  //No pull ups either, Hi-Z
       putc(0x0d);
       break;
     case '.':  //At last, good idea Atmel. Universal instruction
       i=getc();
       spi_wr(i);
       spi_wr(getc());
       spi_wr(0x00);
       if (i>0x7f) {  //Write command
	 spi_wr(getc());
	 delay_1ms(FuseLockPeriod);  //Wait for Lock / Fuse bits to program
	 putc(0x0d);
       }
       else {  //Read command
	 putc(spi_rd());
       }
       outp(0x00,DDRB);   //Pins not driven. Leave programming mode
       outp(0x00,PORTB);  //No pull ups either, Hi-Z
       break;
     case 0x1b:  //ESC received, do nothing
       break;
     case '!':
       if (getc()=='!') terminal_mode();
       break;
     default:
       for(i=0;i<=strlen_P(devID);i++) {
	 if (ch == PRG_RDB(devID + i)) break;  //Character matches a device ID byte
       }
       if (i == strlen_P(devID)+1) putc('?');  //Only send if ch wasn't a device ID byte
     }
 }
}

void putc(uint8_t ch)
{
  while (!(inp(USR) & BV(UDRE))) wdt_reset();
  outp(ch,UDR);
}

uint8_t getc(void)
{
  while(!(inp(USR) & BV(RXC))) wdt_reset();
  return (inp(UDR));
}

void send_prog_str(const char *flash)
{
char ch;

  while ((ch = __lpm_inline((uint16_t) flash)) != 0) {
    putc(ch);
    flash++;
  }
}

void spi_clk(void)
{
  sbi(PORTB,SCK);
  if(cPeriod>2){
    //    outp(0x00,TCCR0);  //Stop timer
    outp(256 - cPeriod/(16000000/F_CPU),TCNT0);
    outp(BV(TOV0),TIFR);
    //    outp(BV(CS01),TCCR0);
    while(!(inp(TIFR) & BV(TOV0)));
  }
  cbi(PORTB,SCK);
  if(cPeriod>2){
    //    outp(0x00,TCCR0);
    outp(256 - cPeriod/(16000000/F_CPU),TCNT0);
    outp(BV(TOV0),TIFR);
    //    outp(BV(CS01),TCCR0);
    while(!(inp(TIFR) & BV(TOV0)));
  }
}

void spi_wr(uint8_t send)
{
  uint8_t i;

  i=0x80;
  do{
    if (send & i) sbi(PORTB,MOSI);
    else cbi(PORTB,MOSI);
    spi_clk();
    i=i>>1;
  } while(i);
}

uint8_t spi_rd(void)
{
  uint8_t i,rx;

  i=0x80;
  rx=0;
  do{
    if (bit_is_set(PINB,MISO)) rx=rx+i;
    spi_clk();
    i=i>>1;
  } while(i);
  return rx;
}
/* For test only
void put_nibble(uint8_t ch)
{
  ch = ch & 0x0f;
  if (ch > 9) ch += 'A' - 10;
  else ch += '0';
  putc(ch);
}

void put_hex(uint8_t ch)
{
  put_nibble(ch >> 4);
  put_nibble(ch);
}
*/
void delay_100us(uint8_t count)
{
  while(count) {
    outp(256 - ((F_CPU/80000)-1),TCNT0);
    outp(BV(TOV0),TIFR);
    while(!(inp(TIFR) & BV(TOV0)));
    wdt_reset();
    count--;
  }
}

void delay_1ms(uint8_t count)
{
  while(count) {
    delay_100us(10);
    count--;
  }
}

void terminal_mode(void){
  uint8_t ch;

  do {
    loop_until_bit_is_clear(EECR,EEWE);
    send_prog_str(PSTR("\r\nAtmel AVR Programmer\r\n#"));
    ch = getc();
    putc(ch);  //Echo
    if(ch=='F'){  //Set Flash and EEPROM period
      eeprom_wb(0x0001,getc()-0x30);  //NB No error checking!!
      send_prog_str(PSTR(" OK"));
    }
    else if(ch=='C'){  //Set SCK period
      eeprom_wb(0x0002,getc()-0x30);
      send_prog_str(PSTR(" OK"));
    }
    else if(ch=='f') putc(fPeriod+0x30);
    else if(ch=='e') putc(ePeriod+0x30);
    else if(ch=='c') putc(cPeriod+0x30);
  } while(ch!='Q');
  while(1);  //Force wdt to reset device
}



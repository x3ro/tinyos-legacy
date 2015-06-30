/* Chip-specific deffinition, inspired by avr includes:
 sfr_defs.h
 iom128.h
*/
/*
 * Authors:	Martin Leopold, Sidsel Jensen & Anders Egeskov Petersen, 
 *		Dept of Computer Science, University of Copenhagen
 * Date last modified: Nov 2005
 */

// Turn global interrupt flag on/off. The asm definitions are commented
// out to allow it to pass through nescc and will be replaced by the
// mangle script
#define cli() /*_asm  cli  _endasm;*/
#define sei() _asm  sei  _endasm;


// Interrupt numbers according to 8051/8052
// __vector might be an AVR-thing

#define SIG_INTERRUPT0          __vector_0
#define SIG_TIMER0              __vector_1
#define SIG_INTERRUPT1          __vector_2
#define SIG_TIMER1              __vector_3
#define SIG_SERIAL              __vector_4
#define SIG_TIMER2              __vector_5
#define SIG_ADC                 __vector_8


// Special function register (SFR) definitions 
// Gcc definition:
//#define __SFR_OFFSET
//#define _SFR_IO8(io_addr) ((io_addr) + __SFR_OFFSET)
//#define SREG      _SFR_IO8(0x3F)

// The __attribute(()) will be removed by the mangle script and
// the content x will be used to construct:
// sfr at x ...
//
// Alternative to stay within ANSI-C one could imagine using a
// structure with bit fields say struct { int P0:1 }, however the
// silly architecture of the 8051 forces us to controll whether code
// using direct or indirect addressing is generated. I can't se how
// this could be done using ANSI-C
//
// The above scheme allows nescc to parse the code and sdcc to to
// generate the appropriate code.


//sfr at 0xA8 IE; // Interrupt enable

typedef int sfr;
sfr P0 __attribute((x80));
//sfr at 0x80 P0;

sfr SP __attribute((x81));
//sfr at 0x81 SP;

sfr DPL __attribute((x82));
//sfr at 0x82 DPL;

sfr DPH __attribute((x83));
//sfr at 0x83 DPH;

sfr DPL1 __attribute((x84));
//sfr at 0x84 DPL1;

sfr DPH1 __attribute((x85));
//sfr at 0x85 DPH1;

sfr DPS __attribute((x86));
//sfr at 0x86 DPS;

sfr PCON __attribute((x87));
//sfr at 0x87 PCON;

sfr TCON __attribute((x88));
//sfr at 0x88 TCON;

sfr TMOD __attribute((x89));
//sfr at 0x89 TMOD;

sfr TL0 __attribute((x8A));
//sfr at 0x8A TL0;

sfr TL1 __attribute((x8B));
//sfr at 0x8B TL1;

sfr TH0 __attribute((x8C));
//sfr at 0x8C TH0;

sfr TH1 __attribute((x8D));
//sfr at 0x8D TH1;

sfr CKCON __attribute((x8E));
//sfr at 0x8E CKCON;

sfr P1 __attribute((x90));
//sfr at 0x90 P1;

sfr EXIF __attribute((x91));
//sfr at 0x91 EXIF;

sfr MPAGE __attribute((x92));
//sfr at 0x92 MPAGE;

sfr SCON __attribute((x98));
//sfr at 0x98 SCON;

sfr SBUF __attribute((x99));
//sfr at 0x99 SBUF;

sfr IE __attribute((xA8));
//sfr at 0xA8 IE;

sfr IP __attribute((xB8));
//sfr at 0xB8 IP;

sfr T2CON __attribute((xC8));
//sfr at 0xC8 T2CON;

sfr RCAP2L __attribute((xCA)); 
//sfr at 0xCA RCAP2L;

sfr RCAP2H __attribute((xCB));
//sfr at 0xCB RCAP2H;

sfr TL2 __attribute((xCC));
//sfr at 0xCC TL2;

sfr TH2 __attribute((xCD));
//sfr at 0xCD TH2;

sfr PSW __attribute((xD0));
//sfr at 0xD0 PSW;

sfr EICON __attribute((xD8));
//sfr at 0xD8 EICON;

sfr ACC __attribute((xE0));
//sfr at 0xE0 ACC;

sfr B __attribute((xF0));
//sfr at 0xF0 B;

sfr EIE __attribute((xE8));
//sfr at 0xE8 EIE;

sfr EIP __attribute((xF8));
//sfr at 0xF8 EIP;

sfr P0_DIR __attribute((x94));
//sfr at 0x94 P0_DIR;

sfr P0_ALT __attribute((x95));
//sfr at 0x95 P0_ALT;

sfr P1_DIR __attribute((x96));
//sfr at 0x96 P1_DIR;

sfr P1_ALT __attribute((x97));
//sfr at 0x97 P1_ALT;

sfr RADIO __attribute((xA0));
//sfr at 0xA0 RADIO;

sfr ADCCON __attribute((xA1));
//sfr at 0xA1 ADCCON;

sfr ADCDATAH __attribute((xA2));
//sfr at 0xA2 ADCDATAH;

sfr ADCDATAL __attribute((xA3));
//sfr at 0xA3 ADCDATAL;

sfr ADCSTATIC __attribute((xA4));
//sfr at 0xA4 ADCSTATIC;

sfr PWMCON __attribute((xA9));
//sfr at 0xA9 PWMCON;

sfr PWMDUTY __attribute((xAA));
//sfr at 0xAA PWMDUTY;

sfr REGX_MSB __attribute((xAB));
//sfr at 0xAB REGX_MSB;

sfr REGX_LSB __attribute((xAC));
//sfr at 0xAC REGX_LSB;

sfr REGX_CTRL __attribute((xAD));
//sfr at 0xAD REGX_CTRL;

sfr RSTREAS __attribute((xB1));
//sfr at 0xB1 RSTREAS;

sfr SPI_DATA __attribute((xB2));
//sfr at 0xB2 SPI_DATA;

sfr SPI_CTRL __attribute((xB3));
//sfr at 0xB3 SPI_CTRL;

sfr SPICLK __attribute((xB4));
//sfr at 0xB4 SPICLK;

sfr TICK_DV __attribute((xB5));
//sfr at 0xB5 TICK_DV;

sfr CK_CTRL __attribute((xB6));
//sfr at 0xB6 CK_CTRL;

/*  BIT Registers  */

/*  PSW */
typedef int sbit;

sbit CY __attribute((xD7));
//sbit at PSW^7 CY;

sbit AC __attribute((xD6));
//sbit at PSW^6 AC;

sbit F0 __attribute((xD5));
//sbit at PSW^5 F0;

sbit RS1 __attribute((xD4));
//sbit at PSW^4 RS1;

sbit RS0 __attribute((xD3));
//sbit at PSW^3 RS0;

sbit OV __attribute((xD2));
//sbit at PSW^2 OV;

sbit F1 __attribute((xD1));
//sbit at PSW^1 F1;

sbit P __attribute((xD0));
//sbit at PSW^0 P;

/*  TCON  */

sbit TF1 __attribute((x8F));
//sbit at TCON^7 TF1;

sbit TR1 __attribute((x8E));
//sbit at TCON^6 TR1;

sbit TF0 __attribute((x8D));
//sbit at TCON^5 TF0;

sbit TR0 __attribute((x8C));
//sbit at TCON^4 TR0;

sbit IE1 __attribute((x8B));
//sbit at TCON^3 IE1;

sbit IT1 __attribute((x8A));
//sbit at TCON^2 IT1;

sbit IE0 __attribute((x89));
//sbit at TCON^1 IE0;

sbit IT0 __attribute((x88));
//sbit at TCON^0 IT0;

/*  IE  */ 

sbit EA __attribute((xAF));
//sbit at IE^7 EA;

sbit ET2 __attribute((xAD));
//sbit at IE^5 ET2;

sbit ES __attribute((xAC));
//sbit at IE^4 ES;

sbit ET1 __attribute((xAB));
//sbit at IE^3 ET1;

sbit EX1 __attribute((xAA));
//sbit at IE^2 EX1;

sbit ET0 __attribute((xA9));
//sbit at IE^1 ET0;

sbit EX0 __attribute((xA8));
//sbit at IE^0 EX0;

/*  IP  */

sbit PT2 __attribute((xBD));
//sbit at IP^5 PT2;

sbit PS __attribute((xBC));
//sbit at IP^4 PS;

sbit PT1 __attribute((xBB));
//sbit at IP^3 PT1;

sbit PX1 __attribute((xBA));
//sbit at IP^2 PX1;

sbit PT0 __attribute((xB9));
//sbit at IP^1 PT0;

sbit PX0 __attribute((xB8));
//sbit at IP^0 PX0;


/*  P0  */

sbit T1 __attribute((x86));
//sbit at P0^6 T1;

sbit T0 __attribute((x85));
//sbit at P0^5 T0;

sbit INT1 __attribute((x84));
//sbit at P0^4 INT1;

sbit INT0 __attribute((x83));
//sbit at P0^3 INT0;

/*  P1  */

sbit T2 __attribute((x90));
//sbit at P1^0 T2;

/*  SCON  */

sbit SM0 __attribute((x9F));
//sbit at SCON^7 SM0;

sbit SM1 __attribute((x9E));
//sbit at SCON^6 SM1;

sbit SM2 __attribute((x9D));
//sbit at SCON^5 SM2;

sbit REN __attribute((x9C));
//sbit at SCON^4 REN;

sbit TB8 __attribute((x9B));
//sbit at SCON^3 TB8;

sbit RB8 __attribute((x9A));
//sbit at SCON^2 RB8;

sbit TI __attribute((x99));
//sbit at SCON^1 TI;

sbit RI __attribute((x98));
//sbit at SCON^0 RI;

/*  T2CON  */

sbit TF2 __attribute((xCF));
//sbit at T2CON^7 TF2;

sbit EXF2 __attribute((xCE));
//sbit at T2CON^6 EXF2;

sbit RCLK __attribute((xCD));
//sbit at T2CON^5 RCLK;

sbit TCLK __attribute((xCC));
//sbit at T2CON^4 TCLK;

sbit EXEN2 __attribute((xCB));
//sbit at T2CON^3 EXEN2;

sbit TR2 __attribute((xCA));
//sbit at T2CON^2 TR2;

sbit C_T2 __attribute((xC9));
//sbit at T2CON^1 C_T2;

sbit CP_RL2 __attribute((xC8));
//sbit at T2CON^0 CP_RL2;

/*  EICON  */

sbit SMOD1 __attribute((xDF));
//sbit at EICON^7 SMOD1;

sbit WDTI __attribute((xDB));
//sbit at EICON^3 WDTI;

/*  EIE  */

sbit EWDI __attribute((xEC));
//sbit at EIE^4 EWDI;

sbit EX5 __attribute((xEB));
//sbit at EIE^3 EX5;

sbit EX4 __attribute((xEA));
//sbit at EIE^2 EX4;

sbit EX3 __attribute((xE9));
//sbit at EIE^1 EX3;

sbit EX2 __attribute((xE8));
//sbit at EIE^0 EX2;

/*  EIP  */

sbit PWDI __attribute((xFC));
//sbit at EIP^4 PWDI;

sbit PX5 __attribute((xFB));
//sbit at EIP^3 PX5;

sbit PX4 __attribute((xFA));
//sbit at EIP^2 PX4;

sbit PX3 __attribute((xF9));
//sbit at EIP^1 PX3;

sbit PX2 __attribute((xF8));
//sbit at EIP^0 PX2;

/* RADIO */

sbit PWR_UP __attribute((xA7));
//sbit at RADIO^7 PWR_UP;

sbit DR2 __attribute((xA6));
//sbit at RADIO^6 DR2;

sbit CE __attribute((xA6));
//sbit at RADIO^6 CE;

sbit CLK2 __attribute((xA5));
//sbit at RADIO^5 CLK2;

sbit DOUT2 __attribute((xA4));
//sbit at RADIO^4 DOUT2;

sbit CS __attribute((xA3));
//sbit at RADIO^3 CS;

sbit DR1 __attribute((xA2));
//sbit at RADIO^2 DR1;

sbit CLK1 __attribute((xA1));
//sbit at RADIO^1 CLK1;

sbit DATA __attribute((xA0));
//sbit at RADIO^0 DATA;

#pragma WARN replace

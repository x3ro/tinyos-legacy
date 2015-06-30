#ifndef _H_hardware_h
#define _H_hardware_h

#include "msp430hardware.h"
#include "MSP430ADC12.h"

//#include "CC2420Const.h"
#include "hplcc2420.h"

#include "AM.h"

// Port for Sensinode Micro.4, based on Telosb port

// LEDs - OK for Micro.4, colors?
TOSH_ASSIGN_PIN(RED_LED, 6, 5);
TOSH_ASSIGN_PIN(GREEN_LED, 6, 4);
TOSH_ASSIGN_PIN(YELLOW_LED, 6, 6);


// CC2420 RADIO #defines
TOSH_ASSIGN_PIN(RADIO_CSN, 3, 0);//PLD

//#define TOSH_MAKE_RADIO_CSN_OUTPUT() TOSH_MAKE_FAKE_RADIO_CSN_OUTPUT()
//#define TOSH_SET_RADIO_CSN_PIN() TOSH_CLR_FAKE_RADIO_CSN_PIN()
//#define TOSH_CLR_RADIO_CSN_PIN() TOSH_SET_FAKE_RADIO_CSN_PIN()


//TOSH_ASSIGN_PIN(RADIO_CSN, 3, 1);//PLD


//TOSH_ASSIGN_PIN(RADIO_VREF, , );
//TOSH_ASSIGN_PIN(RADIO_RESET, , );//PLD
TOSH_ASSIGN_PIN(RADIO_FIFOP, 5, 6);//OK
TOSH_ASSIGN_PIN(RADIO_SFD, 1, 7);//OK
//TOSH_ASSIGN_PIN(RADIO_GIO0, 1, 3);//?
TOSH_ASSIGN_PIN(RADIO_FIFO, 5, 5);//OK
//TOSH_ASSIGN_PIN(RADIO_GIO1, 1, 4);//?
TOSH_ASSIGN_PIN(RADIO_CCA, 5, 4);//OK

TOSH_ASSIGN_PIN(CC_FIFOP, 5, 6);
TOSH_ASSIGN_PIN(CC_FIFO, 5, 5);
TOSH_ASSIGN_PIN(CC_SFD, 1, 7);
//TOSH_ASSIGN_PIN(CC_VREN, , );
//TOSH_ASSIGN_PIN(CC_RSTN, , );

#define TOSH_CLR_CC_RSTN_PIN()
#define TOSH_SET_CC_RSTN_PIN()
#define TOSH_SET_CC_VREN_PIN()
#define TOSH_CLR_CC_VREN_PIN()

// UART pins, OK
TOSH_ASSIGN_PIN(SOMI0, 3, 2);
TOSH_ASSIGN_PIN(SIMO0, 3, 1);
TOSH_ASSIGN_PIN(UCLK0, 3, 3);
TOSH_ASSIGN_PIN(UTXD0, 3, 4);
TOSH_ASSIGN_PIN(URXD0, 3, 5);
TOSH_ASSIGN_PIN(UTXD1, 3, 6);
TOSH_ASSIGN_PIN(URXD1, 3, 7);
TOSH_ASSIGN_PIN(UCLK1, 5, 3);
TOSH_ASSIGN_PIN(SOMI1, 5, 2);
TOSH_ASSIGN_PIN(SIMO1, 5, 1);

// ADC, overloaded with Micro.4 connector GPIO
TOSH_ASSIGN_PIN(ADC3, 6, 0);
TOSH_ASSIGN_PIN(ADC4, 6, 1);
TOSH_ASSIGN_PIN(ADC5, 6, 2);
TOSH_ASSIGN_PIN(ADC6, 6, 3);
//P6.4-5 go to LED0-1
TOSH_ASSIGN_PIN(ADC7, 6, 6);
TOSH_ASSIGN_PIN(ADC8, 6, 7);

// GIO pins, corresponsing to external connector pins
TOSH_ASSIGN_PIN(GIO3, 6, 0);
TOSH_ASSIGN_PIN(GIO4, 6, 1);
TOSH_ASSIGN_PIN(GIO5, 6, 2);
TOSH_ASSIGN_PIN(GIO6, 6, 3);
TOSH_ASSIGN_PIN(GIO7, 6, 6);
TOSH_ASSIGN_PIN(GIO8, 6, 7);
TOSH_ASSIGN_PIN(GIO9, 2, 0);
TOSH_ASSIGN_PIN(GIO10, 5, 7);


// 1-Wire, used through PLD

// FLASH, flash_select goes to the PLD
//TOSH_ASSIGN_PIN(FLASH_CS, , );//PLD

// This should work also with the M25P40 on Micro.4
// send a bit via bit-banging to the flash
void TOSH_FLASH_M25P_DP_bit(bool set) {
  if (set)
    TOSH_SET_SIMO0_PIN();
  else
    TOSH_CLR_SIMO0_PIN();
  TOSH_SET_UCLK0_PIN();
  TOSH_CLR_UCLK0_PIN();
}


// need to undef atomic inside header files or nesC ignores the directive
#undef atomic
void TOSH_SET_PIN_DIRECTIONS(void)
{
  // reset all of the ports to be input and using i/o functionality
  atomic
  {
	P1SEL = 0x00;
	P2SEL = 0x00;
	P3SEL = 0x00;
	P4SEL = 0x00;
	P5SEL = 0x00;
	// P6SEL = 0x00;

	P4DIR = 0;	/*parport input mode*/
	P3DIR &= ~0x3F; /*bus pins input*/
	P2DIR |= 0xF0;
	P2OUT |= 0xF0; /*module select none*/

	P3SEL |= (BIT6|BIT7);
	P3DIR |= BIT6;					/* Use P3.6 as TX */
	P3DIR &= ~BIT7;					/* Use P3.7 as RX */

	P5DIR &= ~(BIT2|BIT1);	/* SPI pins are hooked into these on micro.4*/

#if 0

	P1OUT = 0x00;
	P2OUT = 0x00;
	P3OUT = 0x00;
	P4OUT = 0x00;
	P5OUT = 0x00;
	P6OUT = 0x00;

	P1DIR = 0xFF;
	P2DIR = 0xFF;
	P3DIR = 0xFF;
	P4DIR = 0x00;
	P5DIR = 0xFF;
	P6DIR = 0xFF;

	P1DIR = 0x00;
	P2DIR = 0x00;
	P3DIR = 0x00;
	P4DIR = 0x00;
	P5DIR = 0x00;
	P6DIR = 0x00;

//	BCSCTL1 = 0x80; /* XT2OFF | LFXT1=low | DIVA=00 -> 1 | XT5V=0 | RSEL=000 */
//	BCSCTL2 = 0x88; /* SELMx=10 -> XT2    | DIVMx=00 -> 1 | SELS=1 -> MCLK | DIVS=00 -> 1 | DCOR=0 */
//	DCOCTL = 0x00;	/* DCO is not used */

	//P1DIR = 0xe0;
	//P1OUT = 0x00;

//	P2DIR |= 0xF0;
	P2OUT |= 1 << 4; //0xF0; /*module select none*/

	P3OUT |= 0x01; /* unselect flash module */

//	P3DIR &= ~0x3F; /*bus pins input*/

	// P4DIR = 0;	/*parport input mode*/

	/////////////////////////////////////////////////////////////////////////
	// Clear bit 1 and 2, as the HPLUSART expects this
	/////////////////////////////////////////////////////////////////////////
	P5DIR = 0xFB; /* Set RX1 (P5.2) as input pin */
//	P5DIR = 0xf9;
//	P5OUT = 0xff;

//	P6DIR = 0xff;
//	P6OUT = 0x00;
#endif

	P1IE = 0;
	P2IE = 0;

  // the commands above take care of the pin directions
  // there is no longer a need for explicit set pin
  // directions using the TOSH_SET/CLR macros

  // wait 20ms for the flash to startup
  TOSH_uwait(1024*10);
  TOSH_uwait(1024*10);

  }//atomic
}

#endif // _H_hardware_h


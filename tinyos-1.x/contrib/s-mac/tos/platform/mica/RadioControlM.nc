/*									tab:4
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye
 * Date created: 1/21/2003
 *
 * The radio for Mica consists of 3 parts:
 *   1) RFM; 2) SPI; 3) Timer/counter 2
 *
 * This module implements the radio control functions:
 *   1) Put radio into different states:
 *   	a) idle; b) sleep; c) receive; d) transmit
 *   2) Start symbol detection in idle state
 *   3) Physical carrier sense
 * 
 */

//includes uartDebug;

module RadioControlM
{
   provides {
      interface StdControl as RadControl;
      interface RadioState;
      interface CarrierSense;
      interface RadioByte;
   }
   uses {
      interface StdControl as PinControl;
      interface SlavePin;
   }
}

implementation
{

// parameters of the radio
#define BIT_TIME 200
//#define BIT_TIME 100
#define HALF_BIT_TIME (BIT_TIME / 2)
#define SAMPLE_TIME 200

// for carrier sense
#define BUSY_THRES 6

// for start symbol detection
#define MASK 0x7755775
#define STARTSYM 0x7044704
#define NUM_DISCARD 1

   // pre-amble and start symbol before each packet
   //static char start[5] = {0xcf, 0x0c, 0xcf, 0x0c, 0xcc};
   char start[5] __attribute((C)) = {0xcf, 0x0c, 0xcf, 0x0c, 0xcc};
   //static char start[9] = {0xf0, 0xff, 0x00, 0xf0, 0xf0, 0xff, 0x00, 0xf0, 0xf0};
   
   // radio states. INIT is a temperary state only at start up
   enum { SLEEP, IDLE, RECEIVE, TRANSMIT, INIT };
   
   char state;           // radio state
   uint32_t search;      // for searching start symbol
   uint16_t carrSenTime; // carrier sense time
   int16_t csBits;       // carrier sense bits
   uint8_t numOnes;      // carrier sense counter
   uint8_t numDiscard;   // number of bytes to be discarded in Rx
   char nextByte;        // tx buffer
   uint8_t txCount;      // for start symbol tx
   
   
   // initialize the radio
   command result_t RadControl.init()
   {
      //uartDebug_init();
      call PinControl.init();
      cbi(TIMSK, TOIE2); // disable timer 2 overflow interrupt
      state = INIT; // just for changing to idle state
      call RadioState.idle();
	
      return SUCCESS;
   }
   
   
   command result_t RadControl.start()
   {
      return SUCCESS;
   }
   
   
   command result_t RadControl.stop()
   {
      return SUCCESS;
   }
   
   
   // set radio into idle state. Automatically detect start symbol
   command result_t RadioState.idle()
   {
      if (state == IDLE) return SUCCESS;
      // stop timer/counter 2
      outp(0x00, TCCR2); // stop SPI clock after tx/rx - important
      cbi(TIMSK, OCIE2); // disable compare match interrupt
      // turn off SPI
      outp(0x00, SPCR);
      if (state == RECEIVE || state == TRANSMIT) {
         call SlavePin.high(FALSE);
      }
      //set RFM to Rx mode
      TOSH_SET_RFM_CTL0_PIN();
      TOSH_SET_RFM_CTL1_PIN();
      TOSH_CLR_RFM_TXD_PIN();
      // clear state variables
      state = IDLE;
      search = 0;
      carrSenTime = 0; // don't start carrier sense by default
      numDiscard = 0;
      // start timer/counter 2
      outp(0x09, TCCR2); // clear timer on compare match, no prescale
      outp(SAMPLE_TIME, OCR2); // set compare register
      outp(0x00, TCNT2); // clear current counter value
      sbi(TIMSK, OCIE2); // enable compare match interupt
      return SUCCESS;
   }
   
   
   // set radio into sleep mode: can't Tx or Rx
   command result_t RadioState.sleep()
   {
      if (state == SLEEP) return SUCCESS;
      // stop timer/counter 2
      outp(0x00, TCCR2);
      cbi(TIMSK, OCIE2); // disable timer 2 compare match interrupt
      // turn off SPI
      outp(0x00, SPCR);
      if (state != IDLE) {
         call SlavePin.high(FALSE);
      }
      // set RFM to sleep mode
      TOSH_CLR_RFM_TXD_PIN();
      TOSH_CLR_RFM_CTL0_PIN();
      TOSH_CLR_RFM_CTL1_PIN();
      state = SLEEP;
      return SUCCESS;
   }
   
   
	// start sending a new packet. Automatically send start symbol first
   command result_t RadioByte.startTx()
   {
      char temp;
      outp(0x00, TCCR2);  // stop timer
      cbi(TIMSK, OCIE2);  // disable compare match interrupt
      // turn off SPI
      outp(0x00, SPCR);
      if (state != IDLE && state != SLEEP) {
         call SlavePin.high(FALSE);
      }
      state = TRANSMIT;
      nextByte = start[1]; // buffer second byte of start symbol
      txCount = 2;
      //set RFM to Tx mode
      TOSH_CLR_RFM_CTL0_PIN();
      TOSH_SET_RFM_CTL1_PIN();
      // start SPI
      temp = inp(SPSR);  // clear possible pending SPI interrupt
      outp(start[0], SPDR);  // put first byte into SPI data register
      outp(0xc0, SPCR);  // enable SPI and SPI interrupt
      call SlavePin.low();
      //start timer/counter 2 to provide clock to SPI
      outp(0, TCNT2);
      outp(HALF_BIT_TIME, OCR2);
      sbi(DDRB, 7);   // set PB7 as output to provide clock signal to SPI
      cbi(PORTB, 7);  // set initial clock signal to low
      outp(0x19, TCCR2);  // toggle PB7 (OC2) on compare match
      return SUCCESS;
   }
   
   
	// send next byte
   command result_t RadioByte.txNextByte(char data)
   {
      nextByte = data;
      return SUCCESS;
   }


	// start carrier sense
   command result_t CarrierSense.start(uint16_t numBits)
   {
      if (state != IDLE) return FAIL;
      csBits = 0;
      numOnes = 0;
      carrSenTime = numBits;
      return SUCCESS;
   }
	

	// default do-nothing handler for carrier sense
   default event result_t CarrierSense.channelIdle()
   {
      return SUCCESS;
   }


   default event result_t CarrierSense.channelBusy()
   {
      return SUCCESS;
   }
   
   
   event result_t SlavePin.notifyHigh()
   {
      return SUCCESS;
   }


   /* Interrupt handler for SPI.
    * The signal handler disables globle interrupts by default.
    */
   TOSH_SIGNAL(SIG_SPI)
   {
      char data;
      data = inp(SPDR);
      if (state == TRANSMIT) {
         outp(nextByte, SPDR);  // send buffered byte
         if (txCount < sizeof(start)) {
            nextByte = start[txCount];
            txCount++;
         } else {
            signal RadioByte.txByteReady(); // ask a byte from upper layer
         }
      } else if (state == RECEIVE) {
         outp(0, SPDR);
         if (numDiscard < NUM_DISCARD) {
            numDiscard++;
            //uartDebug_txByte(data);
         } else {
            signal RadioByte.rxByteDone(data);
            //uartDebug_txByte(data);
         }
      }		
   }


   /* Interrupt handler for timer/counter 2 compare match.
    * The signal handler disables globle interrupts by default.
    * This interrupt happens only when radio is in idle state.
    */
   TOSH_SIGNAL(SIG_OUTPUT_COMPARE2)
   {
      char bit;
      if (state != IDLE) return;
      bit = TOSH_READ_RFM_RXD_PIN();
      // search for start symbol
      search = (search << 1) | bit;
      if ((search & MASK) == STARTSYM){  // start symbol detected
         cbi(TIMSK, OCIE2); // disable compare match interrupt
         outp(0, TCCR2); // stop timer
         outp(HALF_BIT_TIME, OCR2); // for SPI receiving
         outp(35, TCNT2);  // may change the level of PB7
         sbi(DDRB, 7);  // set port B pin 7 as output
         cbi(PORTB, 7); // set port B pin 7 to high
         // clear possible pending SPI interrupt
         bit = inp(SPSR);
         outp(0, SPDR);
         // select SPI (ss low)
         call SlavePin.low();
         // wait for a rising edge. need to read two 1s for noise rejection
         bit = 0;
         do {
            if (TOSH_READ_RFM_RXD_PIN()) bit++;
            else bit = 0;
         } while (bit < 2);
         // start counter and SPI to receive data
         // following line randomly changes level of PB7 on ATmega103,
         // but not on ATmega128
         outp(0x19, TCCR2); // toggle OC2 (PB7) on compare match
         state = RECEIVE;
         // PINB can't be correctly read if immediately after starting timer
         if (inp(PINB) & 0x80) outp(0xc8, SPCR);
         else outp(0xc0, SPCR);
         //uartDebug_txByte(inp(PINB));
         //uartDebug_txByte(inp(TCNT2));
         // signal upper layer to prepare for reception
         if (carrSenTime > 0) {  // MAC is in Carrier Sense state
            carrSenTime = 0;  // stop carrier sense
            signal CarrierSense.channelBusy();
         }
         if (signal RadioByte.startSymDetected() == FAIL) {
            call RadioState.idle();
         }
      } else {
         bit &= TOSH_READ_RFM_RXD_PIN();  // for noise rejection
         if (carrSenTime > 0){  // carrier sense started
            numOnes += bit;
            if (csBits < 0) numOnes--;
            csBits = (csBits << 1) | bit;

            if (numOnes > BUSY_THRES) {
               // channel busy is detected
               carrSenTime = 0;  // stop carrier sense
               signal CarrierSense.channelBusy();
            } else {
               carrSenTime--;
               if (carrSenTime == 0) {
                  // channel idle is detected
                  signal CarrierSense.channelIdle();
               }
            }
         }
      }
   }
   
}  // end of implementation

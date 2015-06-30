/*
 * Copyright (c) 2005 Hewlett-Packard Company
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
 * Authors:  Steve Ayer
 *           April 2005
 *           rewritten by s.a. to account for a.c.'s rewritten interface, 3/06
 */

includes DMA;
#include "PrintfRadio.h"
//includes Message;

module TestDMA_M {
    provides{
	interface StdControl;
//	interface ParamView;
    }
    uses {
	interface DMA as DMA0;
	interface DMA as DMA1;
	interface DMA as DMA2;
	//	interface ADC as ADC0;

	/* telnet stuff */
/*	interface StdControl as IPStdControl;
	interface StdControl as TelnetStdControl;
	interface StdControl as PVStdControl;
	interface UIP;
	interface Client;
	interface TCPClient;
*/
	/* end telnet stuff */
	interface Leds;
	//	interface Telnet;     
	interface Timer as yTimer;
	interface Timer as gTimer;
	interface Timer as rTimer;
    }

    uses interface PrintfRadio;
}

implementation {

#define MESSAGE_MAX_LENGTH 128

  uint8_t dma_transfers, write_step, status = 0;
  uint16_t inbuf0[256], inbuf1[256], inbuf2[256], *curr0, *curr1, *curr2;

    uint16_t adcifg_count = 0;

/*    void setupDMA() {
	  call DMA0.init();
	  call DMA1.init();
	  call DMA2.init();

	atomic {
	  //DMA0DA = (uint16_t *)inbuf0;       // directly to ram
	  //DMA1DA = (uint16_t *)inbuf1;
	  //DMA2DA = (uint16_t *)inbuf2;
	  
	  call DMA0.setDestinationAddress(inbuf0);
	  call DMA1.setDestinationAddress(inbuf1);
	  call DMA2.setDestinationAddress(inbuf2);

	  DMA0SZ = sizeof(inbuf0) >> 1;
	  DMA1SZ = sizeof(inbuf1) >> 1;
	  DMA2SZ = sizeof(inbuf2) >> 1;

	  DMACTL1 |= 0x0002;  // round-robin
	}
    }
*/
  void setupDMA() {
    call DMA0.init();
    call DMA1.init();
    call DMA2.init();

    atomic {
      call DMA0.setDestinationAddress(inbuf0);
      call DMA1.setDestinationAddress(inbuf1);
      call DMA2.setDestinationAddress(inbuf2);

      call DMA0.setBlockSize(sizeof(inbuf0) >> 1);
      call DMA1.setBlockSize(sizeof(inbuf1) >> 1);
      call DMA2.setBlockSize(sizeof(inbuf2) >> 1);

      SET_FLAG(DMACTL1, ROUNDROBIN);  // round-robin
    }

  }
	
/*    void sampleADC() {
      call DMA0.ADCinit();   // this doesn't really need to be parameterized
	
	ADC12CTL1 &= ~ADC12SSEL_3;         // clr clk from smclk
	ADC12CTL1 |= ADC12SSEL_0;         // clk from aclk

	ADC12CTL1 |= ADC12DIV_7;         // divide clk by 8
	// sample and hold time four adc12clk cycles
	ADC12CTL0 |= SHT0_0;   

	// conversion start address
	ADC12CTL1 |= CSTARTADD_0;      // really a zero, for clarity
	// set input channel
	call DMA0.ADCsetMemRegisterInputChannel(0, 3);  // memreg 0 <= channel 0  the way shimmer is wired, really not a very useful interface
	call DMA0.ADCsetMemRegisterInputChannel(1, 4);  // memreg 1 <= channel 1
	call DMA0.ADCsetMemRegisterInputChannel(2, 5);  // memreg 2 <= channel 2

	// set up for three adc channels -> three adcmem regs -> three dma channels in round-robin
	// clear init defaults first
	ADC12CTL1 &= ~CONSEQ_2;     // clear default repeat single channel
	//	ADC12MCTL0 &= ~INCH_1;      // input channel for mem0 is a0
	ADC12CTL1 |= CONSEQ_3;      // repeat sequence of channels
    
	// test to try channel-mapping, though it's supposed to be auto in repeat-sequence...
 	ADC12MCTL2 |= EOS;       //sez "this is the last reg" 

	setupDMA();

	call DMA0.beginTransfer();
	call DMA1.beginTransfer();
	call DMA2.beginTransfer();

	TOSH_SET_ACCEL_SLEEP_N_PIN();    // wakes up accel board

	call DMA0.ADCbeginConversion();
	
	*curr0 = ADC12MEM0;
	*curr0 = 0;
	*curr1 = ADC12MEM1;
	*curr1 = 0;
	*curr2 = ADC12MEM2;
	*curr2 = 0;

    }
*/

  void sampleADC() {
    call DMA0.ADCinit();   // this doesn't really need to be parameterized

    atomic{
      CLR_FLAG(ADC12CTL1, ADC12SSEL_3);         // clr clk from smclk
      SET_FLAG(ADC12CTL1, ADC12SSEL_3);         // clk from aclk
      
      SET_FLAG(ADC12CTL1, ADC12DIV_4);         // divide clk by 8
      // sample and hold time four adc12clk cycles
      SET_FLAG(ADC12CTL0, SHT0_0);   

      // set reference voltage to 2.5v
      SET_FLAG(ADC12CTL0, REF2_5V);   

      // conversion start address
      SET_FLAG(ADC12CTL1, CSTARTADD_0);      // really a zero, for clarity
    }
    // set input channel
    /*    call DMA0.ADCsetMemRegisterInputChannel(0, 3);  // memreg 0 <= channel 0
    call DMA0.ADCsetMemRegisterInputChannel(1, 4);  // memreg 1 <= channel 1
    call DMA0.ADCsetMemRegisterInputChannel(2, 5);  // memreg 2 <= channel 2
    */
    SET_FLAG(ADC12MCTL0, INCH_3);
    SET_FLAG(ADC12MCTL1, INCH_4);
    SET_FLAG(ADC12MCTL2, INCH_5);
    SET_FLAG(ADC12MCTL2, EOS);       //sez "this is the last reg" 

    /* set up for three adc channels -> three adcmem regs -> three dma channels in round-robin */
    /* clear init defaults first */
    CLR_FLAG(ADC12CTL1, CONSEQ_2);     // clear default repeat single channel

    SET_FLAG(ADC12CTL1, CONSEQ_3);      // repeat sequence of channels
    
    SET_FLAG(ADC12MCTL2, EOS);       // sez "this is the last reg" 

    setupDMA();

    call DMA0.beginTransfer();
    call DMA1.beginTransfer();
    call DMA2.beginTransfer();

    call DMA0.ADCbeginConversion();
	
    *curr0 = ADC12MEM0;
    *curr0 = 0;
    *curr1 = ADC12MEM1;
    *curr1 = 0;
    *curr2 = ADC12MEM2;
    *curr2 = 0;

  }

    task void adcResults() { 
    } 

    task void dma0Results() { 
    }	 
    
    task void dma1Results() { 
    }	 

    task void dma2Results() { 
      	call Leds.greenToggle();

        call DMA0.ADCstopConversion();
            {
                uint16_t i = 0;
                uint16_t max0 = 0; 
                uint16_t max1 = 0; 
                uint16_t max2 = 0; 

                for (i = 0; i < 256; ++i) {
                    if (inbuf0[i] > max0)  max0 = inbuf0[i];
                    if (inbuf1[i] > max1)  max1 = inbuf1[i];
                    if (inbuf2[i] > max2)  max2 = inbuf2[i];
                }
                printfRadio("dma2: %u %u %u", max0, max1, max2);
            }
        call DMA0.ADCbeginConversion();
    }	
    
/*    task void dma2Results() { 
        dma_transfers++;
        call DMA0.ADCstopConversion();
        if(dma_transfers == 255){
        	// reset transfer destinations
        	//	call DMA0.ADCstopConversion();
            {
                uint16_t i = 0;
                uint16_t max0 = 0; 
                uint16_t max1 = 0; 
                uint16_t max2 = 0; 

                for (i = 0; i < 256; ++i) {
                    if (inbuf0[i] > max0)  max0 = inbuf0[i];
                    if (inbuf1[i] > max1)  max1 = inbuf1[i];
                    if (inbuf2[i] > max2)  max2 = inbuf2[i];
                }
                printfRadio("dma2[%u]: %u %u %u", dma_transfers, max0, max1, max2);
            }

        	atomic {
                dma_transfers = 0;

                DMA0DA = (uint16_t *)inbuf0;
                DMA1DA = (uint16_t *)inbuf1;
                DMA2DA = (uint16_t *)inbuf2;
            }
            //	if(server_present){
	        //	call DMA0.ADCbeginConversion();

        	call Leds.greenToggle();
        	//	  call TCPClient.connect(63, 118, 194, 100, 5067);
        	//	}
        }
        call DMA0.ADCbeginConversion();
    }*/	
    
    command result_t StdControl.init() {
      //	howbig = MESSAGE_MAX_LENGTH;
      
//	call PVStdControl.init();
// 	call TelnetStdControl.init();
//	call IPStdControl.init();

	TOSH_MAKE_ACCEL_SLEEP_N_OUTPUT();         // sleep for accel
	TOSH_SEL_ACCEL_SLEEP_N_IOFUNC();

	TOSH_MAKE_ADC_ACCELZ_INPUT();         // clock
	TOSH_SEL_ADC_ACCELZ_MODFUNC();

	TOSH_MAKE_ADC_ACCELY_INPUT();         // clock
	TOSH_SEL_ADC_ACCELY_MODFUNC();

	TOSH_MAKE_ADC_ACCELX_INPUT();         // clock
	TOSH_SEL_ADC_ACCELX_MODFUNC();
	/*
	TOSH_MAKE_UTXD0_OUTPUT();         // sleep for accel
	TOSH_SEL_UTXD0_IOFUNC();
	*/
	/*
	TOSH_MAKE_ADC0_INPUT();         // clock
	TOSH_SEL_ADC0_MODFUNC();

	TOSH_MAKE_ADC1_INPUT();         // clock
	TOSH_SEL_ADC1_MODFUNC();

	TOSH_MAKE_ADC2_INPUT();         // clock
	TOSH_SEL_ADC2_MODFUNC();
	*/
	
	SVSCTL |= VLD_14;
	SVSCTL &= ~PORON;
	
	dma_transfers = 0;

	memset(inbuf0, 0, sizeof(inbuf0));
	curr0 = inbuf0;
	memset(inbuf1, 0, sizeof(inbuf1));
	curr1 = inbuf1;
	memset(inbuf2, 0, sizeof(inbuf2));
	curr2 = inbuf2;
	call Leds.init();

	return SUCCESS;
    }

    command result_t StdControl.start() {
//	call IPStdControl.start();
//	call TelnetStdControl.start();

	sampleADC();

	//	call yTimer.start(TIMER_REPEAT, 250);
	return SUCCESS;
    }

    command result_t StdControl.stop() {
      //	call TelnetStdControl.stop();
    //	return call IPStdControl.stop();
      return SUCCESS;
    }

    event result_t yTimer.fired() {
      //	call Leds.yellowToggle();
	//	DMA0CTL |= DMAREQ;    // software start by setting this bit
	
	return SUCCESS;
    }

    event result_t gTimer.fired() {
//	call Leds.greenToggle();
	//	DMA0CTL |= DMAREQ;    // software start by setting this bit
	
	return SUCCESS;
    }

    event result_t rTimer.fired() {
	call Leds.redToggle();
	
	return SUCCESS;
    }

    async event void DMA0.transferComplete() {
	/*	ADC12IE = 0;   // stop 
	ADC12CTL0 = 0;   // stop 
	DMA0CTL &= ~DMAEN;
	*/
      //      TOSH_TOGGLE_UTXD0_PIN();
	post dma0Results();
    }

    async event void DMA1.transferComplete() {
      //      TOSH_TOGGLE_UTXD0_PIN();
      post dma1Results();
    }

    async event void DMA2.transferComplete() {
      //      TOSH_TOGGLE_UTXD0_PIN();
      post dma2Results();
    }

    async event void DMA0.ADCInterrupt(uint8_t regnum) {
      //      call Leds.yellowToggle();
	atomic {
	    if(adcifg_count++ > 255){
		ADC12CTL0 = 0;
		ADC12IE = 0;
		//		post adcResults();
	    }
	}	       
    } 
    /*
    command result_t connect( uint8_t octet1, uint8_t octet2, uint8_t octet3, uint8_t octet4, uint16_t port );
    command result_t write( const uint8_t *buf, uint16_t len );
    command result_t close();
    */
/*    event void TCPClient.connectionMade( uint8_t status ) {
      write_step = 0;
      call Leds.redOff();
      call TCPClient.write(inbuf0, 128);
      call Leds.yellowOn();
    }
*/
    /*
     * version with 128 byte sends
     */
/*    event void TCPClient.writeDone(){
      call Leds.yellowOff();

      write_step++;
      switch (write_step) {
      case 1:
	call Leds.yellowOn();
	call TCPClient.write(inbuf0 + 64, 128);
	break;
      case 2:
	call Leds.yellowOn();
	call TCPClient.write(inbuf0 + 128, 128);
	break;
      case 3:
	call Leds.yellowOn();
	call TCPClient.write(inbuf0 + 192, 128);
	break;
      case 4:
	call Leds.yellowOn();
	call TCPClient.write(inbuf1, 128);
	break;
      case 5:
	call Leds.yellowOn();
	call TCPClient.write(inbuf1 + 64, 128);
	break;
      case 6:
	call Leds.yellowOn();
	call TCPClient.write(inbuf1 + 128, 128);
	break;
      case 7:
	call Leds.yellowOn();
	call TCPClient.write(inbuf1 + 192, 128);
	break;
      case 8:
	call Leds.yellowOn();
	call TCPClient.write(inbuf2, 128);
	break;
      case 9:
	call Leds.yellowOn();
	call TCPClient.write(inbuf2 + 64, 128);
	break;
      case 10:
	call Leds.yellowOn();
	call TCPClient.write(inbuf2 + 128, 128);
	break;
      case 11:
	call Leds.yellowOn();
	call TCPClient.write(inbuf2 + 192, 128);
	break;
      default:
	call TCPClient.close();

	write_step = 0;

	call DMA0.ADCbeginConversion();
	break;
      }
    }
*/
/*    event   void     TCPClient.dataAvailable( uint8_t *buf, uint16_t len ){}

    event   void     TCPClient.connectionFailed( uint8_t reason ){  // Reason = which end died
      status = reason;
      call Leds.redOn();
      //      call TCPClient.close();
      //      server_present = 0;
      //      call DMA0.ADCbeginConversion();
    }
*/
    async event void DMA1.ADCInterrupt(uint8_t regnum) {}
    async event void DMA2.ADCInterrupt(uint8_t regnum) {}

//    event void Client.connected( bool isConnected ) {
//    }

/*    const struct Param s_ADCRegs[] = {
  	{ "svsreg",     PARAM_TYPE_HEX8, &SVSCTL },
	{ "adcctl0",    PARAM_TYPE_HEX16, &ADC12CTL0 },
	{ "adcctl1",    PARAM_TYPE_HEX16, &ADC12CTL1 },
	{ "adcmem0",    PARAM_TYPE_HEX16, &ADC12MEM0},
	{ "adcmem1",    PARAM_TYPE_HEX16, &ADC12MEM1},
	{ "adcmem2",    PARAM_TYPE_HEX16, &ADC12MEM2},
	{ "adcmemctl",    PARAM_TYPE_HEX8, &ADC12MCTL0},
	{ "adciv",    PARAM_TYPE_HEX16, &ADC12IV},
	{ "adcifg",    PARAM_TYPE_HEX16, &ADC12IFG},
	{ "adcie",    PARAM_TYPE_HEX16, &ADC12IE},
	{ "adcifgcount",    PARAM_TYPE_HEX16, &adcifg_count},
	//	{ "p6dir",    PARAM_TYPE_HEX8, &P6DIR},
	//	{ "p6sel",    PARAM_TYPE_HEX8, &P6SEL},
	{ NULL, 0, NULL }
    };
    const struct Param s_DMARegs[] = {
	{ "dmactl0",    PARAM_TYPE_HEX16, &DMACTL0 },
	{ "dmactl1",    PARAM_TYPE_HEX16, &DMACTL1 },
	{ "dma0ctl",    PARAM_TYPE_HEX16, &DMA0CTL},
	{ "dma1ctl",    PARAM_TYPE_HEX16, &DMA1CTL},
	{ "dma2ctl",    PARAM_TYPE_HEX16, &DMA2CTL},
	{ "dma0sa",    PARAM_TYPE_HEX16, &DMA0SA},
	{ "dma0da",    PARAM_TYPE_HEX16, &DMA0DA},
	{ "dma0sz",    PARAM_TYPE_HEX16, &DMA0SZ},
	{ "dma1sa",    PARAM_TYPE_HEX16, &DMA1SA},
	{ "dma1da",    PARAM_TYPE_HEX16, &DMA1DA},
	{ "dma1sz",    PARAM_TYPE_HEX16, &DMA1SZ},
	{ "dma2sa",    PARAM_TYPE_HEX16, &DMA2SA},
	{ "dma2da",    PARAM_TYPE_HEX16, &DMA2DA},
	{ "dma2sz",    PARAM_TYPE_HEX16, &DMA2SZ},
	{ NULL, 0, NULL }
    };

    const struct Param s_DMA0Output[] = {
	{ "status",    PARAM_TYPE_HEX8, &status },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[0] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[1] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[2] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[3] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[4] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[5] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[6] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[7] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[8] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[9] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[10] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[11] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[12] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[13] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[14] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[15] },
	{ "",    PARAM_TYPE_HEX16, &inbuf0[16] },
	{ NULL, 0, NULL }
    };
    const struct Param s_DMA1Output[] = {
	{ "",    PARAM_TYPE_HEX16, &inbuf1[0] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[1] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[2] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[3] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[4] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[5] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[6] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[7] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[8] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[9] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[10] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[11] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[12] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[13] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[14] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[15] },
	{ "",    PARAM_TYPE_HEX16, &inbuf1[16] },
	{ NULL, 0, NULL }
    };
    const struct Param s_DMA2Output[] = {
	{ "",    PARAM_TYPE_HEX16, &inbuf2[0] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[1] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[2] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[3] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[4] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[5] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[6] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[7] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[8] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[9] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[10] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[11] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[12] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[13] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[14] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[15] },
	{ "",    PARAM_TYPE_HEX16, &inbuf2[16] },
	{ NULL, 0, NULL }
    };

    struct ParamList g_ADCRegsList = { "adcregs", &s_ADCRegs[0] };
    struct ParamList g_DMA0OutList = { "output0", &s_DMA0Output[0] };
    struct ParamList g_DMA1OutList = { "output1", &s_DMA1Output[0] };
    struct ParamList g_DMA2OutList = { "output2", &s_DMA2Output[0] };
    struct ParamList g_DMARegsList = { "dmaregs", &s_DMARegs[0] };
*/
/*    command result_t ParamView.init(){
      signal ParamView.add( &g_ADCRegsList );
      signal ParamView.add( &g_DMARegsList );
      signal ParamView.add( &g_DMA0OutList );
      signal ParamView.add( &g_DMA1OutList );
      signal ParamView.add( &g_DMA2OutList );
      return SUCCESS;
    }
*/
}

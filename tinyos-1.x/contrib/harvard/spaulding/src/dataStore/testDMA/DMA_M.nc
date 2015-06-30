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
 *
 * A parameterized interface for DMA
 * You should use this as 'foo.DMA -> DMA[unique("DMA")]'
 *
 * Authors:  Steven Ayer
 *           April 2005
 ////////////////////////////////////////////////////////////////////////
 Revised: Stephen Linder October 19
 
 Added methods to support DMA transfers to SD card over an SPI interface.
 
 */

includes DMA;
 
module DMA_M {
  provides interface DMA[uint8_t id];
}
implementation {
  MSP430REG_NORACE(ADC12IV);

  MSP430REG_NORACE(DMACTL0);
  MSP430REG_NORACE(DMACTL1);

  MSP430REG_NORACE(DMA0CTL);
  MSP430REG_NORACE(DMA1CTL);
  MSP430REG_NORACE(DMA2CTL);

  MSP430REG_NORACE(DMA0SA);
  MSP430REG_NORACE(DMA1SA);
  MSP430REG_NORACE(DMA2SA);

  MSP430REG_NORACE(DMA0DA);
  MSP430REG_NORACE(DMA1DA);
  MSP430REG_NORACE(DMA2DA);

  MSP430REG_NORACE(DMA0SZ);
  MSP430REG_NORACE(DMA1SZ);
  MSP430REG_NORACE(DMA2SZ);

  uint8_t ch_id;
  
  volatile uint16_t* channelSourceRegisters[] = 	 {&DMA0SA, &DMA1SA, &DMA2SA};
  volatile uint16_t* channelDestinationRegisters[] = {&DMA0DA, &DMA1DA, &DMA2DA};
  volatile uint16_t* channelSizeRegisters[] = 		 {&DMA0SZ, &DMA1SZ, &DMA2SZ};
  volatile uint16_t* channelControlRegisters[] =     {&DMA0CTL, &DMA1CTL, &DMA2CTL};
  // number of bits left that the trigger mask needs to be shifted
  // for each channel
  uint8_t channelTriggerBitShift[] = {DMA0TSEL_SHIFT, DMA1TSEL_SHIFT, DMA2TSEL_SHIFT};
  
  
  command void DMA.ADCinit[uint8_t id]() {
    atomic {
      ADC12CTL0 = ADC12ON;       // self-explanatory

      ADC12CTL0 |= REFON;               // reference generator on

      ADC12CTL0 |= MSC;                 // multiple conversions without more triggers

      CLR_FLAG(ADC12CTL0, SHT0_15);     //clear sample and hold time bits
      CLR_FLAG(ADC12CTL0, SHT1_15);
      ADC12CTL1 = SHS_0 + SHP + CONSEQ_2;     // s&h from adc12sc bit; sample from sampling timer;  repeat single-channel conversion
      ADC12CTL1 |= ADC12SSEL_3;         // clk from smclk
	
      ADC12MCTL0 |= INCH_0;             // use input channel 1 for all mem regs

      ADC12MCTL0 |= SREF_1;             // Vref = Vref+ and avss-
      ADC12MCTL1 |= SREF_1;             // Vref = Vref+ and avss-
      ADC12MCTL2 |= SREF_1;             // Vref = Vref+ and avss-
    }
  }
	
  command void DMA.ADCbeginConversion[uint8_t id]() {
    atomic{
      ADC12CTL0 |= ENC + ADC12SC;   // start conversion
    }
  }

  command void DMA.ADCstopConversion[uint8_t id]() {
    atomic ADC12CTL0 &= ~(ENC + ADC12SC);
  }
  /**
   * each of 16 mem registers selects its own input channel, 8 external, 4 internal
   * 
   **/
  command void DMA.ADCsetMemRegisterInputChannel[uint8_t id](uint8_t reg_num, uint8_t ch) {
    uint16_t mreg = ADC12MCTL0;
    mreg += reg_num;
	
    mreg |= ch;
  }

  command void DMA.init[uint8_t id]() {
    uint16_t inbuf[256];

    switch (id) {
    case 0:
      atomic {
	DMA0SA = ADC12MEM0_;               // src first adc buf register

	DMA0SZ = sizeof(inbuf) >> 1;       // oddly, setting this to 1 breaks code;  this is nominal word block
	// default is word transfer, set in DMA0CTL with DMASRCBYTE and DMADSTBYTE == 0

	DMACTL0 = DMA0TSEL_3 << 1;         // trigger from ADC12IFGx

	// repeat single transfer (no ie reset), increment dest addr, static src addr
	DMA0CTL = DMADT_4 + DMADSTINCR_3 + DMASRCINCR_0;    
	
      }
      break;
    case 1:
      atomic{
	DMA1SA = ADC12MEM1_;               // src next adc buf register
	//	  DMA1DA = inbuf1;           // set dest thus in app.
	DMA1SZ = sizeof(inbuf) >> 1;       // see dma0sz

	DMACTL0 |= DMA1TSEL_3 << 1;                     // trigger from ADC12IFGx

	DMA1CTL = DMADT_4 + DMADSTINCR_3 + DMASRCINCR_0;    
      }
      break;
    case 2:
      atomic{
	DMA2SA = ADC12MEM2_;               // src next adc buf register
	//   DMA2DA = inbuf2;                  // set dest thus in application
	DMA2SZ = sizeof(inbuf) >> 1;                        // see dma0sz

	DMACTL0 |= DMA2TSEL_3 << 1;

	DMA2CTL = DMADT_4 + DMADSTINCR_3 + DMASRCINCR_0;    
      }
      break;
    }
  }

  command void DMA.beginTransfer[uint8_t id]() {
    if(id == 0){
      SET_FLAG(DMA0CTL, DMAEN + DMAIE);      // enabled and interrupt enabled
      CLR_FLAG(DMA0CTL, DMAIFG);
    }
    else if(id == 1){
      SET_FLAG(DMA1CTL, DMAEN + DMAIE);      // enabled and interrupt enabled
      CLR_FLAG(DMA1CTL, DMAIFG);
    }
    else if(id == 2){
      SET_FLAG(DMA2CTL, DMAEN + DMAIE);      // enabled and interrupt enabled
      CLR_FLAG(DMA2CTL, DMAIFG);
    }
  }

  // this one requires some interrupt manipulation if in progress; use after transfer completes
  command void DMA.stopTransfer[uint8_t id]() {
    if(id == 0)
      CLR_FLAG(DMA0CTL, DMAEN + DMAIE);      // enable and interrupt enable
    else if(id == 1)
      CLR_FLAG(DMA1CTL, DMAEN + DMAIE);      // enable and interrupt enable
    else if(id == 2)
      CLR_FLAG(DMA2CTL, DMAEN + DMAIE);      // enable and interrupt enable
  }

  command void DMA.setSourceAddress[uint8_t id](uint16_t src){
    if(id == 0)
      DMA0SA = src;
    else if(id == 1)
      DMA1SA = src;
    else if(id == 2)
      DMA2SA = src;
  }

  command void DMA.setDestinationAddress[uint8_t id](uint16_t dest){
    if(id == 0)
      DMA0DA = dest;
    else if(id == 1)
      DMA1DA = dest;
    else if(id == 2)
      DMA2DA = dest;
  }
    
  // size is number of bytes or words, depending upon dmaxctl; 
  command void DMA.setBlockSize[uint8_t id](uint16_t size){
    if(id == 0)
      DMA0SZ = size;
    else if(id == 1)
      DMA1SZ = size;
    else if(id == 2)
      DMA2SZ = size;
  }

  /**
   * DMADT_0 transfer mode 0: single
   * DMADT_1 transfer mode 1: block 
   * DMADT_2 transfer mode 2: interleaved 
   * DMADT_3 transfer mode 3: interleaved 
   * DMADT_4 transfer mode 4: single, repeat 
   * DMADT_5 transfer mode 5: block, repeat 
   * DMADT_6 transfer mode 6: interleaved, repeat 
   * DMADT_7 transfer mode 7: interleaved, repeat 
   **/
  command void DMA.setTransferMode[uint8_t id](uint16_t mode){
    if(id == 0){
      CLR_FLAG(DMA0CTL, DMADT_7);
      SET_FLAG(DMA0CTL, mode);
    }
    else if(id == 1){
      CLR_FLAG(DMA1CTL, DMADT_7);
      SET_FLAG(DMA1CTL, mode);
    }
    else if(id == 2){
      CLR_FLAG(DMA2CTL, DMADT_7);
      SET_FLAG(DMA2CTL, mode);
    }
  }

  // sets round-robin bit
  command void DMA.setChannelPriority[uint8_t id](bool roundrobin){
    if(roundrobin)
      SET_FLAG(DMACTL1, ROUNDROBIN);
    else
      CLR_FLAG(DMACTL1, ROUNDROBIN);
  }

  command void DMA.setDestinationAddressIncrement[uint8_t id](addressIncrement ai){
    if(id == 0){
      SET_FLAG(DMA0CTL, ai << 8);
    }
    else if(id == 1){
      SET_FLAG(DMA1CTL, ai << 8);
    }
    else if(id == 2){
      SET_FLAG(DMA2CTL, ai << 8);
    }
  }

  command void DMA.setSourceAddressIncrement[uint8_t id](addressIncrement ai) {
    if(id == 0){
      SET_FLAG(DMA0CTL, ai << 10);
    }
    else if(id == 1){
      SET_FLAG(DMA1CTL, ai << 10);
    }
    else if(id == 2){
      SET_FLAG(DMA2CTL, ai << 10);
    }
  }
    
  // alternative is word
  command void DMA.setSourceByteSize[uint8_t id](bool byteSize){
    if(byteSize){
      if(id == 0){
	SET_FLAG(DMA0CTL, DMASRCBYTE);
      }
      else if(id == 1){
	SET_FLAG(DMA1CTL, DMASRCBYTE);
      }
      else if(id == 2){
	SET_FLAG(DMA2CTL, DMASRCBYTE);
      }
    }
    else{
      if(id == 0){
	CLR_FLAG(DMA0CTL, DMASRCBYTE);
      }
      else if(id == 1){
	CLR_FLAG(DMA1CTL, DMASRCBYTE);
      }
      else if(id == 2){
	CLR_FLAG(DMA2CTL, DMASRCBYTE);
      }
    }
  }

  command void DMA.setDestinationByteSize[uint8_t id](bool byteSize) {
    if(byteSize){
      if(id == 0){
	SET_FLAG(DMA0CTL, DMADSTBYTE);
      }
      else if(id == 1){
	SET_FLAG(DMA1CTL, DMADSTBYTE);
      }
      else if(id == 2){
	SET_FLAG(DMA2CTL, DMADSTBYTE);
      }
    }
    else{
      if(id == 0){
	CLR_FLAG(DMA0CTL, DMADSTBYTE);
      }
      else if(id == 1){
	CLR_FLAG(DMA1CTL, DMADSTBYTE);
      }
      else if(id == 2){
	CLR_FLAG(DMA2CTL, DMADSTBYTE);
      }
    }
  }

  async default event void DMA.transferComplete[uint8_t id](){}
  TOSH_SIGNAL(DACDMA_VECTOR) {
    volatile uint16_t v  = DMA0CTL;
	
    if(v & DMAIFG) { 
      DMA0CTL &= ~DMAIFG;
      signal DMA.transferComplete[0]();
    }
    v = DMA1CTL;
    if(v & DMAIFG) { 
      DMA1CTL &= ~DMAIFG;
      signal DMA.transferComplete[1]();
    }
    v = DMA2CTL;
    if(v & DMAIFG) { 
      DMA2CTL &= ~DMAIFG;
      signal DMA.transferComplete[2]();
    }
  }

  async default event void DMA.ADCInterrupt[uint8_t id](uint8_t regnum) {} ;
  TOSH_SIGNAL(ADC_VECTOR) {
    volatile uint16_t vec = ADC12IV;
	
    if( vec ) { 
      vec = vec >> 1;
      /*	     original generic trigger
      if( vec >= 3 )
	signal DMA.ADCInterrupt[0](vec);
      */
      switch (vec) {
      case 6:
	signal DMA.ADCInterrupt[0](vec);
	break;
      case 7:
	signal DMA.ADCInterrupt[1](vec);
	break;
      case 8:
	signal DMA.ADCInterrupt[2](vec);
	break;
      default:
	break;
      }
    }
  } 

  ///////////////////////////////////////////////////////////////////////////////
  ///////////////////////////////////////////////////////////////////////////////
  
	// Should a DMA transfer occur immediately (FALSE),
	// on the next instruction fetch after the trigger (TRUE)
  	// Note: DMAONFETCH Must Be Used When The DMA Writes To Flash
  	// If the DMA controller is used to write to flash memory, the DMAONFETCH
  	// bit must be set. Otherwise, unpredictable operation can result.
	async command void DMA.setOnFetch[uint8_t id]() {
	  DMACTL1 |= DMAONFETCH;
	}
	async command void DMA.clearOnFetch[uint8_t id]() {
	  DMACTL1 &= ~(DMAONFETCH);
	}

	// Should the DMA channel priority be 0, 1, 2 (FALSE), or 
	// should it change with each transfer (TRUE)
	async command void DMA.setRoundRobin[uint8_t id]() {
		DMACTL1 |= ROUNDROBIN;
	}
	async command void DMA.clearRoundRobin[uint8_t id]() {
	  DMACTL1 &= ~(ROUNDROBIN);
	}

	// enables the interruption of a DMA transfer by an NMI
	// interrupt. WHen an NMI interrupts a DMA transfer, the current
	// transfer is completed normally, further transfers are stopped,
	// and DMAABORT is set.
	async command void DMA.setENNMI[uint8_t id]() {
	  DMACTL1 |= ENNMI;
	}
	async command void DMA.clearENNMI[uint8_t id]() {
	  DMACTL1 &= ~(ENNMI);
	}

	async command void DMA.setControllerState[uint8_t id](dma_state_t s) {
	  uint16_t dmactl1 = 0;
	  dmactl1 |= (s.enableNMI       ? ENNMI      : 0);
	  dmactl1 |= (s.roundRobin      ? ROUNDROBIN : 0);
	  dmactl1 |= (s.onFetch         ? DMAONFETCH : 0);
	  DMACTL1 = dmactl1;
	}
	async command dma_state_t DMA.getControllerState[uint8_t id]() {
	  dma_state_t s;
	  s.enableNMI = (DMACTL1 & ENNMI ? 1 : 0);
	  s.roundRobin = (DMACTL1 & ROUNDROBIN ? 1 : 0);
	  s.onFetch = (DMACTL1 & DMAONFETCH ? 1 : 0);
	  s.reserved = 0;
	  return s;
	}
 
 
	/////////////////////////////////
	// ----- DMA Trigger Mode -----
	/////////////////////////////////
	async command result_t DMA.setTrigger[uint8_t id](dma_trigger_t trigger) {
	  	if(*(channelControlRegisters[id])& DMAEN) {
	  		return FAIL;
  		}
		DMACTL0 &= ~( (DMA0TSEL0 | DMA0TSEL1 | DMA0TSEL2 | DMA0TSEL3) 
								<< channelTriggerBitShift[id]);
				DMACTL0 |= ((DMATSEL_MASK & trigger) 
								<< channelTriggerBitShift[id]);
	  	return SUCCESS;
	}
	async command void DMA.clearTrigger[uint8_t id]() {
		DMACTL0 &= ~( (DMA0TSEL0 | DMA0TSEL1 | DMA0TSEL2 | DMA0TSEL3) 
							<< channelTriggerBitShift[id]);
	}
	
	/////////////////////////////////
	// ----- DMA Transfer Mode -----
	/////////////////////////////////
	async command void DMA.setSingleMode[uint8_t id]() {
	  *(channelControlRegisters[id]) &= ~(DMADT0 | DMADT1 | DMADT2);
	}
	async command void DMA.setBlockMode[uint8_t id]() {
	  *(channelControlRegisters[id]) &= ~(DMADT0 | DMADT1 | DMADT2);
	  *(channelControlRegisters[id]) |= DMADT0;
	}
	async command void DMA.setBurstMode[uint8_t id]() {
	  *(channelControlRegisters[id]) &= ~(DMADT0 | DMADT1 | DMADT2);
	  *(channelControlRegisters[id]) |= DMADT1;
	}
	async command void DMA.setRepeatedSingleMode[uint8_t id]() {
	  *(channelControlRegisters[id]) &= ~(DMADT0 | DMADT1 | DMADT2);
	  *(channelControlRegisters[id]) |= DMADT2;
	}
	async command void DMA.setRepeatedBlockMode[uint8_t id]() {
	  *(channelControlRegisters[id]) &= ~(DMADT0 | DMADT1 | DMADT2);
	  *(channelControlRegisters[id]) |= (DMADT2 | DMADT0);
	}
	async command void DMA.setRepeatedBurstMode[uint8_t id]() {
	  *(channelControlRegisters[id]) &= ~(DMADT0 | DMADT1 | DMADT2);
	  *(channelControlRegisters[id]) |= (DMADT2 | DMADT1);
	}

	/////////////////////////////////
	// ----- DMA Address Incrementation -----
	/////////////////////////////////
	async command void DMA.setSrcNoIncrement[uint8_t id]() {
	  *(channelControlRegisters[id]) &= ~(DMASRCINCR0 | DMASRCINCR1);
	}
	async command void DMA.setSrcDecrement[uint8_t id]() {
	  *channelControlRegisters[id] |= DMASRCINCR1;
	}
	async command void DMA.setSrcIncrement[uint8_t id]() {
	  *channelControlRegisters[id] |= (DMASRCINCR0 | DMASRCINCR1);
	}
	async command void DMA.setDstNoIncrement[uint8_t id]() {
	  *channelControlRegisters[id] &= ~(DMADSTINCR0 | DMADSTINCR1);
	}
	async command void DMA.setDstDecrement[uint8_t id]() {
	  *channelControlRegisters[id] |= DMADSTINCR1;
	}
	async command void DMA.setDstIncrement[uint8_t id]() {
	  *channelControlRegisters[id] |= (DMADSTINCR0 | DMADSTINCR1);
	}

	/////////////////////////////////
	// ----- DMA Word Size Mode -----
	/////////////////////////////////
	async command void DMA.setWordToWord[uint8_t id]() {
	  *channelControlRegisters[id] &= ~(DMASRCBYTE | DMADSTBYTE);
	  *channelControlRegisters[id] |= DMASWDW;
	}
	async command void DMA.setByteToWord[uint8_t id]() {
	  *channelControlRegisters[id] &= ~(DMASRCBYTE | DMADSTBYTE);
	  *channelControlRegisters[id] |= DMASBDW;
	}
	async command void DMA.setWordToByte[uint8_t id]() {
	  *channelControlRegisters[id] &= ~(DMASRCBYTE | DMADSTBYTE);
	  *channelControlRegisters[id] |= DMASWDB;
	}
	async command void DMA.setByteToByte[uint8_t id]() {
	  *channelControlRegisters[id] &= ~(DMASRCBYTE | DMADSTBYTE);
	  *channelControlRegisters[id] |= DMASBDB;
	}

	/////////////////////////////////
	// ----- DMA Level -----
	/////////////////////////////////

	async command void DMA.setEdgeSensitive[uint8_t id]() {
	  *channelControlRegisters[id] &= ~DMALEVEL;
	}
	async command void DMA.setLevelSensitive[uint8_t id]() {
	  *channelControlRegisters[id] |= DMALEVEL;
	}

	/////////////////////////////////
	// ----- DMA Enable -----
	/////////////////////////////////
	async command void DMA.enableDMA[uint8_t id]() {
		*channelControlRegisters[id] |= DMAEN; 
	}
	async command void DMA.disableDMA[uint8_t id]() {
		*channelControlRegisters[id] &= ~DMAEN; 
	}
	async command bool DMA.getBusyState[uint8_t id]() {
		if (*channelControlRegisters[id]& DMAEN) {
			return TRUE;
		} else {
			return FALSE; 
		}
	}


	/////////////////////////////////
	// ----- DMA Interrupt -----
	/////////////////////////////////
	async command void DMA.enableInterrupt[uint8_t id]() {
	  *channelControlRegisters[id]   |= DMAIE; 
	}
	async command void DMA.disableInterrupt[uint8_t id]() {
	  *channelControlRegisters[id]   &= ~DMAIE; 
	}
	async command bool DMA.interruptPending[uint8_t id]() {
	  bool ret = FALSE;
	  if (*channelControlRegisters[id] & DMAIFG) ret = TRUE;
	  return ret;
	}

	/////////////////////////////////
	// ----- DMA Abort -----
	/////////////////////////////////
	// todo: should this trigger an interrupt?
	async command bool DMA.aborted[uint8_t id]() {
	  bool ret = FALSE;
	  if (*channelControlRegisters[id] & DMAABORT) ret = TRUE;
	  return ret;
	}
	
	async command void DMA.reset[uint8_t id]() {
	  *channelControlRegisters[id] = 0;
//	  DMA0SA = 0;
//	  DMA0DA = 0;
//	  DMA0SZ = 0;
	}

	/////////////////////////////////
	// ----- DMA Software Request -----
	/////////////////////////////////
	async command void DMA.triggerDMA[uint8_t id]() {
		*channelControlRegisters[id]  |= DMAREQ; 
	}

	//****************** WARNING ********************
	//****************** NOT TESTED *****************
	async command void DMA.setState[uint8_t id](dma_channel_state_t s) {
 	  uint16_t dmactl0 = DMACTL0;
	  uint16_t dmaXctl = 0;

	  dmactl0 |= ((s.trigger & DMATSEL_MASK) << channelTriggerBitShift[id]);
	  dmaXctl |= (s.request         ? DMAREQ     : 0);
	  dmaXctl |= (s.abort           ? DMAABORT   : 0);
	  dmaXctl |= (s.interruptEnable ? DMAIE      : 0);
	  dmaXctl |= (s.interruptFlag   ? DMAIFG     : 0);
	  dmaXctl |= (s.enable          ? DMAEN      : 0);
	  dmaXctl |= (s.level           ? DMALEVEL   : 0);
	  dmaXctl |= (s.srcByte         ? DMASRCBYTE : 0);
	  dmaXctl |= (s.dstByte         ? DMADSTBYTE : 0);
	  dmaXctl |= ((s.srcIncrement & DMAINCR_MASK) << DMASRCINCR_SHIFT);
	  dmaXctl |= ((s.dstIncrement & DMAINCR_MASK) << DMADSTINCR_SHIFT);
	  dmaXctl |= ((s.transferMode & DMADT_MASK) << DMADT_SHIFT);

	  *channelSourceRegisters[id] = 		(s.srcAddr);
	  *channelDestinationRegisters[id] = (s.dstAddr);
	  *channelSizeRegisters[id] = 		  (s.size);
	  DMACTL0 = dmactl0;
	  *channelControlRegisters[id]= dmaXctl;
	}
	async command dma_channel_state_t DMA.getState[uint8_t id]() {
	  dma_channel_state_t s;
	  s.trigger = ((DMACTL0 >> channelTriggerBitShift[id]) & DMATSEL_MASK);
	  s.reserved = 0;
	  s.request         = (*channelControlRegisters[id] & DMAREQ     ? 1 : 0);
	  s.abort           = (*channelControlRegisters[id] & DMAABORT   ? 1 : 0);
	  s.interruptEnable = (*channelControlRegisters[id] & DMAIE      ? 1 : 0);
	  s.interruptFlag   = (*channelControlRegisters[id] & DMAIFG     ? 1 : 0);
	  s.enable          = (*channelControlRegisters[id] & DMAEN      ? 1 : 0);
	  s.level           = (*channelControlRegisters[id] & DMALEVEL   ? 1 : 0);
	  s.srcByte         = (*channelControlRegisters[id] & DMASRCBYTE ? 1 : 0);
	  s.dstByte         = (*channelControlRegisters[id] & DMADSTBYTE ? 1 : 0);
	  s.srcIncrement    = ((*channelControlRegisters[id] >> DMASRCINCR_SHIFT) & DMAINCR_MASK);
	  s.dstIncrement    = ((*channelControlRegisters[id] >> DMADSTINCR_SHIFT) & DMAINCR_MASK);
	  s.reserved2 = 0;
	  s.transferMode    = ((*channelControlRegisters[id] >> DMADT_SHIFT) & DMADT_MASK);
	  s.srcAddr = (uint16_t) *channelSourceRegisters[id];
	  s.dstAddr = (uint16_t) *channelDestinationRegisters[id];
	  s.size = *channelSizeRegisters[id];
	  return s;
	} 
	

	//********************* NOT TESTED ************************
	// This code was cut and pasted from a another function where
	// I was testing DMA transfers. I have not yet tested the code 
	// to see if I broke it when I wrapped it in this method
	//////////////////////////////////////////////////////
/*	void transferBlock_DMA  (uint8_t *sourcePtr, 
							uint8_t *destinationPtr,
							uint16_t blockLength) {

		//************************************************
		//  Must set trigger before enabling DMA channel
		//************************************************
		call DMA1.setTrigger(DMA_TRIGGER_DMAREQ);
		call DMA1.clearOnFetch();
		call DMA1.clearRoundRobin();
		call DMA1.clearENNMI();

		call DMA1.setSourceAddress ((uint16_t)  sourcePtr);
		call DMA1.setDestinationAddress ((uint16_t) destinationPtr);
		call DMA1.setBlockSize(blockLength);
		call DMA1.setBurstMode();
		call DMA1.setByteToByte();
		call DMA1.setSrcIncrement();
		call DMA1.setDstIncrement();

		call DMA1.enableDMA();triggerDMA
		call DMA1.triggerDMA();
	}
*/	
}

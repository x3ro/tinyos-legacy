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
 *
 */

interface DMA {
    
  command void init();

  command void beginTransfer();
  command void stopTransfer();

  command void setSourceAddress(uint16_t src);
  command void setDestinationAddress(uint16_t dest);
    
  command void setBlockSize(uint16_t size);
    
  command void setTransferMode(uint16_t mode);

  command void setChannelPriority(bool roundrobin);

  command void setDestinationAddressIncrement(addressIncrement ai);
  command void setSourceAddressIncrement(addressIncrement ai);
    
  command void setSourceByteSize(bool byteSize);
  command void setDestinationByteSize(bool byteSize);

  async default event void transferComplete();

  // Analog to Digital Converter code that should be move at some point
  command void ADCinit();
  command void ADCbeginConversion(); 
  command void ADCstopConversion();
  command void ADCsetMemRegisterInputChannel(uint8_t reg_num, uint8_t ch);
    
  async default event void ADCInterrupt(uint8_t regnum);
  
  ///////////////////////////////////////////////////////////////////////
    // augmented interface added by SPL 10-16-07 to enable the abstraction
    // of DMA access to the SD card. When possible uses the conventions found
    // in MSP430DMAChannelControl.nc by Ben Greenstein <ben@cs.ucla.edu>
    ///////////////////////////////////////////////////////////////////////

    async command result_t setTrigger(dma_trigger_t trigger);
    async command void clearTrigger();

    async command void setOnFetch(); 
    async command void clearOnFetch(); 
    async command void setRoundRobin(); 
    async command void clearRoundRobin(); 
    async command void setENNMI(); 
    async command void clearENNMI(); 
    async command void 			setControllerState(dma_state_t s);
    async command dma_state_t 	getControllerState();


    async command void setSingleMode();
    async command void setBlockMode();
    async command void setBurstMode();
    async command void setRepeatedSingleMode();
    async command void setRepeatedBlockMode();
    async command void setRepeatedBurstMode();

    async command void setSrcNoIncrement();
    async command void setSrcDecrement();
    async command void setSrcIncrement();
    async command void setDstNoIncrement();
    async command void setDstDecrement();
    async command void setDstIncrement();

    async command void setWordToWord(); 
    async command void setByteToWord(); 
    async command void setWordToByte(); 
    async command void setByteToByte(); 


    async command void setEdgeSensitive();
    async command void setLevelSensitive();

    async command void enableDMA();		// different than beginTransfer() found above
    async command void disableDMA();
    async command bool getBusyState();
    async command void enableInterrupt(); 
    async command void disableInterrupt(); 

    async command bool interruptPending();
    async command void reset();
    async command bool aborted();
    async command void triggerDMA();
    // not tested
    async command void 					setState(dma_channel_state_t s);
    async command dma_channel_state_t 	getState();
  
}    


/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Ben Greenstein <ben@cs.ucla.edu>

includes MSP430DMA;

module HALDMAM {
  provides {
    interface DMAControl;
    interface DMA[uint8_t channel];
  }
  uses {
    interface MSP430DMAControl;
    interface MSP430DMAChannelControl as DMAChannelCtrl0;
    interface MSP430DMAChannelControl as DMAChannelCtrl1;
    interface MSP430DMAChannelControl as DMAChannelCtrl2;
  }
}
implementation {
  norace dma_channel_state_t gChannelState[DMA_CHANNELS];
  
  async command void DMAControl.init(){
    call MSP430DMAControl.reset();
    call DMAChannelCtrl0.reset();
    call DMAChannelCtrl1.reset();
    call DMAChannelCtrl2.reset();
  } 
  async command void DMAControl.setFlags(bool enable_nmi,
                                         bool round_robin,
                                         bool on_fetch){

    // NOTE: on_fetch must be true when dst addr is flash

    if (enable_nmi) call MSP430DMAControl.setENNMI();
    else call MSP430DMAControl.clearENNMI();
    if (round_robin) call MSP430DMAControl.setRoundRobin();
    else call MSP430DMAControl.clearRoundRobin();
    if (on_fetch) call MSP430DMAControl.setOnFetch();
    else call MSP430DMAControl.clearOnFetch();
  }
  async command result_t DMA.setupTransfer[uint8_t channel]
    (dma_transfer_mode_t transfer_mode, 
     dma_trigger_t trigger, 
     dma_level_t level,
     void *src_addr, void *dst_addr, uint16_t size,
     dma_byte_t src_byte, dma_byte_t dst_byte,
     dma_incr_t src_incr, dma_incr_t dst_incr){
                                                              
    if (channel >= DMA_CHANNELS) return FAIL;
    gChannelState[channel].trigger = trigger;
    gChannelState[channel].reserved = 0;
    gChannelState[channel].request = 0;
    gChannelState[channel].abort = 0;
    gChannelState[channel].interruptEnable = 1;
    gChannelState[channel].interruptFlag = 0;
    gChannelState[channel].enable = 0;          /* don't start an xfer */
    gChannelState[channel].level = level;
    gChannelState[channel].srcByte = src_byte;
    gChannelState[channel].dstByte = dst_byte;
    gChannelState[channel].srcIncrement = src_incr;
    gChannelState[channel].dstIncrement = dst_incr;
    gChannelState[channel].transferMode = transfer_mode;
    gChannelState[channel].reserved2 = 0;
    gChannelState[channel].srcAddr = src_addr;
    gChannelState[channel].dstAddr = dst_addr;
    gChannelState[channel].size = size;
    switch (channel){
    case 0:
      call DMAChannelCtrl0.setState(gChannelState[0]); break;
    case 1:
      call DMAChannelCtrl1.setState(gChannelState[1]); break;
    case 2:
      call DMAChannelCtrl2.setState(gChannelState[2]); break;
    default: return FAIL;
    }
    return SUCCESS;
    return SUCCESS;
  }
  async command result_t DMA.startTransfer[uint8_t channel](){
    switch (channel){
    case 0: call DMAChannelCtrl0.enableDMA(); break;
    case 1: call DMAChannelCtrl1.enableDMA(); break;
    case 2: call DMAChannelCtrl2.enableDMA(); break;
    default: return FAIL;
    }
    return SUCCESS;
  }
  async command result_t DMA.repeatTransfer[uint8_t channel]
    ( void *src_addr, void *dst_addr, uint16_t size){

    if (channel >= DMA_CHANNELS) return FAIL;
    if (src_addr != NULL)
      gChannelState[channel].srcAddr = src_addr;
    if (dst_addr != NULL)
      gChannelState[channel].dstAddr = dst_addr;
    if (size != 0)
      gChannelState[channel].size = size;

    switch (channel){
    case 0: 
      call DMAChannelCtrl0.setSrc(gChannelState[0].srcAddr);
      call DMAChannelCtrl0.setDst(gChannelState[0].dstAddr);
      call DMAChannelCtrl0.setSize(gChannelState[0].size);
      call DMAChannelCtrl0.enableDMA(); 
      break;
    case 1: 
      call DMAChannelCtrl1.setSrc(gChannelState[1].srcAddr);
      call DMAChannelCtrl1.setDst(gChannelState[1].dstAddr);
      call DMAChannelCtrl1.setSize(gChannelState[1].size);
      call DMAChannelCtrl1.enableDMA(); 
      break;
    case 2: 
      call DMAChannelCtrl2.setSrc(gChannelState[2].srcAddr);
      call DMAChannelCtrl2.setDst(gChannelState[2].dstAddr);
      call DMAChannelCtrl2.setSize(gChannelState[2].size);
      call DMAChannelCtrl2.enableDMA(); 
      break;
    default: return FAIL;
    }
    return SUCCESS;
  }
  async command result_t DMA.softwareTrigger[uint8_t channel](){
    result_t ret = SUCCESS;
    if (channel >= DMA_CHANNELS) return FAIL;
    if (gChannelState[channel].trigger != DMA_TRIGGER_DMAREQ) return FAIL;
    switch (channel){
    case 0: call DMAChannelCtrl0.triggerDMA(); break;
    case 1: call DMAChannelCtrl1.triggerDMA(); break;
    case 2: call DMAChannelCtrl2.triggerDMA(); break;
    default: return FAIL;
    }
    return SUCCESS;
  }

  async command result_t DMA.stopTransfer[uint8_t channel](){
    if (gChannelState[channel].transferMode == DMA_BURST_BLOCK_TRANSFER ||
        gChannelState[channel].transferMode == DMA_REPEATED_BURST_BLOCK_TRANSFER){
      switch(channel){
      case 0: call DMAChannelCtrl0.disableDMA(); return SUCCESS;
      case 1: call DMAChannelCtrl1.disableDMA(); return SUCCESS;
      case 2: call DMAChannelCtrl2.disableDMA(); return SUCCESS;
      default: return FAIL;
      }
    }
  }
  async event void DMAChannelCtrl0.transferDone(result_t success){
    signal DMA.transferDone[0](success);
  }
  async event void DMAChannelCtrl1.transferDone(result_t success){
    signal DMA.transferDone[1](success);
  }
  async event void DMAChannelCtrl2.transferDone(result_t success){
    signal DMA.transferDone[2](success);
  }
  default async event void DMA.transferDone[uint8_t channel](result_t success){
    return;
  }
}

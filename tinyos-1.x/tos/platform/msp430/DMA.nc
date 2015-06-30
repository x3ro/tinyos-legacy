
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

interface DMA {
  async command result_t setupTransfer(dma_transfer_mode_t transfer_mode, 
                                       dma_trigger_t trigger, 
                                       dma_level_t level,
                                       void *src_addr, void *dst_addr, uint16_t size,
                                       dma_byte_t src_byte, dma_byte_t dst_byte,
                                       dma_incr_t src_incr, dma_incr_t dst_incr);
                                                              
  async command result_t startTransfer();
  async command result_t repeatTransfer (void *src_addr, 
                                         void *dst_addr, 
                                         uint16_t size);
  async command result_t softwareTrigger();
  async command result_t stopTransfer();
  async event void transferDone(result_t success);
}

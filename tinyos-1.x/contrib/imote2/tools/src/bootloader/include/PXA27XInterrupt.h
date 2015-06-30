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

/**
 * @file PXA27XInterrupt.h
 * @author
 *
 * ported from TinyOS repository - junaith
 */

#ifndef PXA27X_INTERRUPT_H
#define PXA27X_INTERRUPT_H

#include <hardware.h>
#include <stdlib.h>
#include <string.h>

//void hplarmv_irq_redirect () __attribute__ ((interrupt ("IRQ")));
void hplarmv_pabort () __attribute__((interrupt ("PABORT")));

/**
 * hplarmv_irq
 * 
 * The function is an interrupt handler. The compiler will 
 * generate function entry and exit sequences suitable for use in an 
 * interrupt handler.
 */ 
void hplarmv_irq() __attribute__ ((interrupt ("IRQ")));
//void hplarmv_irq();
//void hpl_irq_redir () __attribute__ ((interrupt ("IRQ")));

/**
 * hplarmv_fiq
 * 
 * The function is an interrupt handler. The compiler will 
 * generate function entry and exit sequences suitable for use in an 
 * interrupt handler.
 */
void hplarmv_fiq() __attribute__ ((interrupt ("FIQ")));

result_t allocate(uint8_t id, bool level, uint8_t priority);
void enable(uint8_t id);
void disable (uint8_t id);
result_t PXA27XIrq_Allocate (uint8_t id);
void PXA27XIrq_Enable (uint8_t id);
void PXA27XIrq_Disable (uint8_t id);
result_t PXA27XFiq_Allocate(uint8_t id);
void PXA27XFiq_Enable (uint8_t id);
void PXA27XFiq_Disable (uint8_t id);

//inline __nesc_atomic_t __nesc_atomic_start(void);
//inline void __nesc_atomic_end(__nesc_atomic_t oldState);

#endif

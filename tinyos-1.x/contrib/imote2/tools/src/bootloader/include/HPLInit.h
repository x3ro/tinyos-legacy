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
 * @file HPLInit.h
 * @author
 *
 * The file provides various hardware initialization routines. 
 * Ported from TinyOS repository - Junaith
 *
 */
#ifndef BL_HPL_INIT_H
#define BL_HPL_INIT_H

#include <types.h>

/**
 * TOSH_SET_PIN_DIRECTIONS
 *
 * Set the pin directions in the processor as a part of
 * the hardware initialization process.
 *
 */
void TOSH_SET_PIN_DIRECTIONS(void);

/**
 * This function is ported from DVFS TinyOS Module.
 * Set the Frequency of the clock.
 *
 * NOTE:
 *   If the Frequency has to be incremented about 104Mhz then
 *   the CoreVoltage has to be increased accordingly. Refer to
 *   http://download.intel.com/design/pca/applicationsprocessors/datashts/28000304.pdf
 *
 * @param coreFreq Clock frequency to be set.
 * @param sysBusFreq Bus Frequency.
 *
 * @return SUCCESS | FAIL
 */
result_t SetCoreFreq (uint32_t coreFreq, uint32_t sysBusFreq);

/**
 * HPLInit
 *
 * Intialize the hardware clock, set clock frequency and set
 * pin directions.
 *
 * @return SUCCESS | FAIL
 */
result_t HPLInit();

/**
 * Enable_MMU
 *
 * The function enables the MMU, ICache and
 * DCache. The clock frequency is set to 104Mhz for
 * fast execution and improves performance.
 *
 * @return SUCCESS | FAIL
 */
result_t Enable_MMU ();

#endif

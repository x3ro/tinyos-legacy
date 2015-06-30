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

#include <hardware.h>
#include <HPLInit.h>
#include <MMU.h>
#include <FlashAccess.h>

/**
 * TOSH_SET_PIN_DIRECTIONS
 *
 * Set the pin directions in the processor as a part of
 * the hardware initialization process.
 *
 */
void TOSH_SET_PIN_DIRECTIONS(void)
{
  PSSR = (PSSR_RDH | PSSR_PH);   // Reenable the GPIO buffers (needed out of reset)
  TOSH_CLR_CC_RSTN_PIN();
  TOSH_MAKE_CC_RSTN_OUTPUT();
  TOSH_CLR_CC_VREN_PIN();
  TOSH_MAKE_CC_VREN_OUTPUT();
  TOSH_SET_CC_CSN_PIN();
  TOSH_MAKE_CC_CSN_OUTPUT();
  TOSH_MAKE_CC_FIFOP_INPUT();
  TOSH_MAKE_CC_FIFO_INPUT();
  TOSH_MAKE_CC_SFD_INPUT();
  TOSH_MAKE_RADIO_CCA_INPUT();
}

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
result_t SetCoreFreq (uint32_t coreFreq, uint32_t sysBusFreq)
{
  /*
   * TODO : add all supported frequencies, for now support 13 & 104 only
   *        add core voltage switching to min value based on freq
   */
  switch (coreFreq) 
  {
    case 13:
      if (sysBusFreq != 13) {
        return FAIL;
      }
      {__nesc_atomic_t atomic = __nesc_atomic_start();
        CCCR = CCCR_CPDIS | CCCR_A;
        asm volatile (
	         "mcr p14,0,%0,c6,c0,0\n\t"
	         :
	         : "r" (0x2)
	         );
        // check that core PLL was disabled
        while ((CCSR & CCSR_CPDIS_S) == 0);
      __nesc_atomic_end (atomic);
      }
        return SUCCESS;

      case 104:
        if (sysBusFreq != 104)
           return FAIL;

        {
        __nesc_atomic_t atomic = __nesc_atomic_start();
          CCCR = CCCR_L(8) | CCCR_2N(2) | CCCR_A ; 
          asm volatile (
		         "mcr p14,0,%0,c6,c0,0\n\t"
		         :
		         : "r" (0xb)           
		         );
	  // "r" (0xb)
           // wait until core pll locks
          while ((CCSR & CCSR_CPLCK) == 0);
        __nesc_atomic_end (atomic);
        }
        return SUCCESS;
      case 312:
        if (sysBusFreq != 312)
           return FAIL;

        {
        __nesc_atomic_t atomic = __nesc_atomic_start();
          CCCR = CCCR_L(16) | CCCR_2N(3) | CCCR_A; 
          asm volatile (
		         "mcr p14,0,%0,c6,c0,0\n\t"
		         :
		         : "r" (0xb)
		         );
	  // "r" (0xb)
           // wait until core pll locks
          while ((CCSR & CCSR_CPLCK) == 0);
        __nesc_atomic_end (atomic);
        }
        return SUCCESS;
      default:
        return FAIL;
  }
  return FAIL;
}

/**
 * HPLInit
 *
 * Intialize the hardware clock, set clock frequency and set
 * pin directions.
 *
 * @return SUCCESS | FAIL
 */
result_t HPLInit() 
{
  CKEN = (CKEN22_MEMC | CKEN20_IMEM | CKEN15_PMI2C | CKEN9_OST);
  OSCC = (OSCC_OON);

  while ((OSCC & OSCC_OOK) == 0);
    
  TOSH_SET_PIN_DIRECTIONS();
  SetCoreFreq(13, 13);
  return SUCCESS;
}


/**
 * Enable_MMU
 *
 * The function enables the MMU, ICache and
 * DCache. The clock frequency is set to 104Mhz for
 * fast execution and improves performance.
 *
 * @return SUCCESS | FAIL
 */
result_t Enable_MMU ()
{
  SetCoreFreq(104, 104);

#ifdef MMU_ENABLE

  /* Every thing is still happy even if we dont set these fields, 
   * just do it for correctness
   */
  SA1110 = SA1110_SXSTACK(1);  
  //MSC0 = MSC0 | (1<<19) | (1<<31) | (2 << 16) ;
  MSC0 = MSC0 | (1<<3) | (1<<15) | 2 ;
  //MSC0 = 0xFFFA7FF8;
  MSC1 = MSC1 | (1<<3);
  MSC2 = MSC2 | (1<<3);

  //PXA27x MemController 2nd tier initialization.See 6.4.10 for details
  MECR =0; //no PC Card is present and 1 card slot
     
  //PXA27x MemController 3rd tier initialization.See 6.4.10 for details
  //FLYCNFG
     
  //PXA27x MemController 4th tier initialization.See 6.4.10 for details
  MDCNFG = 0x0B002BCC; //should be 0x0B002BCD, but we want it disabled.

  //PXA27x MemController 5th tier initialization.See 6.4.10 for details
  //SXCNFG = SXCNFG_SXEN0 | SXCNFG_SXCL0(4) | SXCNFG_SXTP0(3);

  //initialize the MMU
  initMMU();
  enableICache();
  enableDCache();
#endif

  return SUCCESS;
}

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  6/25/02
 *
 */

// The hardware presentation layer. See hpl.h for the C side.
// Note: there's a separate C side (hpl.h) to get access to the avr macros

// The model is that HPL is stateless. If the desired interface is as stateless
// it can be implemented here (Clock, FlashBitSPI). Otherwise you should
// create a separate component

includes MMU;
includes queue;
includes trace;

module HPLInitM {
  provides command result_t init();
  uses interface DVFS;
}

implementation
{

  queue_t paramtaskQueue __attribute__ ((C));
  
  void initMemory(bool bInitSDRAM);
  
  command result_t init() {
    CKEN = (CKEN_CKEN22 | CKEN_CKEN20 | CKEN_CKEN15 | CKEN_CKEN9);
    OSCC = (OSCC_OON);
    
    while ((OSCC & OSCC_OOK) == 0);
    
    TOSH_SET_PIN_DIRECTIONS();
    initqueue(&paramtaskQueue,defaultQueueSize);
    
    initMMU();
    enableICache();
#if defined(SYSTEM_USE_SDRAM)
    initMemory(SYSTEM_USE_SDRAM);
#else
    initMemory(FALSE);
#endif
    enableDCache();
 
#if defined(SYSTEM_CORE_FREQUENCY) && defined(SYSTEM_BUS_FREQUENCY)
     if(call DVFS.SwitchCoreFreq(SYSTEM_CORE_FREQUENCY, SYSTEM_BUS_FREQUENCY) !=  SUCCESS){
       //set to default value of 13:13
       call DVFS.SwitchCoreFreq(13, 13);
       //currently, we can't print out anything because we haven necessarily enabled the UART...leave this as a comment...
       //trace(DBG_TEMP, "Unable to set Core/Bus frequency to [%d/%d]\r\n",SYSTEM_CORE_FREQUENCY, SYSTEM_BUS_FREQUENCY);
     }
#else
     //PLACE PXA27X into 13 MHz mode
     call DVFS.SwitchCoreFreq(13, 13);
#endif
           
      return SUCCESS;
  }

  void initMemory(bool bInitSDRAM){
   
    uint32_t waitStart;
    uint32_t *pSDRAM = (uint32_t *)0xa0000000;
    int i;
    
    
    //initialize the memory controller
    //PXA27x MemConttroller 1st tier initialization.See 6.4.10 for details
    // Initialize Memory/Flash subsystems
    /**
       1. On hardware reset, complete a power-on wait period (typically 
       100-200 us) to allow the internal clocks (which generate SDCLK) to 
       stabilize. MDREFR[K0RUN] can be enabled at this time for synchronous 
       flash memory. Allowed writes are shown below. Refer to the Intel�
       PXA27x Processor Family EMTS for timing details.
    **/
    
    SA1110 = SA1110_SXSTACK(1);
    //MSC0 =MSC0 | MSC_RBW024 | MSC_RBUFF024 | MSC_RT024(2) ;
    MSC0 =MSC0 | MSC_RBW024 | MSC_RBUFF024 | MSC_RT024(0) ;
    MSC1 =MSC1 | MSC_RBW024;
    MSC2 =MSC2 | MSC_RBW024;
    
    //PXA27x MemController 2nd tier initialization.See 6.4.10 for details
    MECR =0; //no PC Card is present and 1 card slot
    
    /** 
	the folowing registers are used for configuring PC card access
	MCMEM0; used for PC Cards
	MCMEM1; used for PC Cards
	MCATT0;
	MCATT1
	MCIO0;
	MCIO1;
    **/
    
    
    //PXA27x MemController 3rd tier initialization.See 6.4.10 for details
    //FLYCNFG
    
    //PXA27x MemController 4th tier initialization.See 6.4.10 for details
    MDCNFG = (MDCNFG_DTC2(0x3) |MDCNFG_STACK0 | MDCNFG_SETALWAYS |
	      MDCNFG_DTC0(0x3) | MDCNFG_DNB0 | MDCNFG_DRAC0(0x2) | 
	      MDCNFG_DCAC0(0x1) | MDCNFG_DWID0);
    
    
    /**
       From 6.4.10
       Set MDREFR[K0RUN]. Properly configure MDREFR[K0DB2] and MDREFR[K0DB4].
       Retain the current values of MDREFR[APD] (clear) and MDREFR[SLFRSH] 
       (set). MDREFR[DRI] must contain a valid value (not all 0s). If required,
       MDREFR[KxFREE] can be de-asserted.
    **/
    
    MDREFR = (MDREFR & ~(0xFFF)) | MDREFR_DRI(0x18); 
        
    //PXA27x MemController 5th tier initialization.See 6.4.10 for details
    //SXCNFG = SXCNFG_SXEN0 | SXCNFG_SXCL0(4) | SXCNFG_SXTP0(3);
    
    /**
       2. In systems that contain synchronous flash memory, write to the 
       SXCNFG to configure all appropriate bits, including the enables. While 
       the synchronous flash banks are being configured, the SDRAM banks must 
       be disabled and MDREFR[APD] must be de-asserted (auto-power-down 
       disabled).
    **/
    initSyncFlash(); 
    
    if(bInitSDRAM == FALSE){
      return;
    }
    /**
       3. Toggle the SDRAM controller through the following state
       sequence: self-refresh and clock-stop to self-refresh to power-down 
       to PWRDNX to NOP. See Figure 6-4. The SDRAM clock run and enable bits, 
       (MDREFR[K1RUN] and MDREFR[K2RUN] and MDREFR[E1PIN]), are described 
       in Section 6.5.1.3. MDREFR[SLFRSH] must not be set.
    **/

    /**
       a. Set MDREFR[K1RUN], MDREFR[K2RUN] (self-refresh and clock-stop 
       through selfrefresh). MDREFR[K1DB2] and MDREFR[K2DB2] must be 
       configured appropriately.  Also, clear the free running clock bits to
       save power and configure the boot partition (FLASH) clock to run since
       we already put FLASH in sync mode
    **/
    MDREFR = (MDREFR & ~(MDREFR_K0FREE | MDREFR_K1FREE | MDREFR_K2FREE)) | 
      (MDREFR_K1RUN | MDREFR_K1DB2 | MDREFR_K0DB2 | MDREFR_K0RUN); 
    //MDREFR |= (MDREFR_K1RUN | MDREFR_K1DB2); 
    /**
       b. Clear MDREFR[SLFRSH] (self-refresh through power down)
    **/
    MDREFR &= ~MDREFR_SLFRSH;
    
    /**
    c. Set MDREFR[E1PIN] (power down through PWRDNX)
    **/
    MDREFR |= MDREFR_E1PIN;
    
    /**
       d. No write required for this state transition (PWRDNX through NOP)
    **/
    
    /**
       4. Appropriately configure, but do not enable, each SDRAM partition 
       pair. SDRAM partitions are disabled by keeping the MDCNFG[DEx] bits 
       clear.
    **/
    //this was done earlier;

    /**
    5. For systems that contain SDRAM, wait the NOP power-up waiting period 
    required by the SDRAMs (normally 100-200 usec) to ensure the SDRAMs 
    receive a stable clock with a NOP condition.
    **/
    //OSCR0 runs at 3.25MHz.  200us = 650 clks, 250us = 812
    //look at a difference in order to take care of wrapping arithmetic
    waitStart = OSCR0;
    while( (OSCR0 - waitStart) < 800); 
    
    /**
       6. Ensure the XScale core memory-management data cache (Coprocessor 15, 
       Register 1, bit 2) is disabled. If this bit is enabled, the refreshes 
       triggered by the next step may not be passed properly through to the 
       memory controller. Coprocessor 15, register 1, bit 2 must be reenabled
       after the refreshes are performed if data cache is preferred.
       Note:  calling disable DCache takes ~25seconds!!! assume for now that it is
       //already disabled
       
    **/
    //disableDCache();
      
    /**
    7. On hardware reset in systems that contain SDRAM, trigger a number 
    (the number required by the SDRAM manufacturer) of refresh cycles by 
    attempting non-burst read or write accesses to any disabled SDRAM bank. 
    Each such access causes a simultaneous CBR for all four banks, which in 
    turn causes a pass through the CBR state and a return to NOP. On the 
    first pass, the PALL state is incurred before the CBR state. 
    See Figure 6-4.
    **/
    for (i=0; i<7; i++){
      *pSDRAM = (uint32_t)pSDRAM;
    }
    
    /**
    8. Set coprocessor 15, register 1, bit 2 if it was cleared in step 6.
    **/

    /**
       9. In systems that contain SDRAM, enable SDRAM partitions by setting 
       MDCNFG[DEx] bits.
    **/
    MDCNFG |= MDCNFG_DE0;
    
    /**
       10. In systems that contain SDRAM, write the MDMRS register to trigger 
       an MRS command to all enabled banks of SDRAM. For each SDRAM partition 
       pair that has one or both partitions enabled, this forces a pass through
       the MRS state and a return to NOP. The CAS latency is the only variable 
       option and is derived from what was programmed into the MDCNFG[MDTC0]
       and MDCNFG[MDTC2] fields. The burst type and length are always 
       programmed to sequential and four, respectively. For more information, 
       see Section 6.4.2.5.
    **/
    MDMRS = 0;
    
    /**
       11. In systems that contain SDRAM or synchronous flash, optionally 
       enable auto-power-down by setting MDREFR[APD].
    **/
    MDREFR |= MDREFR_APD;
  }

}


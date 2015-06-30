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
 * @file PXA27XInterrupt.c
 * @author Phil Buonadonna
 *
 * Edits:	Josh Herbach
 * Ported:	Junaith Ahemed Shahabdeen
 *
 */
#include <PXA27XInterrupt.h>
#include <PXA27XGPIOInt.h>
#include <PXA27XClock.h>
#include <USBClient.h>
#include <PMIC.h>

/* Global interrupt priority table. 
 *    Table is indexed by the Peripheral ID (PPID). Priorities are 0 - 39
 *    where 0 is the highest.  Priorities MUST be unique. 0XFF = invalid/unassigned
 */
const uint8_t TOSH_IRP_TABLE[] = { 0xFF, // PPID  0 SSP_3 Service Req
				   0xFF, // PPID  1 MSL
				   0xFF, // PPID  2 USBH2
				   0xFF, // PPID  3 USBH1
				   0xFF, // PPID  4 Keypad
				   0xFF, // PPID  5 Memory Stick
				   0xFF, // PPID  6 Power I2C
				   0x01, // PPID  7 OST match Register 4-11
				   0x02, // PPID  8 GPIO_0
				   0x03, // PPID  9 GPIO_1
				   0x04, // PPID 10 GPIO_x
				   0x08, // PPID 11 USBC
				   0xFF, // PPID 12 PMU
				   0xFF, // PPID 13 I2S
				   0xFF, // PPID 14 AC '97
				   0xFF, // PPID 15 SIM status/error
				   0xFF, // PPID 16 SSP_2 Service Req
				   0xFF, // PPID 17 LCD Controller Service Req
				   0xFF, // PPID 18 I2C Service Req
				   0xFF, // PPID 19 TX/RX ERROR IRDA
				   0x07, // PPID 20 TX/RX ERROR STUART
				   0xFF, // PPID 21 TX/RX ERROR BTUART
				   0x06, // PPID 22 TX/RX ERROR FFUART
				   0xFF, // PPID 23 Flash Card status/Error Detect
				   0x05, // PPID 24 SSP_1 Service Req
				   0x00, // PPID 25 DMA Channel Service Req
				   0xFF, // PPID 26 OST equals Match Register 0
				   0xFF, // PPID 27 OST equals Match Register 1
				   0xFF, // PPID 28 OST equals Match Register 2
				   0xFF, // PPID 29 OST equals Match Register 3
				   0xFF, // PPID 30 RTC One HZ TIC
				   0xFF, // PPID 31 RTC equals Alarm
				   0xFF, // PPID 32
				   0x09, // PPID 33 Quick Capture Interface
				   0xFF, // PPID 34
				   0xFF, // PPID 35
				   0xFF, // PPID 36
				   0xFF, // PPID 37
				   0xFF, // PPID 38
				   0xFF  // PPID 39
};

void hplarmv_pabort ()
{
  asm volatile ("MRC P15,0,R0,C5,C0,0\n\t");
  return;
}

/**
 * hplarmv_irq
 *
 * Irq handler for the boot loader. The address of the function is
 * stored in a RAM table at the start of the RAM. The hardware IRQ
 * branches to a redirect function that invokes this function to
 * handle the IRQ.
 */
void hplarmv_irq()
{
  uint32_t IRQPending;

  IRQPending = ICHP;  // Determine which interrupt to service
  IRQPending >>= 16;  // Right justify to the IRQ portion

  while (IRQPending & (1 << 15)) 
  {
    uint8_t PeripheralID = (IRQPending & 0x3f); // Get rid of the Valid bit
    //signal PXA27XIrq.fired[PeripheralID]();// Handler is responsible for clearing interrupt
    switch (PeripheralID)
    {
      case PPID_GPIO_0:
        GPIOIrq0_Fired ();
      break;
      case PPID_GPIO_1:
        GPIOIrq1_Fired ();
      break;
      case PPID_GPIO_X:
        GPIOIrq_Fired ();
      break;
      case PPID_USBC:
        USBInterrupt_Fired ();
      break;
      case PPID_PWR_I2C:
        PI2CInterrupt_Fired ();
      break;
      case PPID_OST_4_11:
        OSTIrq_Fired ();
      break;
      case PPID_DMAC:
        DMA_Done ();
      break;
      default:
        break;					
    }
    IRQPending = ICHP;  // Determine which interrupt to service
    IRQPending >>= 16;  // Right justify to the IRQ portion
  }
  return;
}

/**
 * hplarmv_fiq
 *
 * Fast Interrupt, currently not used in the code.
 */
void hplarmv_fiq()
{
  uint32_t FIQPending;

  FIQPending = ICHP;   // Determine which interrupt to service
  FIQPending &= 0xFF;  // Mask off the IRQ portion

  while (FIQPending & (1 << 15)) 
  {
    uint8_t PeripheralID = (FIQPending & 0x3f); // Get rid of the Valid bit
    //signal PXA27XFiq.fired[PeripheralID]();	// Handler is responsible for clearing interrupt
    FIQPending = ICHP;
    FIQPending &= 0xFF;
  }
  return;
} 

static uint8_t usedPriorities = 0;

/* Helper functions */
/* NOTE: Read-back of all register writes is necessary to ensure the data latches */

result_t allocate(uint8_t id, bool level, uint8_t priority)
{
  uint32_t tmp;
  result_t result = FAIL;

  /*I had to replace the atomic statement with the following -Junaith*/
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start(); 
  {
    uint8_t i;
    if(usedPriorities == 0)
    {//assumed that the table will have some entries
      uint8_t PriorityTable[40], DuplicateTable[40];
      for(i = 0; i < 40; i++)
      {
        DuplicateTable[i] = PriorityTable[i] = 0xFF;
      }

      for(i = 0; i < 40; i++)
        if(TOSH_IRP_TABLE[i] != 0xff)
        {
          if(PriorityTable[TOSH_IRP_TABLE[i]] != 0xFF)/*duplicate priorities in 
                                                        the table, mark 
                                                        for later fixing*/
            DuplicateTable[i] = PriorityTable[TOSH_IRP_TABLE[i]];
          else
            PriorityTable[TOSH_IRP_TABLE[i]] = i;
        }
	
        //compress table
        for(i = 0; i < 40; i++)
        {
          if(PriorityTable[i] != 0xff)
          {
            PriorityTable[usedPriorities] = PriorityTable[i];
            if(i != usedPriorities)
              PriorityTable[i] = 0xFF;
            usedPriorities++;
          }
        }

        for(i = 0; i < 40; i++)
          if(DuplicateTable[i] != 0xFF)
          {
            uint8_t j, ExtraTable[40];
            for(j = 0; DuplicateTable[i] != PriorityTable[j]; j++);
              memcpy(ExtraTable + j + 1, PriorityTable + j, usedPriorities - j);
            memcpy(PriorityTable + j + 1, ExtraTable + j + 1, usedPriorities - j);
					PriorityTable[j] = i;
					usedPriorities++;
          }

        for(i = 0; i < usedPriorities; i++)
        {
          IPR(i) = (IPR_VALID | PriorityTable[i]);
          tmp = IPR(i);
        }
    }

    if (id < 34)
    {
      if(priority == 0xff)
      {
        priority = usedPriorities;
        usedPriorities++;
        IPR(priority) = (IPR_VALID | (id));
        tmp = IPR(priority);
      }
      if (level) 
      {
        _ICLR(id) |= _PPID_Bit(id);
        tmp = _ICLR(id);
      } 

      result = SUCCESS;
    }
  }
  __nesc_atomic_end(__nesc_atomic); }
  return result;
}
  
void enable(uint8_t id)
{
  uint32_t tmp;
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
  {
    if (id < 34) 
    {
      _ICMR(id) |= _PPID_Bit(id);
      tmp = _ICMR(id);
    }
  }
  __nesc_atomic_end(__nesc_atomic); }
  return;
}

void disable (uint8_t id)
{
  uint32_t tmp;
  { __nesc_atomic_t __nesc_atomic = __nesc_atomic_start();
  {
    if (id < 34) 
    {
      _ICMR(id) &= ~(_PPID_Bit(id));
      tmp = _ICMR(id);
    }
  }
  __nesc_atomic_end(__nesc_atomic); }
  return;
}

/* Interface implementation */
result_t PXA27XIrq_Allocate (uint8_t id)
{
  return allocate(id, FALSE, TOSH_IRP_TABLE[id]);
}

void PXA27XIrq_Enable (uint8_t id)
{
  enable(id);
  return;
}

void PXA27XIrq_Disable (uint8_t id)
{
  disable(id);
  return;
}

result_t PXA27XFiq_Allocate (uint8_t id)
{
  return allocate (id, TRUE, TOSH_IRP_TABLE[id]);
}

void PXA27XFiq_Enable (uint8_t id)
{
  enable(id);
  return;
}

void PXA27XFiq_Disable (uint8_t id)
{
  disable(id);
  return;
}


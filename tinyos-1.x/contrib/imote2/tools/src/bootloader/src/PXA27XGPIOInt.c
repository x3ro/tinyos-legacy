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
 * @file PXA27XGPIOInt.c
 * @author Phil Buonadonna
 *
 * NOTE- Ported from TinyOS repository. Jan 16.2006.
 */
#include <HPLInit.h>
#include <PXA27XGPIOInt.h>
#include <PXA27XInterrupt.h>
#include <USBClient.h>
#include <PMIC.h>

bool gfInitialized = FALSE;

result_t PXA27XGPIOInt_Init()
{
  bool isInited;
  //atomic 
  {
    isInited = gfInitialized;
    gfInitialized = TRUE;
  }

  if (!isInited) 
  {
    PXA27XIrq_Allocate (PPID_GPIO_0);
    PXA27XIrq_Allocate (PPID_GPIO_1);
    PXA27XIrq_Allocate (PPID_GPIO_X);
  }

  PXA27XIrq_Enable (PPID_GPIO_0);
  PXA27XIrq_Enable (PPID_GPIO_1);
  PXA27XIrq_Enable (PPID_GPIO_X);

  return SUCCESS;
}

result_t PXA27XGPIOInt_Stop()
{
  PXA27XIrq_Disable (PPID_GPIO_0);
  PXA27XIrq_Disable (PPID_GPIO_1);
  PXA27XIrq_Disable (PPID_GPIO_X);
  return SUCCESS;
}

void PXA27XGPIOInt_Enable(uint8_t pin, uint8_t mode)
{
  if (pin < 121) 
  {
    switch (mode) 
    {
      case TOSH_RISING_EDGE:
        _GRER(pin) |= _GPIO_bit(pin);
        _GFER(pin) &= ~(_GPIO_bit(pin));
        break;
      case TOSH_FALLING_EDGE:
        _GRER(pin) &= ~(_GPIO_bit(pin));
        _GFER(pin) |= _GPIO_bit(pin);
        break;
      case TOSH_BOTH_EDGE:
        _GRER(pin) |= _GPIO_bit(pin);	
        _GFER(pin) |= _GPIO_bit(pin);
        break;
      default:
        break;
    }
  }
  return;
}


void PXA27XGPIOInt_Disable (uint8_t pin) 
{
  if (pin < 121) 
  {
    _GRER(pin) &= ~(_GPIO_bit(pin));
    _GFER(pin) &= ~(_GPIO_bit(pin));
  }
  return;
}

void PXA27XGPIOInt_Clear (uint8_t pin)
{
  if (pin < 121) 
  {
    _GEDR(pin) = _GPIO_bit(pin);
  }
    
  return;
}

void GPIOIrq_Fired() 
{
  uint32_t DetectReg;
  uint8_t pin;

  //TOSH_CLR_RED_LED_PIN ();
  // Mask off GPIO 0 and 1 (handled by direct IRQs)
  //atomic 
  DetectReg = (GEDR0 & ~((1<<1) | (1<<0))); 

  //TOSH_CLR_RED_LED_PIN ();	
  while (DetectReg) 
  {
    pin = 31 - _pxa27x_clzui(DetectReg);
    //signal PXA27XGPIOInt.fired[pin]();
    DetectReg &= ~(1 << pin);
  }

  //atomic 
  DetectReg = GEDR1;
  while (DetectReg) 
  {
    pin = 31 - _pxa27x_clzui(DetectReg);
    //signal PXA27XGPIOInt.fired[(pin+32)]();
    DetectReg &= ~(1 << pin);
  }

  //atomic 
  DetectReg = GEDR2;
  while (DetectReg) 
  {
    pin = 31 - _pxa27x_clzui(DetectReg);
    //signal PXA27XGPIOInt.fired[(pin+64)]();
    DetectReg &= ~(1 << pin);
  }

  //atomic 
  DetectReg = GEDR3;
  while (DetectReg) 
  {
    pin = 31 - _pxa27x_clzui(DetectReg);
    //signal PXA27XGPIOInt.fired[(pin+96)]();
    DetectReg &= ~(1 << pin);
  }

  return;
}

void GPIOIrq0_Fired()
{
  //signal PXA27XGPIOInt.fired[0]();
}

void GPIOIrq1_Fired() 
{
  PMICInterrupt_Fired ();
}



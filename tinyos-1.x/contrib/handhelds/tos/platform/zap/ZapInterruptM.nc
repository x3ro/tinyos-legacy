//$Id: ZapInterruptM.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $

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

//@author Joe Polastre
//@author Jamey Hicks

module ZapInterruptM
{
  provides interface ZapInterrupt as Eth;
  provides interface ZapInterrupt as CCA;
  provides interface ZapInterrupt as FIFOP;
  provides interface ZapInterrupt as SFD;
}
implementation
{

#include "hwportdefs.h"

  default async event void Eth.fired() { call Eth.clear(); }
  default async event void FIFOP.fired() { call FIFOP.clear(); }
  default async event void CCA.fired() { call CCA.clear(); }
  default async event void SFD.fired() { call SFD.clear(); }

  async command void Eth.enable() { _IER1 |= (1ul << 16); }
  async command void FIFOP.enable() { _IER1 |= (1ul << 11); }
  async command void CCA.enable() { _IER1 |= (1ul << 3); }
  async command void SFD.enable() { _IER1 |= (1ul << 19); }

  async command void Eth.disable() { _IER1 &= !(1ul << 16); }
  async command void FIFOP.disable() { _IER1 &= !(1ul << 11); }
  async command void CCA.disable() { _IER1 &= !(1ul << 3); }
  async command void SFD.disable() { _IER1 &= !(1ul << 19); }

  async command void Eth.clear() { _IFR1 |= (1ul << 16); }
  async command void FIFOP.clear() { _IFR1 |= (1ul << 16); }
  async command void CCA.clear() { _IFR1 |= (1ul << 16); }
  async command void SFD.clear() { _IFR1 |= (1ul << 16); }

  void HWI_eth() __attribute__((C, spontaneous))
  {
    signal Eth.fired(); return;
  }

  void HWI_fifop() __attribute__((C, spontaneous))
  {
    signal FIFOP.fired(); return;
  }

  void HWI_cca() __attribute__((C, spontaneous))
  {
    signal CCA.fired(); return;
  }

  void HWI_rtc_sfd() __attribute__((C, spontaneous))
  {
    signal SFD.fired(); return;
  }
}

// $Id: SysTimeC.nc,v 1.2 2003/10/07 21:45:28 idgay Exp $

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

/*
 *
 * Authors:		Su Ping <sping@intel-research.net>
 * Date last modified:  $Id: SysTimeC.nc,v 1.2 2003/10/07 21:45:28 idgay Exp $
 *
 */

/**
 * @author Su Ping <sping@intel-research.net>
 */



module SysTimeC {
  provides interface SysTime;
}
implementation
{
  uint16_t  high16;

  command result_t SysTime.init() {        
    outp(0x41, TCCR1B);// set clock source 
    // disable output comparation interrupt
    cbi(TIMSK, OCIE1A);
    cbi(TIMSK, OCIE1B);
    // enable timer1 overflow interrupt
    sbi(TIMSK, TOIE1);
    high16=0;

    return SUCCESS;
  }

  command result_t SysTime.get(uint32_t * time){
    // read  hardware timer1's TCNT1L and TCNT1H register 
    uint16_t tt;
    atomic {
      tt = inw(TCNT1L);
      *time = ((uint32_t)high16<<16);
    } 
    *time += tt; 
    return SUCCESS; 
  }

  command result_t SysTime.set(uint32_t  time){
    char temp;
    uint16_t t = time & 0xFFFF;
    // write into  hardware timer1's TCNT1 register
    atomic { 
      __outw(t, TCNT1L);
      high16 = time >>16 ;
    } 
    return SUCCESS;
  }

  TOSH_INTERRUPT(SIG_OVERFLOW1) __attribute((spontaneous)){
    high16 ++;
  }

}

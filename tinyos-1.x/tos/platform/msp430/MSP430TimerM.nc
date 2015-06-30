//$Id: MSP430TimerM.nc,v 1.13 2005/01/10 12:03:27 janhauer Exp $

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

//@author Cory Sharp <cssharp@eecs.berkeley.edu
//@author Joe Polastre
//@author Jan Hauer <hauer@tkn.tu-berlin.de>

includes MSP430Timer;

module MSP430TimerM
{
  provides interface MSP430Timer as TimerA;
  provides interface MSP430TimerControl as ControlA0;
  provides interface MSP430TimerControl as ControlA1;
  provides interface MSP430TimerControl as ControlA2;
  provides interface MSP430Compare as CompareA0;
  provides interface MSP430Compare as CompareA1;
  provides interface MSP430Compare as CompareA2;
  provides interface MSP430Capture as CaptureA0;
  provides interface MSP430Capture as CaptureA1;
  provides interface MSP430Capture as CaptureA2;

  provides interface MSP430Timer as TimerB;
  provides interface MSP430TimerControl as ControlB0;
  provides interface MSP430TimerControl as ControlB1;
  provides interface MSP430TimerControl as ControlB2;
  provides interface MSP430TimerControl as ControlB3;
  provides interface MSP430TimerControl as ControlB4;
  provides interface MSP430TimerControl as ControlB5;
  provides interface MSP430TimerControl as ControlB6;
  provides interface MSP430Compare as CompareB0;
  provides interface MSP430Compare as CompareB1;
  provides interface MSP430Compare as CompareB2;
  provides interface MSP430Compare as CompareB3;
  provides interface MSP430Compare as CompareB4;
  provides interface MSP430Compare as CompareB5;
  provides interface MSP430Compare as CompareB6;
  provides interface MSP430Capture as CaptureB0;
  provides interface MSP430Capture as CaptureB1;
  provides interface MSP430Capture as CaptureB2;
  provides interface MSP430Capture as CaptureB3;
  provides interface MSP430Capture as CaptureB4;
  provides interface MSP430Capture as CaptureB5;
  provides interface MSP430Capture as CaptureB6;
}
implementation
{
  MSP430REG_NORACE(TACTL);
  
  MSP430REG_NORACE(TACCTL0);
  MSP430REG_NORACE(TACCTL1);
  MSP430REG_NORACE(TACCTL2);

  MSP430REG_NORACE(TACCR0);
  MSP430REG_NORACE(TACCR1);
  MSP430REG_NORACE(TACCR2);

  MSP430REG_NORACE(TBCCTL0);
  MSP430REG_NORACE(TBCCTL1);
  MSP430REG_NORACE(TBCCTL2);
  MSP430REG_NORACE(TBCCTL3);
  MSP430REG_NORACE(TBCCTL4);
  MSP430REG_NORACE(TBCCTL5);
  MSP430REG_NORACE(TBCCTL6);

  MSP430REG_NORACE(TBCCR0);
  MSP430REG_NORACE(TBCCR1);
  MSP430REG_NORACE(TBCCR2);
  MSP430REG_NORACE(TBCCR3);
  MSP430REG_NORACE(TBCCR4);
  MSP430REG_NORACE(TBCCR5);
  MSP430REG_NORACE(TBCCR6);

  typedef MSP430CompareControl_t CC_t;

  DEFINE_UNION_CAST(CC2int,uint16_t,CC_t)
  DEFINE_UNION_CAST(int2CC,CC_t,uint16_t)

  uint16_t compareControl()
  {
    CC_t x = {
      cm : 1,    // capture on rising edge
      ccis : 0,  // capture/compare input select
      clld : 0,  // TBCL1 loads on write to TBCCR1
      cap : 0,   // compare mode
      ccie : 0,  // capture compare interrupt enable 
    };
    return CC2int(x);
  }

  uint16_t captureControl(uint8_t l_cm)
  {
    CC_t x = {
      cm : l_cm & 0x03,    // capture on rising edge
      ccis : 0,  // capture/compare input select
      clld : 0,  // TBCL1 loads on write to TBCCR1
      cap : 1,   // compare mode
      scs : 1,   // synchronous capture mode
      ccie : 0,  // capture compare interrupt enable 
    };
    return CC2int(x);
  }

  TOSH_SIGNAL(TIMERA0_VECTOR)
  {
    if ((call ControlA0.getControl()).cap) 
      signal CaptureA0.captured(call CaptureA0.getEvent());
    else
      signal CompareA0.fired();
  }

  TOSH_SIGNAL(TIMERA1_VECTOR)
  {
    int n = TAIV;
    switch( n )
    {
      case  0: break;
      case  2: 
               if ((call ControlA1.getControl()).cap) 
                 signal CaptureA1.captured(call CaptureA1.getEvent());
               else
                 signal CompareA1.fired();
               break;
      case  4: 
               if ((call ControlA2.getControl()).cap) 
                 signal CaptureA2.captured(call CaptureA2.getEvent());
               else
                 signal CompareA2.fired();
               break;
      case  6: break;
      case  8: break;
      case 10: signal TimerA.overflow(); break;
      case 12: break;
      case 14: break;
    }
  }

  default async event void CompareA0.fired() { }
  default async event void CompareA1.fired() { }
  default async event void CompareA2.fired() { }
  default async event void CaptureA0.captured(uint16_t time) { }
  default async event void CaptureA1.captured(uint16_t time) { }
  default async event void CaptureA2.captured(uint16_t time) { }
  default async event void TimerA.overflow() { }

  async command uint16_t TimerA.read() { return TAR; }
  async command uint16_t TimerB.read() { return TBR; }

  async command bool TimerA.isOverflowPending() { return TACTL & TAIFG; }
  async command bool TimerB.isOverflowPending() { return TBCTL & TBIFG; }

  async command void TimerA.clearOverflow() { CLR_FLAG(TACTL,TAIFG); }
  async command void TimerB.clearOverflow() { CLR_FLAG(TBCTL,TBIFG); }

  async command void TimerA.setMode(int mode) { TACTL=(TACTL & ~(MC1|MC0)) | ((mode<<4)&(MC1|MC0)); }
  async command void TimerB.setMode(int mode) { TBCTL=(TBCTL & ~(MC1|MC0)) | ((mode<<4)&(MC1|MC0)); }
  async command int TimerA.getMode() { return (TACTL & (MC1|MC0)) >> 4; }
  async command int TimerB.getMode() { return (TBCTL & (MC1|MC0)) >> 4; }

  async command void TimerA.clear() { TACTL |= TACLR; }
  async command void TimerB.clear() { TBCTL |= TBCLR; }

  async command void TimerA.disableEvents() { TACTL &= ~TAIE;}
  async command void TimerB.disableEvents() { TBCTL &= ~TBIE;}

  async command void TimerA.setClockSource( uint16_t clockSource ) 
  { 
    TACTL = (TACTL & ~(TASSEL0|TASSEL1)) | ((clockSource << 8) & (TASSEL0|TASSEL1));
  }
  
  async command void TimerB.setClockSource( uint16_t clockSource )
  { 
    TBCTL = (TBCTL & ~(TBSSEL0|TBSSEL1)) | ((clockSource << 8) & (TBSSEL0|TBSSEL1));
  }
  
  async command void TimerA.setInputDivider( uint16_t inputDivider )
  {
    TACTL = (TACTL & ~(ID_1|ID_3)) | ((inputDivider << 8) & (ID_1|ID_3));
  }
  
  async command void TimerB.setInputDivider( uint16_t inputDivider )
  {
    TBCTL = (TBCTL & ~(ID_1|ID_3)) | ((inputDivider << 8) & (ID_1|ID_3));
  }
  
  async command CC_t ControlA0.getControl() { return int2CC(TACCTL0); }
  async command CC_t ControlA1.getControl() { return int2CC(TACCTL1); }
  async command CC_t ControlA2.getControl() { return int2CC(TACCTL2); }

  async command bool ControlA0.isInterruptPending() { return TACCTL0 & CCIFG; }
  async command bool ControlA1.isInterruptPending() { return TACCTL1 & CCIFG; }
  async command bool ControlA2.isInterruptPending() { return TACCTL2 & CCIFG; }

  async command void ControlA0.clearPendingInterrupt() { CLR_FLAG(TACCTL0,CCIFG); }
  async command void ControlA1.clearPendingInterrupt() { CLR_FLAG(TACCTL1,CCIFG); }
  async command void ControlA2.clearPendingInterrupt() { CLR_FLAG(TACCTL2,CCIFG); }

  async command void ControlA0.setControl( CC_t x ) { TACCTL0 = CC2int(x); }
  async command void ControlA1.setControl( CC_t x ) { TACCTL1 = CC2int(x); }
  async command void ControlA2.setControl( CC_t x ) { TACCTL2 = CC2int(x); }

  async command void ControlA0.setControlAsCompare() { TACCTL0 = compareControl(); }
  async command void ControlA1.setControlAsCompare() { TACCTL1 = compareControl(); }
  async command void ControlA2.setControlAsCompare() { TACCTL2 = compareControl(); }

  async command void ControlA0.setControlAsCapture(uint8_t cm) { TACCTL0 = captureControl(cm); }
  async command void ControlA1.setControlAsCapture(uint8_t cm) { TACCTL1 = captureControl(cm); }
  async command void ControlA2.setControlAsCapture(uint8_t cm) { TACCTL2 = captureControl(cm); }

  async command void CaptureA0.setEdge(uint8_t cm) { CC_t t = call ControlA0.getControl(); t.cm = cm & 0x03; TACCTL0 = CC2int(t); }
  async command void CaptureA1.setEdge(uint8_t cm) { CC_t t = call ControlA1.getControl(); t.cm = cm & 0x03; TACCTL1 = CC2int(t); }
  async command void CaptureA2.setEdge(uint8_t cm) { CC_t t = call ControlA2.getControl(); t.cm = cm & 0x03; TACCTL2 = CC2int(t); }

  async command void CaptureA0.setSynchronous(bool synch) { if (synch) SET_FLAG(TACCTL0, SCS); else CLR_FLAG(TACCTL0, SCS); }
  async command void CaptureA1.setSynchronous(bool synch) { if (synch) SET_FLAG(TACCTL1, SCS); else CLR_FLAG(TACCTL1, SCS); }
  async command void CaptureA2.setSynchronous(bool synch) { if (synch) SET_FLAG(TACCTL2, SCS); else CLR_FLAG(TACCTL2, SCS); }

  async command void ControlA0.enableEvents() { SET_FLAG( TACCTL0, CCIE ); }
  async command void ControlA1.enableEvents() { SET_FLAG( TACCTL1, CCIE ); }
  async command void ControlA2.enableEvents() { SET_FLAG( TACCTL2, CCIE ); }

  async command void ControlA0.disableEvents() { CLR_FLAG( TACCTL0, CCIE ); }
  async command void ControlA1.disableEvents() { CLR_FLAG( TACCTL1, CCIE ); }
  async command void ControlA2.disableEvents() { CLR_FLAG( TACCTL2, CCIE ); }

  async command bool ControlA0.areEventsEnabled() { return READ_FLAG( TACCTL0, CCIE ); }
  async command bool ControlA1.areEventsEnabled() { return READ_FLAG( TACCTL1, CCIE ); }
  async command bool ControlA2.areEventsEnabled() { return READ_FLAG( TACCTL2, CCIE ); }

  async command uint16_t CompareA0.getEvent() { return TACCR0; }
  async command uint16_t CompareA1.getEvent() { return TACCR1; }
  async command uint16_t CompareA2.getEvent() { return TACCR2; }

  async command uint16_t CaptureA0.getEvent() { return TACCR0; }
  async command uint16_t CaptureA1.getEvent() { return TACCR1; }
  async command uint16_t CaptureA2.getEvent() { return TACCR2; }

  async command void CompareA0.setEvent( uint16_t x ) { TACCR0 = x; }
  async command void CompareA1.setEvent( uint16_t x ) { TACCR1 = x; }
  async command void CompareA2.setEvent( uint16_t x ) { TACCR2 = x; }

  async command void CompareA0.setEventFromPrev( uint16_t x ) { TACCR0 += x; }
  async command void CompareA1.setEventFromPrev( uint16_t x ) { TACCR1 += x; }
  async command void CompareA2.setEventFromPrev( uint16_t x ) { TACCR2 += x; }

  async command void CompareA0.setEventFromNow( uint16_t x ) { TACCR0 = TAR+x; }
  async command void CompareA1.setEventFromNow( uint16_t x ) { TACCR1 = TAR+x; }
  async command void CompareA2.setEventFromNow( uint16_t x ) { TACCR2 = TAR+x; }

  async command bool CaptureA0.isOverflowPending() { return READ_FLAG(TACCTL0, COV); }
  async command bool CaptureA1.isOverflowPending() { return READ_FLAG(TACCTL1, COV); }
  async command bool CaptureA2.isOverflowPending() { return READ_FLAG(TACCTL2, COV); }

  async command void CaptureA0.clearOverflow() { CLR_FLAG(TACCTL0,COV); }
  async command void CaptureA1.clearOverflow() { CLR_FLAG(TACCTL1,COV); }
  async command void CaptureA2.clearOverflow() { CLR_FLAG(TACCTL2,COV); }

  TOSH_SIGNAL(TIMERB0_VECTOR)
  {
    if ((call ControlB0.getControl()).cap) 
      signal CaptureB0.captured(call CaptureB0.getEvent());
    else
      signal CompareB0.fired();
  }

  TOSH_SIGNAL(TIMERB1_VECTOR)
  {
    int n = TBIV;
    switch( n )
    {
      case  0: break;
      case  2: 
               if ((call ControlB1.getControl()).cap) 
                 signal CaptureB1.captured(call CaptureB1.getEvent());
               else
                 signal CompareB1.fired();
               break;
      case  4: 
               if ((call ControlB2.getControl()).cap) 
                 signal CaptureB2.captured(call CaptureB2.getEvent());
               else
                 signal CompareB2.fired();
               break;
      case  6: 
               if ((call ControlB3.getControl()).cap) 
                 signal CaptureB3.captured(call CaptureB3.getEvent());
               else
                 signal CompareB3.fired();
               break;
      case  8: 
               if ((call ControlB4.getControl()).cap) 
                 signal CaptureB4.captured(call CaptureB4.getEvent());
               else
                 signal CompareB4.fired();
               break;
      case 10: 
               if ((call ControlB5.getControl()).cap) 
                 signal CaptureB5.captured(call CaptureB5.getEvent());
               else
                 signal CompareB5.fired();
               break;
      case 12: 
               if ((call ControlB6.getControl()).cap) 
                 signal CaptureB6.captured(call CaptureB6.getEvent());
               else
                 signal CompareB6.fired();
               break;
      case 14: signal TimerB.overflow(); break;
    }
  }

  default async event void CompareB0.fired() { }
  default async event void CompareB1.fired() { }
  default async event void CompareB2.fired() { }
  default async event void CompareB3.fired() { }
  default async event void CompareB4.fired() { }
  default async event void CompareB5.fired() { }
  default async event void CompareB6.fired() { }
  default async event void CaptureB0.captured(uint16_t time) { }
  default async event void CaptureB1.captured(uint16_t time) { }
  default async event void CaptureB2.captured(uint16_t time) { }
  default async event void CaptureB3.captured(uint16_t time) { }
  default async event void CaptureB4.captured(uint16_t time) { }
  default async event void CaptureB5.captured(uint16_t time) { }
  default async event void CaptureB6.captured(uint16_t time) { }
  default async event void TimerB.overflow() { }

  async command CC_t ControlB0.getControl() { return int2CC(TBCCTL0); }
  async command CC_t ControlB1.getControl() { return int2CC(TBCCTL1); }
  async command CC_t ControlB2.getControl() { return int2CC(TBCCTL2); }
  async command CC_t ControlB3.getControl() { return int2CC(TBCCTL3); }
  async command CC_t ControlB4.getControl() { return int2CC(TBCCTL4); }
  async command CC_t ControlB5.getControl() { return int2CC(TBCCTL5); }
  async command CC_t ControlB6.getControl() { return int2CC(TBCCTL6); }

  async command bool ControlB0.isInterruptPending() { return TBCCTL0 & CCIFG; }
  async command bool ControlB1.isInterruptPending() { return TBCCTL1 & CCIFG; }
  async command bool ControlB2.isInterruptPending() { return TBCCTL2 & CCIFG; }
  async command bool ControlB3.isInterruptPending() { return TBCCTL3 & CCIFG; }
  async command bool ControlB4.isInterruptPending() { return TBCCTL4 & CCIFG; }
  async command bool ControlB5.isInterruptPending() { return TBCCTL5 & CCIFG; }
  async command bool ControlB6.isInterruptPending() { return TBCCTL6 & CCIFG; }

  async command void ControlB0.clearPendingInterrupt() { CLR_FLAG(TBCCTL0,CCIFG); }
  async command void ControlB1.clearPendingInterrupt() { CLR_FLAG(TBCCTL1,CCIFG); }
  async command void ControlB2.clearPendingInterrupt() { CLR_FLAG(TBCCTL2,CCIFG); }
  async command void ControlB3.clearPendingInterrupt() { CLR_FLAG(TBCCTL3,CCIFG); }
  async command void ControlB4.clearPendingInterrupt() { CLR_FLAG(TBCCTL4,CCIFG); }
  async command void ControlB5.clearPendingInterrupt() { CLR_FLAG(TBCCTL5,CCIFG); }
  async command void ControlB6.clearPendingInterrupt() { CLR_FLAG(TBCCTL6,CCIFG); }

  async command void ControlB0.setControl( CC_t x ) { TBCCTL0 = CC2int(x); }
  async command void ControlB1.setControl( CC_t x ) { TBCCTL1 = CC2int(x); }
  async command void ControlB2.setControl( CC_t x ) { TBCCTL2 = CC2int(x); }
  async command void ControlB3.setControl( CC_t x ) { TBCCTL3 = CC2int(x); }
  async command void ControlB4.setControl( CC_t x ) { TBCCTL4 = CC2int(x); }
  async command void ControlB5.setControl( CC_t x ) { TBCCTL5 = CC2int(x); }
  async command void ControlB6.setControl( CC_t x ) { TBCCTL6 = CC2int(x); }

  async command void ControlB0.setControlAsCompare() { TBCCTL0 = compareControl(); }
  async command void ControlB1.setControlAsCompare() { TBCCTL1 = compareControl(); }
  async command void ControlB2.setControlAsCompare() { TBCCTL2 = compareControl(); }
  async command void ControlB3.setControlAsCompare() { TBCCTL3 = compareControl(); }
  async command void ControlB4.setControlAsCompare() { TBCCTL4 = compareControl(); }
  async command void ControlB5.setControlAsCompare() { TBCCTL5 = compareControl(); }
  async command void ControlB6.setControlAsCompare() { TBCCTL6 = compareControl(); }

  async command void ControlB0.setControlAsCapture(uint8_t cm) { TBCCTL0 = captureControl(cm); }
  async command void ControlB1.setControlAsCapture(uint8_t cm) { TBCCTL1 = captureControl(cm); }
  async command void ControlB2.setControlAsCapture(uint8_t cm) { TBCCTL2 = captureControl(cm); }
  async command void ControlB3.setControlAsCapture(uint8_t cm) { TBCCTL3 = captureControl(cm); }
  async command void ControlB4.setControlAsCapture(uint8_t cm) { TBCCTL4 = captureControl(cm); }
  async command void ControlB5.setControlAsCapture(uint8_t cm) { TBCCTL5 = captureControl(cm); }
  async command void ControlB6.setControlAsCapture(uint8_t cm) { TBCCTL6 = captureControl(cm); }

  async command void CaptureB0.setEdge(uint8_t cm) { CC_t t = call ControlB0.getControl(); t.cm = cm & 0x03; TBCCTL0 = CC2int(t); }
  async command void CaptureB1.setEdge(uint8_t cm) { CC_t t = call ControlB1.getControl(); t.cm = cm & 0x03; TBCCTL1 = CC2int(t); }
  async command void CaptureB2.setEdge(uint8_t cm) { CC_t t = call ControlB2.getControl(); t.cm = cm & 0x03; TBCCTL2 = CC2int(t); }
  async command void CaptureB3.setEdge(uint8_t cm) { CC_t t = call ControlB3.getControl(); t.cm = cm & 0x03; TBCCTL3 = CC2int(t); }
  async command void CaptureB4.setEdge(uint8_t cm) { CC_t t = call ControlB4.getControl(); t.cm = cm & 0x03; TBCCTL4 = CC2int(t); }
  async command void CaptureB5.setEdge(uint8_t cm) { CC_t t = call ControlB5.getControl(); t.cm = cm & 0x03; TBCCTL5 = CC2int(t); }
  async command void CaptureB6.setEdge(uint8_t cm) { CC_t t = call ControlB6.getControl(); t.cm = cm & 0x03; TBCCTL6 = CC2int(t); }

  async command void CaptureB0.setSynchronous(bool synch) { if (synch) SET_FLAG(TBCCTL0, SCS); else CLR_FLAG(TBCCTL0, SCS); }
  async command void CaptureB1.setSynchronous(bool synch) { if (synch) SET_FLAG(TBCCTL1, SCS); else CLR_FLAG(TBCCTL1, SCS); }
  async command void CaptureB2.setSynchronous(bool synch) { if (synch) SET_FLAG(TBCCTL2, SCS); else CLR_FLAG(TBCCTL2, SCS); }
  async command void CaptureB3.setSynchronous(bool synch) { if (synch) SET_FLAG(TBCCTL3, SCS); else CLR_FLAG(TBCCTL3, SCS); }
  async command void CaptureB4.setSynchronous(bool synch) { if (synch) SET_FLAG(TBCCTL4, SCS); else CLR_FLAG(TBCCTL4, SCS); }
  async command void CaptureB5.setSynchronous(bool synch) { if (synch) SET_FLAG(TBCCTL5, SCS); else CLR_FLAG(TBCCTL5, SCS); }
  async command void CaptureB6.setSynchronous(bool synch) { if (synch) SET_FLAG(TBCCTL6, SCS); else CLR_FLAG(TBCCTL6, SCS); }

  async command void ControlB0.enableEvents() { SET_FLAG( TBCCTL0, CCIE ); }
  async command void ControlB1.enableEvents() { SET_FLAG( TBCCTL1, CCIE ); }
  async command void ControlB2.enableEvents() { SET_FLAG( TBCCTL2, CCIE ); }
  async command void ControlB3.enableEvents() { SET_FLAG( TBCCTL3, CCIE ); }
  async command void ControlB4.enableEvents() { SET_FLAG( TBCCTL4, CCIE ); }
  async command void ControlB5.enableEvents() { SET_FLAG( TBCCTL5, CCIE ); }
  async command void ControlB6.enableEvents() { SET_FLAG( TBCCTL6, CCIE ); }

  async command void ControlB0.disableEvents() { CLR_FLAG( TBCCTL0, CCIE ); }
  async command void ControlB1.disableEvents() { CLR_FLAG( TBCCTL1, CCIE ); }
  async command void ControlB2.disableEvents() { CLR_FLAG( TBCCTL2, CCIE ); }
  async command void ControlB3.disableEvents() { CLR_FLAG( TBCCTL3, CCIE ); }
  async command void ControlB4.disableEvents() { CLR_FLAG( TBCCTL4, CCIE ); }
  async command void ControlB5.disableEvents() { CLR_FLAG( TBCCTL5, CCIE ); }
  async command void ControlB6.disableEvents() { CLR_FLAG( TBCCTL6, CCIE ); }

  async command bool ControlB0.areEventsEnabled() { return READ_FLAG( TBCCTL0, CCIE ); }
  async command bool ControlB1.areEventsEnabled() { return READ_FLAG( TBCCTL1, CCIE ); }
  async command bool ControlB2.areEventsEnabled() { return READ_FLAG( TBCCTL2, CCIE ); }
  async command bool ControlB3.areEventsEnabled() { return READ_FLAG( TBCCTL3, CCIE ); }
  async command bool ControlB4.areEventsEnabled() { return READ_FLAG( TBCCTL4, CCIE ); }
  async command bool ControlB5.areEventsEnabled() { return READ_FLAG( TBCCTL5, CCIE ); }
  async command bool ControlB6.areEventsEnabled() { return READ_FLAG( TBCCTL6, CCIE ); }

  async command uint16_t CompareB0.getEvent() { return TBCCR0; }
  async command uint16_t CompareB1.getEvent() { return TBCCR1; }
  async command uint16_t CompareB2.getEvent() { return TBCCR2; }
  async command uint16_t CompareB3.getEvent() { return TBCCR3; }
  async command uint16_t CompareB4.getEvent() { return TBCCR4; }
  async command uint16_t CompareB5.getEvent() { return TBCCR5; }
  async command uint16_t CompareB6.getEvent() { return TBCCR6; }

  async command uint16_t CaptureB0.getEvent() { return TBCCR0; }
  async command uint16_t CaptureB1.getEvent() { return TBCCR1; }
  async command uint16_t CaptureB2.getEvent() { return TBCCR2; }
  async command uint16_t CaptureB3.getEvent() { return TBCCR3; }
  async command uint16_t CaptureB4.getEvent() { return TBCCR4; }
  async command uint16_t CaptureB5.getEvent() { return TBCCR5; }
  async command uint16_t CaptureB6.getEvent() { return TBCCR6; }

  async command void CompareB0.setEvent( uint16_t x ) { TBCCR0 = x; }
  async command void CompareB1.setEvent( uint16_t x ) { TBCCR1 = x; }
  async command void CompareB2.setEvent( uint16_t x ) { TBCCR2 = x; }
  async command void CompareB3.setEvent( uint16_t x ) { TBCCR3 = x; }
  async command void CompareB4.setEvent( uint16_t x ) { TBCCR4 = x; }
  async command void CompareB5.setEvent( uint16_t x ) { TBCCR5 = x; }
  async command void CompareB6.setEvent( uint16_t x ) { TBCCR6 = x; }

  async command void CompareB0.setEventFromPrev( uint16_t x ) { TBCCR0 += x; }
  async command void CompareB1.setEventFromPrev( uint16_t x ) { TBCCR1 += x; }
  async command void CompareB2.setEventFromPrev( uint16_t x ) { TBCCR2 += x; }
  async command void CompareB3.setEventFromPrev( uint16_t x ) { TBCCR3 += x; }
  async command void CompareB4.setEventFromPrev( uint16_t x ) { TBCCR4 += x; }
  async command void CompareB5.setEventFromPrev( uint16_t x ) { TBCCR5 += x; }
  async command void CompareB6.setEventFromPrev( uint16_t x ) { TBCCR6 += x; }

  async command void CompareB0.setEventFromNow( uint16_t x ) { TBCCR0 = TBR+x; }
  async command void CompareB1.setEventFromNow( uint16_t x ) { TBCCR1 = TBR+x; }
  async command void CompareB2.setEventFromNow( uint16_t x ) { TBCCR2 = TBR+x; }
  async command void CompareB3.setEventFromNow( uint16_t x ) { TBCCR3 = TBR+x; }
  async command void CompareB4.setEventFromNow( uint16_t x ) { TBCCR4 = TBR+x; }
  async command void CompareB5.setEventFromNow( uint16_t x ) { TBCCR5 = TBR+x; }
  async command void CompareB6.setEventFromNow( uint16_t x ) { TBCCR6 = TBR+x; }

  async command bool CaptureB0.isOverflowPending() { return READ_FLAG(TBCCTL0, COV); }
  async command bool CaptureB1.isOverflowPending() { return READ_FLAG(TBCCTL1, COV); }
  async command bool CaptureB2.isOverflowPending() { return READ_FLAG(TBCCTL2, COV); }
  async command bool CaptureB3.isOverflowPending() { return READ_FLAG(TBCCTL3, COV); }
  async command bool CaptureB4.isOverflowPending() { return READ_FLAG(TBCCTL4, COV); }
  async command bool CaptureB5.isOverflowPending() { return READ_FLAG(TBCCTL5, COV); }
  async command bool CaptureB6.isOverflowPending() { return READ_FLAG(TBCCTL6, COV); }

  async command void CaptureB0.clearOverflow() { CLR_FLAG(TBCCTL0,COV); }
  async command void CaptureB1.clearOverflow() { CLR_FLAG(TBCCTL1,COV); }
  async command void CaptureB2.clearOverflow() { CLR_FLAG(TBCCTL2,COV); }
  async command void CaptureB3.clearOverflow() { CLR_FLAG(TBCCTL3,COV); }
  async command void CaptureB4.clearOverflow() { CLR_FLAG(TBCCTL4,COV); }
  async command void CaptureB5.clearOverflow() { CLR_FLAG(TBCCTL5,COV); }
  async command void CaptureB6.clearOverflow() { CLR_FLAG(TBCCTL6,COV); }

}


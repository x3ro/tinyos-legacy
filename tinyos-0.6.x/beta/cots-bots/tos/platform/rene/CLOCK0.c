/*
 * Sarah Bergbreiter
 * 5/25/2001
 * COTS-BOTS project
 *
 * This Clock0 component implementation uses TMR0 to generate events at a
 * rate specified by the argument "interval".
 *
 * History:
 * 5/25/2001 - created by modifying the included CLOCK.c implementation 
 * from Jason Hill.
 * 6/21/2001 - modified so that it can take an argument in initialization
 * command to specify ticks per second (might have to change macros
 * in hardware.h
 * 10/15/2001 - modified for new NEST implementation
 */

#include "tos.h"
#include "CLOCK0.h"

// Frame declaration
#define TOS_FRAME_TYPE CLOCK0_frame
TOS_FRAME_BEGIN(CLOCK0_frame){
  unsigned char interval;
}
TOS_FRAME_END(CLOCK0_frame);

char TOS_COMMAND(CLOCK0_INIT)(unsigned char interval){

  printf("Clock initialized\n");

  VAR(interval) = interval - 1;  // subtract 1 b/c of way count set up
  outp(0x03, TCCR0); // Set prescaler to 64 to see overflow 250 times per sec
  outp(0, TCNT0);    // Reset timer
  sbi(TIMSK, TOIE0); // Enable TMR0 overflow interrupt
  sei();             // Set the global interrupt pin

  return 1;
}

TOS_INTERRUPT_HANDLER(_overflow0_, (void)) {
  // I can overflow at a faster rate if I load a value into TCNT0
  // (not currently implemented -- would add to #defines in hardware.h)
  static unsigned char count = 0;
  if (count == VAR(interval)) {
     TOS_SIGNAL_EVENT(CLOCK0_FIRE_EVENT)();
     count = 0;
  }
  count++;
}













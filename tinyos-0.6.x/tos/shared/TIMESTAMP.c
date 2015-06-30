/* This component creates a timestamp ts.*/

#include "tos.h"
#include "TIMESTAMP.h"

#define TIMESTAMP

uint32_t ts;
uint32_t ts_radio_out;
uint8_t tcnt0_radio_out;
uint32_t ts_radio_backoff;
uint8_t tcnt0_radio_backoff;


void store_radio_in_ts() {
  //reset ts
  ts = 0;
  __outb(0,TCNT0);
}

void store_radio_backoff_ts() {
  ts_radio_backoff = ts;
  tcnt0_radio_backoff = __inb(TCNT0);
}

void store_radio_out_ts() {
  ts_radio_out = ts;
  tcnt0_radio_out = __inb(TCNT0);
}

char TOS_COMMAND(TIMESTAMP_INIT)() {  
  sbi(TIMSK, TOIE0);
  outp(0x03, TCCR0);    //prescale the timer to be clock/64 => 16us
  sei();
  return 1;
}

TOS_INTERRUPT_HANDLER(_overflow0_, (void)) {
  ts++;
}

/**
 * Busy wait component as per TEP102. Supports waiting for at least some
 * number of microseconds. This functionality should be used sparingly,
 * when the overhead of posting a Timer or Alarm is greater than simply
 * busy waiting.
 *
 * Mica2 compatible
 *
 * @author David Gay
 */

module BusyWaitM {
  provides {
    interface BusyWait;
  }
}

implementation {
  inline async command void BusyWait.wait(uint16_t dt) {
    if (dt) {
      /* loop takes 8 cycles. this is 1uS if running on an internal 8MHz
         clock, and 1.09uS if running on the external crystal. */
      asm volatile (
        "1: sbiw    %0,1\n"
        "   adiw    %0,1\n"
        "   sbiw    %0,1\n"
        "   brne    1b" : "+w" (dt));
    }
  }
}

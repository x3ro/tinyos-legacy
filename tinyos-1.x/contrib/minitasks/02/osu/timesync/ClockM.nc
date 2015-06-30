/*
 * Copyright Ted Herman, 2003, All Rights Reserved.
 * To the user: Ted Herman does not and cannot warrant the
 * product, information, documentation, or software (including
 * any fixes and updates) included in this package or the
 * performance or results obtained by using this product,
 * information, documentation, or software. This product,
 * information, documentation, and software is provided
 * "as is". Ted Herman makes no warranties of any kind,
 * either express or implied, including but not limited to,
 * non infringement of third party rights, merchantability,
 * or fitness for a particular purpose with respect to the
 * product and the accompanying written materials. To the
 * extent you use or implement this product, information,
 * documentation, or software in your own setting, you do so
 * at your own risk. In no event will Ted Herman be liable
 * to you for any damages arising from your use or, your
 * inability to use this product, information, documentation,
 * or software, including any lost profits, lost savings,
 * or other incidental or consequential damages, even if
 * Ted Herman has been advised of the possibility of such
 * damages, or for any claim by another party. All product
 * names are trademarks or registered trademarks of their
 * respective holders. Any resemblance to real persons, living
 * or dead is purely coincidental. Contains no peanuts. Void
 * where prohibited. Batteries not included. Contents may
 * settle during shipment. Use only as directed. No other
 * warranty expressed or implied. Do not use while operating a
 * motor vehicle or heavy equipment. This is not an offer to
 * sell securities. Apply only to affected area. May be too
 * intense for some viewers. Do not stamp. Use other side
 * for additional listings. For recreational use only. Do
 * not disturb. All models over 18 years of age. If condition
 * persists, consult your physician. No user-serviceable parts
 * inside. Freshest if eaten before date on carton. Subject
 * to change without notice. Times approximate. Simulated
 * picture. Children under 12 must wear a helmet. May cause
 * oily discharge. Contents under pressure. Pay before pumping
 * after dark. Paba free. Please remain seated until the ride
 * has come to a complete stop. Breaking seal constitutes
 * acceptance of agreement. For off-road use only. As seen on
 * TV. One size fits all. Many suitcases look alike. Contains
 * a substantial amount of non-tobacco ingredients. Colors
 * may, in time, fade. Slippery when wet. Not affiliated with
 * the American Red Cross. Drop in any mailbox. Edited for
 * television. Keep cool; process promptly. Post office will
 * not deliver without postage. List was current at time of
 * printing. Not responsible for direct, indirect, incidental
 * or consequential damages resulting from any defect,
 * error or failure to perform. At participating locations
 * only. Not the Beatles. See label for sequence. Substantial
 * penalty for early withdrawal. Do not write below this
 * line. Falling rock. Lost ticket pays maximum rate. Your
 * canceled check is your receipt. Add toner. Avoid
 * contact with skin. Sanitized for your protection. Be
 * sure each item is properly endorsed. Sign here without
 * admitting guilt. Employees and their families are not
 * eligible. Beware of dog. Contestants have been briefed
 * on some questions before the show. You must be present
 * to win. No passes accepted for this engagement. Shading
 * within a garment may occur. Use only in a well-ventilated
 * area. Keep away from fire or flames. Replace with same
 * type. Approved for veterans. Booths for two or more. Check
 * if tax deductible. Some equipment shown is optional. No
 * Canadian coins. Not recommended for children. Prerecorded
 * for this time zone. Reproduction strictly prohibited. No
 * solicitors. No alcohol, dogs or horses. No anchovies
 * unless otherwise specified. Restaurant package, not for
 * resale. List at least two alternate dates. First pull up,
 * then pull down. Call before digging. Driver does not carry
 * cash. Some of the trademarks mentioned in this product
 * appear for identification purposes only. Objects in
 * mirror may be closer than they appear. Record additional
 * transactions on back of previous stub. Do not fold,
 * spindle or mutilate. No transfers issued until the bus
 * comes to a complete stop. Package sold by weight, not
 * volume. Your mileage may vary. Parental discretion is
 * advised. Warranty void if this seal is broken. Employees
 * do not know combination to safe. Do not expose to rain
 * or moisture. To prevent fire hazard, do not exceed listed
 * wattage. Do not use with any other power source. May cause
 * radio and television interference. Consult your doctor
 * before starting this, or any other program. Drain fully
 * before recharging.
 */

module ClockM {
  provides interface Clock;
  provides interface readClock;
  uses interface Clock as HPLClock;
}
implementation 
{
  uint32_t theClock;
  uint16_t theIncrement;
  uint8_t theInterval, theScale;

  /**
   * Assigns specified value to Clock.  Note: 
   * masks interrupts using mica-style instructions,
   * this code should be replaced by some architecture
   * independent way to ensure the assignment is atomic.
   * @author herman@cs.uiowa.edu
   * @return Always returns SUCCESS.
   */
  command result_t readClock.set( uint32_t t ) {
    dbg(DBG_USR1,"set clock %d\n",t);
    cbi(TIMSK, TOIE0);
    cbi(TIMSK, OCIE0);   // Disable TC0 interrupt
    theClock = t;
    sbi(TIMSK, OCIE0);
    return SUCCESS;
    }

  /**
   * Subroutine: reads current clock. This is done by taking the 
   * current clock and adding the hardware countdown register (TCNT0),
   * multiplied by the current scale.  Probably this code should be  
   * moved to some HPL-layer or be replaced by some architecture
   * independent way to ensure the reading is atomic.
   * @author herman@cs.uiowa.edu
   * @return Returns a clock value.
   */
  uint32_t getClock() {
    const uint16_t tab[8] = { 0, 1, 8, 32, 64, 128, 256, 1024 };
    uint8_t f;
    cbi(TIMSK, TOIE0);
    cbi(TIMSK, OCIE0);   // Disable TC0 interrupt
    f = inp(TCNT0);     
    sbi(TIMSK, OCIE0);
    return theClock + (f * tab[ theScale ]); 
    }

  /**
   * Reads current clock.  See the subroutine getClock() for 
   * implementation details, which are hardware dependent. 
   * @author herman@cs.uiowa.edu
   * @return Returns a clock value.
   */
  command uint32_t readClock.read() { 
    return getClock();
    }
 
  /**
   * Set clock rate.  The only function of this command
   * is to record the scale and interval of the setting
   * before it is passed on to the lower level implementation --
   * we need these parameters to later return an accurate
   * reading and also to increment the clock by the correct
   * amount following a clock interrupt.  
   * @author herman@cs.uiowa.edu
   * @return Returns what the lower-level implementation returns.
   */
  command result_t Clock.setRate(char interval, char scale) {
    const uint16_t tab[8] = { 0, 1, 8, 32, 64, 128, 256, 1024 };
    // NOTE:  this has a bug -- all of this should be masked 
    // from interrupts!
    theClock = getClock();
    theInterval = interval;  theScale = scale & 0x07;
    dbg(DBG_CLOCK,"setRate interval %d scale %d\n", theInterval, theScale);
    // calculate theIncrement from (interval,scale)
    theIncrement = tab[theScale];
    theIncrement *= interval;
    return call HPLClock.setRate(interval,scale);
  }

  /**
   * A trivial implementation between the hardware firing
   * of a Clock.fire() and the application, this just adds
   * an increment to the clock/counter. 
   * @author herman@cs.uiowa.edu
   * @return Returns whatever the fired event returns.
   */
  event result_t HPLClock.fire() { 
    theClock += theIncrement;
    return signal Clock.fire(); 
    }

}

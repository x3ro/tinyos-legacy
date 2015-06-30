/*  
 * 
  * Authors:		Mike Grimmer, Martin Turon
 * Date last modified:  2-20-04
 */

interface Grenade
{
  command result_t readID();
  command result_t readRTClock();
  command result_t PullPin();
  command result_t setInterval(uint8_t interval);
  command result_t setRTClock(uint8_t* time);

  command result_t ArmNow(uint8_t interval);

  command result_t setInterrupt();
  command result_t clrInterrupt();
  command result_t FireReset();

  event result_t readRTClockDone(uint8_t* tod);
  event result_t readIDDone(uint8_t* id);

}


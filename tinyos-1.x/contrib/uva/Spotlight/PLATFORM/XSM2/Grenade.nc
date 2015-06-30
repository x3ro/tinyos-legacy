/*  
 * 
  * Authors:		Mike Grimmer
 * Date last modified:  2-20-04
 */

interface Grenade
{
  command result_t skipROM();
  command result_t setInterrupt(uint8_t interval);
  command result_t clrInterrupt(uint8_t interval);

  command result_t setRTClock(uint8_t *tod);
  command result_t readRTClock();
  command result_t FireReset();
  command result_t PullPin();

  event result_t readRTClockDone(uint8_t tod[4]);
}


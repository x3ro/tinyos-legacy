
/*
 * Authors:		Mike Grimmer
 * Date last modified:  2-20-04
 * 
 */

interface Mag
{

  command result_t On();
  command result_t Off();
  command result_t SetReset();

  command result_t DCAdjustX(uint8_t val);
  command result_t DCAdjustY(uint8_t val);

  event result_t DCAdjustXdone(result_t ok);
  event result_t DCAdjustYdone(result_t ok);

}


/*
 * Authors:		Mike Grimmer
 * Date last modified:  2-20-04
 * 
 */

interface Sounder
{
  command result_t twoTone(uint16_t first, uint16_t second, uint16_t interval);
  command result_t setInterval(uint16_t val);
  command result_t Beep(uint16_t interval);
  command result_t Off();
}

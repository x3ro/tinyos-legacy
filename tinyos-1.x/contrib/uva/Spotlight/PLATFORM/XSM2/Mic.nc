
/*
 * Authors:		Mike Grimmer
 * Date last modified:  2-20-04
 * 
 */

interface Mic 
{

  command result_t MicOn();
  command result_t MicOff();
  command result_t LPFsetFreq(uint8_t freq);
  command result_t HPFsetFreq(uint8_t freq);
  command result_t detectAdjust(uint8_t val);
  command result_t gainAdjust(uint8_t val);
}

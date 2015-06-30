
/*
 * Authors:		Mike Grimmer
 * Date last modified:  2-20-04
 * 
 */

interface PIR 
{

  command result_t On();
  command result_t Off();

  command result_t detectAdjust(uint8_t val);
  command result_t QuadAdjust(uint8_t val);

}

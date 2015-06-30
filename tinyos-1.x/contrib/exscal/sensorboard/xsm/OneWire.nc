/*  
 * 
  * Authors:		Mike Grimmer
 * Date last modified:  2-20-04
 */

interface OneWire
{
  command result_t reset();
  command result_t write(uint8_t byte);
  command result_t read();

  event result_t readDone(uint8_t temp);

}


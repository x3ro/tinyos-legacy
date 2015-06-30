/*  
 * 
  * Authors:		Mike Grimmer
 * Date last modified:  2-20-04
 */

interface SerialID
{
  command result_t read(uint8_t* idloc);

  event result_t readDone();
}


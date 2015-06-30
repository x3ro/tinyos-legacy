/*									tab:4
 * NetworkControl interface
 *
 * Authors: Lin Gu
 * Date:    6/19/2003
 */

interface NetworkControl
{ 
  command result_t set(char cFunc, uint16_t address);
  command result_t disable();
  command result_t disable4(uint16_t maStart1,
			  uint16_t maEnd1,
			  uint16_t maStart2,
			  uint16_t maEnd2,
			  uint16_t maStart3,
			  uint16_t maEnd3,
			  uint16_t maStart4,
			  uint16_t maEnd4);
}

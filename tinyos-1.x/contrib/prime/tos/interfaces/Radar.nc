/*									
 * Authors:  Lin Gu
 * Version:  V0.1
 * Date:     2003-6-16
 */
// Radar operation interface

interface Radar
{ 
  command uint16_t readBit();
  command result_t getData();
  event result_t alarm(uint16_t nHighestRecent);
  // event result_t dataReady(uint16_t data);
}

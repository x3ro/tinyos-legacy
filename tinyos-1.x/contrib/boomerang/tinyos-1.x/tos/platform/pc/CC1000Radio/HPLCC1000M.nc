/**
 * Dummy low level CC1000 hardware access module for TOSSIM
 * modified from HPLCC1000M.nc under platform/mica2
 *
 * Author: Bor-rong Chen
 */

module HPLCC1000M {
  provides {
    interface HPLCC1000;
  }
}
implementation
{
  command result_t HPLCC1000.init() {

    return SUCCESS;
  }

  //********************************************************/
  // function: write                                       */
  // description: accepts a 7 bit address and 8 bit data,  */
  //    creates an array of ones and zeros for each, and   */
  //    uses a loop counting thru the arrays to get        */
  //    consistent timing for the chipcon radio control    */
  //    interface.  PALE active low, followed by 7 bits    */
  //    msb first of address, then lsb high for write      */
  //    cycle, followed by 8 bits of data msb first.  data */
  //    is clocked out on the falling edge of PCLK.        */
  // Input:  7 bit address, 8 bit data                     */
  //********************************************************/

  async command result_t HPLCC1000.write(uint8_t addr, uint8_t data) {

    return SUCCESS;
  }

  //********************************************************/
  // function: read                                        */
  // description: accepts a 7 bit address,                 */
  //    creates an array of ones and zeros for each, and   */
  //    uses a loop counting thru the arrays to get        */
  //    consistent timing for the chipcon radio control    */
  //    interface.  PALE active low, followed by 7 bits    */
  //    msb first of address, then lsb low for read        */
  //    cycle, followed by 8 bits of data msb first.  data */
  //    is clocked in on the falling edge of PCLK.         */
  // Input:  7 bit address                                 */
  // Output:  8 bit data                                   */
  //********************************************************/

  async command uint8_t HPLCC1000.read(uint8_t addr) {
    int cnt;
    uint8_t din;
    uint8_t data = 0;

    return data;
  }


  async command bool HPLCC1000.GetLOCK() {
    char cVal = 0;

    return cVal;
  }
}
  

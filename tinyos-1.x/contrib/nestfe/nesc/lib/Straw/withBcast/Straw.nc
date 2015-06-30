/**
 *  Straw (Scalable Thin and Rapid Amassment Without loss)
 */
interface Straw
{
  /**
   * Application fills up bffr, and calls readDone.
   * Data can reside in either RAM or FLASH.
   *
   * @param start Starting address of data to read
   *
   * @param size Size of data to read
   *
   * @param bffr Buffer space to fill up data
   *
   * @return Always return SUCCESS
   */
  event result_t read(uint32_t start, uint32_t size, uint8_t* bffr);
  
  command result_t readDone(result_t success);

}


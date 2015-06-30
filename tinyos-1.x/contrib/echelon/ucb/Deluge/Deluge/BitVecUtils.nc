
/**
 * BitVecUtils.nc - Provides generic methods for manipulating bit
 * vectors.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

interface BitVecUtils {
  /**
   * Locates the index of the first '1' bit in a bit vector.
   *
   * @param result     the location of the '1' bit
   * @param fromIndex  the index to start search for '1' bit
   * @param bitVec     the bit vector
   * @param length     the length of the bit vector in bits
   * @return           <code>SUCCESS</code> if a '1' bit was found;
   *                   <code>FAIL</code> otherwise.
   * @since 0.1
   */
  command result_t indexOf(uint16_t* pResult, uint16_t fromIndex, 
			   uint8_t* bitVec, uint16_t length);

  /**
   * Counts the number of '1' bits in a bit vector.
   *
   * @param result  the number of '1' bits
   * @param bitVec  the bit vector
   * @param length  the length of the bit vector in bits
   * @return        <code>SUCCESS</code> if the operation completed successfully;
   *                <code>FAIL</code> otherwise.
   * @since 0.1
   */
  command result_t countOnes(uint16_t* pResult, uint8_t* bitVec, 
			     uint16_t length);

  /**
   * Generates an ASCII representation of the bit vector.
   *
   * @param buf     the character array to place the ASCII string
   * @param bitVec  the bit vector
   * @param length  the length of the bit vector in bits
   * @since 0.1
   */
  command void printBitVec(char* buf, uint8_t* bitVec, uint16_t length);
}

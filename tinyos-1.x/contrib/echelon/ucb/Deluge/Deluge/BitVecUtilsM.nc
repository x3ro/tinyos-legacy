
/**
 * BitVecUtilsM.nc - Provides generic methods for manipulating bit
 * vectors.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

module BitVecUtilsM {
  provides interface BitVecUtils;
}

implementation {

  command result_t BitVecUtils.indexOf(uint16_t* pResult, uint16_t fromIndex, 
				       uint8_t* bitVec, uint16_t length) {
    
    uint16_t i = fromIndex;

    if (length == 0)
      return FAIL;
    
    do {
      if (BITVEC_GET(bitVec, i)) {
	*pResult = i;
	return SUCCESS;
      }
      i = (i+1) % length;
    } while (i != fromIndex);
    
    return FAIL;
    
  }

  command result_t BitVecUtils.countOnes(uint16_t* pResult, uint8_t* bitVec, uint16_t length) {

    int count = 0;
    int i;

    for ( i = 0; i < length; i++ ) {
      if (BITVEC_GET(bitVec, i))
	count++;
    }

    *pResult = count;

    return SUCCESS;

  }

  command void BitVecUtils.printBitVec(char* buf, uint8_t* bitVec, uint16_t length) {
#ifdef PLATFORM_PC
    uint16_t i;
    
    dbg(DBG_TEMP, "");
    for ( i = 0; i < length; i++ ) {
      sprintf(buf++, "%d", !!BITVEC_GET(bitVec, i));
    }
#endif	  
  }

}


/**
 * BitVecUtilsC.nc - Provides generic methods for manipulating bit
 * vectors.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

includes BitVecUtils;

configuration BitVecUtilsC {
  provides interface BitVecUtils;
}

implementation {
  components BitVecUtilsM;
  BitVecUtils = BitVecUtilsM;
}

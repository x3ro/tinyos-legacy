/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

/** 
 * Interface for controlling the range of the GeoNeighborhood module.
 */
interface GeoNeighborhoodControl {

  /** 
   * Set the maximum neighbor distance. Values less than 0 
   * indicate infinity.
   */
  command void setMaxDist(double maxdist);

  /** 
   * Get the maximum neighbor distance. 
   */
  command double getMaxDist();

}

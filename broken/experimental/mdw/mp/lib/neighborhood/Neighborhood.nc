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
 * Interface for nodes to acquire information about their local neighborhood.
 * Many interpretations of "neighborhood" are possible - see the various 
 * implementations for details.
 */
interface Neighborhood {

  /** 
   * Initiate creation of this neighborhood graph.
   */
  command result_t getNeighborhood();

  /** 
   * Indicates that the neighborhood has been created.
   */
  event void getNeighborhoodDone(result_t success);

  /**
   * Return the number of neighbors in this Neighborhood. 
   */
  command int numNeighbors();

  /**
   * Return the neighbors in this Neighborhood. The buffer 'neighbors'
   * must be at least the size 'size'. Returns the number of neighbors
   * written to the array.
   */
  command int getNeighbors(uint16_t *neighbors, int size);

}

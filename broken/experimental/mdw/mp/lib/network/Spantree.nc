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
includes Spantree;

/**
 * Interface for creating a spanning tree rooted at some node.
 *
interface Spantree {

  /** 
   * Returns SUCCESS if it's possible to initiate creation of a
   * spanning tree to 'root'.
   */
  command result_t makeSpantree(uint16_t root, uint32_t timeout);

  /**
   * Indicates that a spanning tree is now available.
   * 'stree' is only valid if 'res' is SUCCESS.
   */
  event void spantreeDone(uint16_t root, spantree_t *stree, result_t res);

  /**
   * Lock the given spantree.
   */
  command result_t lockSpantree(uint16_t root);

  /**
   * Unlock the given spantree.
   */
  command result_t unlockSpantree(uint16_t root);

  /**
   * Indicates that the spanning tree for 'root' was removed from 
   * the spanning tree cache.
   */
  event void spantreeEvicted(uint16_t root);
}


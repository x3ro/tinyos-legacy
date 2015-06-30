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

includes Collective;

/**
 * Reduce: Generic tree-based reduction interface. 
 */
interface Reduce {

  /**
   * Reduce using the specified operator 'op' on 'inbuf' of type
   * 'type' to 'root_addr'. The result will be stored in 'outbuf' on 
   * 'root'.
   * 
   * @return SUCCESS if the reduction could be initiated; FAIL otherwise
   *   (for example, if another reduction is in progress).
   */
  command result_t reduceToOne(uint16_t root, operator_t op, type_t type,
      void *inbuf, void *outbuf);

  /**
   * Reduce using the specified operator 'op' on 'inbuf' of type
   * 'type'. The result will be stored in 'outbuf' on all nodes
   * participating in the reduction. 'root' is used as the root of
   * the reduction tree.
   * 
   * @return SUCCESS if the reduction could be initiated; FAIL otherwise
   *   (for example, if another reduction is in progress).
   */
  command result_t reduceToAll(uint16_t root, operator_t op, type_t type,
      void *inbuf, void *outbuf);

  /**
   * Act as a pass-through node for a reduction; that is, do not take
   * part in the reduction but allow messages to be routed.
   */
  command result_t passThrough();

  /**
   * Signalled on a node when a reduction is complete.
   * @param outbuf The output buffer of the completed reduction.
   * Will be NULL on nodes that were not targets of the reduction
   * or which performed a passThrough().
   *
   * @param res The result of the reduction; FAIL indicates that the
   *   reduction could not be completed.
   */
  event void reduceDone(void *outbuf, result_t res);

  /**
   * Returns the size in bytes of the given type.
   */
  command int typeSize(type_t type);

}


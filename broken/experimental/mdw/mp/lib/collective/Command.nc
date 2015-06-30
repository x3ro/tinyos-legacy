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
 * Command: Simple command interface, wrapping Active Messages with a 
 * simplified interface allowing applications to invoke or broadcast
 * commands to other nodes.
 */
interface Command {

  command result_t invoke(uint16_t destaddr, uint16_t commandID, uint8_t *params, uint16_t params_len);
  command result_t broadcast(uint16_t commandID, uint8_t *params, uint16_t params_len);
  event void receive(uint16_t commandID, uint8_t *params, uint16_t paramslen);
  command result_t sendToBase(uint16_t commandID, uint8_t *params, uint16_t params_len);

}

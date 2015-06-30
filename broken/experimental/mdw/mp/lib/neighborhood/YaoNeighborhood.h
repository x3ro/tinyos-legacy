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

typedef struct PickEdgeMsg {
  uint16_t fromaddr;
  uint16_t toaddr;
} __attribute__ ((packed)) PickEdgeMsg;

typedef struct InvalidateMsg {
  uint16_t fromaddr;
  uint16_t toaddr;
} __attribute__ ((packed)) InvalidateMsg;

enum {
  AM_YAONEIGHBORHOOD_PICKEDGEMSG = 98,
  AM_YAONEIGHBORHOOD_INVALIDATEMSG = 99,
};

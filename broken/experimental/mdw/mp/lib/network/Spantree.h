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

static int SPANTREE_NO_PARENT = 0xffff;
static int SPANTREE_MS_PER_TICK = 1000;

enum {
  SPANTREE_CACHE_SIZE = 4,
  AM_SPANTREEMSG = 78,
  EMPTY_ROOT = 0xffff,
};

typedef struct {
  uint16_t root;
  uint16_t parent;
  uint8_t depth;
} spantree_t;

typedef struct MaketreeMsg {
  uint16_t rootaddr;
  uint16_t srcaddr;
  uint8_t depth;
} MaketreeMsg;


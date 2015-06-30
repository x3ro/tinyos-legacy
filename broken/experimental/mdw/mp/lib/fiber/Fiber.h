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

#ifdef PLATFORM_PC
enum {
  MAX_FIBERS = 1,
  MAX_STACK_SIZE = 16384,
};
#endif

#ifdef PLATFORM_MICA
enum {
  MAX_FIBERS = 1,
  MAX_STACK_SIZE = 512,
};
#endif

typedef struct _fiber_t {
  int fiber_num;
  void *internal;
  struct _fiber_t **queue;
  struct _fiber_t *next;
} fiber_t;

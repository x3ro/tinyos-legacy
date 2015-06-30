/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
includes Mate;
includes Motlle;
interface MotlleGC
{
  // Access to the "safe over GC" fixed-size, pre-allocated stack
  command uint8_t gcpush(mvalue x);
  command mvalue gcfetch(uint8_t sindex);
  command mvalue gcpopfetch();
  command void gcpop(uint8_t count);

  command void collect();

  command void forward(mvalue *ptr);
  command void sforward(svalue *ptr);
  command uint8_t *base(); /* Return base of memory area */
  command mvalue entry_point();
  command bool mutable(void *ptr);

  command uint8_t *allocate(msize n);
}

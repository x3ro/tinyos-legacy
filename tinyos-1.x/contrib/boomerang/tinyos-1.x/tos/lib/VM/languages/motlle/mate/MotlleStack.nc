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
interface MotlleStack
{
  // Frame allocation
  command void *alloc_frame(MateContext *context, framekind kind, msize size);
  command bool pop_frame(MateContext *context, msize size,
			 uint8_t stack_move_count);
  command void *current_frame(MateContext *context);

  command void reset(MateContext *context);

  command void *fp(MateContext *context);
  command void *sp(MateContext *context);

  // Reserve stack space
  command bool reserve(MateContext *context, msize n);

  command bool push(MateContext *context, mvalue x);
  command void qpush(MateContext *context, mvalue x); // does not reserve
  command mvalue pop(MateContext *context, uint8_t n);
  command mvalue get(MateContext *context, uint8_t sindex);

  command mvalue getOtherFrame(void *osp, uint8_t sindex);
  command void putOtherFrame(void *osp, uint8_t sindex, mvalue v);
}

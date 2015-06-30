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
/*
  MateStackVariable (mate value): the standard mate representation, 
    for use when communicating with standard mate primitives via
    the MateStacks interface.
*/
interface MotlleValues {
  command mvalue read(svalue *location);
  command mvalue read_unaligned(svalue *location);
  command void write(svalue *location, mvalue x);

  // Categories

  // integers (unboxed)
  command bool integerp(mvalue x);
  command ivalue integer(mvalue x);
  command mvalue make_integer(ivalue x);

  // floats (unboxed, not always present)
  command bool realp(mvalue x);
  command float real(mvalue x);
  command mvalue make_real(float x);

  // atoms
  command bool atomp(mvalue x);
  command avalue atom(mvalue x);
  command mvalue make_atom(avalue x);

  // boxed objects
  command bool pointerp(mvalue x);
  command pvalue pointer(mvalue x);
  command mvalue make_pointer(pvalue x);
  command msize size(pvalue x);
  command msize fullsize(pvalue x);
  command mtype ptype(pvalue x);
  command void *data(pvalue x);
  command pvalue make_pvalue(void *x);

  command pvalue forward(pvalue from, uint8_t *to, msize gc_offset, msize fsize);
  command bool forwardedp(pvalue x);
  command pvalue forward_get(pvalue old);
  command void *skip_header(uint8_t *baseptr);

  // Miscellaneous
  command bool truep(mvalue x);
  command void *allocate(mtype type, msize s);

  // load-time relocation (this is here, because value representation
  // may obviate the need for relocation...)
  command void relocate(void *loaded, msize s);

  // Marks. Use the forwarding bits, so don't use if GC can occur!
  command void mark(mvalue x);
  command void unmark(mvalue x);
  command bool marked(mvalue x);
}

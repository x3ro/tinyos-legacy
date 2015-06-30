/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MotlleRepM
{
  provides interface MotlleValues as V;
  uses interface MotlleGC as GC;
}
implementation
{
  enum {
    ATOM_BASE = 0x8000
  };

  // An unsigned int which will hold any value
  typedef uint16_t uvalue;

  msize size_align(msize n) {
    return ALIGN(n, MOTLLE_HEAP_ALIGNMENT);
  }

  command mvalue V.read(svalue *location) {
#ifdef PLATFORM_LITTLE_ENDIAN
    return (mvalue)*location;
#else
    return call V.read_unaligned(location);
#endif
  }

  command mvalue V.read_unaligned(svalue *location) {
#if defined(PLATFORM_REQUIRES_ALIGNMENT) || !defined(PLATFORM_LITTLE_ENDIAN)
    uint8_t *loc = (uint8_t *)location;
    return (mvalue)(loc[0] | loc[1] << 8);
#else
    return call V.read(location);
#endif
  }

  command void V.write(svalue *location, mvalue x) {
#ifdef PLATFORM_LITTLE_ENDIAN
    *location = (svalue)x;
#else
    uint8_t *loc = (uint8_t *)location;
    loc[0] = x;
    loc[1] = x >> 8;
#endif
  }

  // Categories

  // integers (unboxed)
  command bool V.integerp(mvalue x) {
    return (uvalue)x & 1;
  }

  command ivalue V.integer(mvalue x) {
    return (ivalue)x >> 1;
  }

  command mvalue V.make_integer(ivalue x) {
    return (mvalue)(x << 1 | 1);
  }

  // floats (unboxed, not present)
  command bool V.realp(mvalue x) {
    return FALSE;
  }

  command float V.real(mvalue x) {
    return 0.0;
  }

  command mvalue V.make_real(float x) {
    return call V.make_integer(0);
  }

  // atoms
  command bool V.atomp(mvalue x) {
    return (uvalue)x >= ATOM_BASE && !call V.integerp(x);
  }

  command avalue V.atom(mvalue x) {
    return ((uvalue)x - ATOM_BASE) >> 1;
  }

  command mvalue V.make_atom(avalue x) {
    return (mvalue)((x << 1) + ATOM_BASE);
  }

  // boxed objects
  command bool V.pointerp(mvalue x) {
    return !((uvalue)x & 1) && (uvalue)x < ATOM_BASE;
  }

  command pvalue V.pointer(mvalue x) {
    return (pvalue)x;
  }

  command mvalue V.make_pointer(pvalue x) {
    return (mvalue)x;
  }

  uint8_t *objbase(pvalue x) {
    return call GC.base() + (uvalue)x;
  }

  command void *V.skip_header(uint8_t *baseptr) {
    return baseptr + sizeof(uint16_t);
  }

  uint16_t header(pvalue x) {
    uint8_t *base = objbase(x);

    return base[0] | ((uvalue)base[1] << 8);
  }

  command msize V.size(pvalue x) {
    return header(x) >> 4;
  }

  command msize V.fullsize(pvalue x) {
    return size_align(header(x) >> 4) + sizeof(uint16_t);
  }

  command mtype V.ptype(pvalue x) {
    return (header(x) & 0xf) >> 1;
  }

  command void *V.data(pvalue x) {
    return call V.skip_header(objbase(x));
  }

  command pvalue V.make_pvalue(void *x) {
    return (pvalue)((uint8_t *)x - sizeof(uint16_t) - call GC.base());
  }

  command bool V.forwardedp(pvalue x) {
    return header(x) & 1;
  }

  command pvalue V.forward(pvalue old, uint8_t *to, msize gc_offset, msize fullsize) {
    pvalue newv = (pvalue)(to - call GC.base() + gc_offset);
    uint8_t *oldhdr = objbase(old);
    uint16_t fw;

    memcpy(to, oldhdr, fullsize);
    fw = (uvalue)newv | 1;
    oldhdr[0] = fw;
    oldhdr[1] = fw >> 8;

    return newv;
  }

  command pvalue V.forward_get(pvalue old) {
    return (pvalue)(header(old) & ~1);
  }

  // load-time relocation (this is here, because value representation
  // may obviate the need for relocation...)
  command void V.relocate(void *loaded, msize size) {
  }

  command void *V.allocate(mtype type, msize size) {
    uint16_t hdr = size << 4 | type << 1;
    uint8_t *newp = call GC.allocate(size_align(size) + sizeof(uint16_t));

    if (!newp)
      return NULL;

    newp[0] = hdr;
    newp[1] = hdr >> 8;

    return call V.skip_header(newp);
  }

  command bool V.truep(mvalue x) {
    return x != call V.make_integer(0);
  }

  // Marks. Use the forwarding bits, so don't use if GC can occur!
  command void V.mark(mvalue x) {
    if (call V.pointerp(x))
      {
	uint8_t *hdr = objbase(call V.pointer(x));

	hdr[0] |= 1;
      }
  }

  command void V.unmark(mvalue x) {
    if (call V.pointerp(x))
      {
	uint8_t *hdr = objbase(call V.pointer(x));

	hdr[0] &= ~1;
      }
  }

  command bool V.marked(mvalue x) {
    return call V.pointerp(x) && call V.forwardedp(call V.pointer(x));
  }
}

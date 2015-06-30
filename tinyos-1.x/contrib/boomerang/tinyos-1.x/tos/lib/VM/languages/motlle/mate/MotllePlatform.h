/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* For each platform, you should define the following constants:
   MOTLLE_STACK_ALIGNMENT: enough alignment for the svalue and all
     stack frame types.
   MOTLLE_HEAP_ALIGNMENT: enough alignment for all heap-stored objects,
     and must also take account of the current value encoding

   Also, you should #define 
   PLATFORM_LITTLE_ENDIAN if your platform is little-endian.
   PLATFORM_REQUIRES_ALIGNMENT except if your platform supports unaligned 
     reads.
   MINLINE to inline if you want to inline performance-critical routines
     and can afford the code space, or to nothing if you can't

   Note also that you should check that the value returned by GC.base() in
   MemoryM.nc is appropriately aligned for the MotlleValues.read and write
   commands (if it isn't, the easiest "fix" is to modify the implementations
   of read and write in rep-{16,float}/MotlleRepM.nc to accept unaligned
   pointers).
*/

#if defined(PLATFORM_MICA) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_MICAZ)

enum {
  MOTLLE_STACK_ALIGNMENT = 1,
  MOTLLE_HEAP_ALIGNMENT = 2
};

#define PLATFORM_LITTLE_ENDIAN
#undef PLATFORM_REQUIRES_ALIGNMENT

/* Trade code space for performance */
#define MINLINE inline
  
#elif defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB)

enum {
  MOTLLE_STACK_ALIGNMENT = 2,
  MOTLLE_HEAP_ALIGNMENT = 2
};

#define PLATFORM_LITTLE_ENDIAN
#define PLATFORM_REQUIRES_ALIGNMENT

/* Trade performace for code space */
#define MINLINE
  
#else
#error "Unsupported platform. Add appropriate definitions to this file (MotllePlatform.h)"
#endif

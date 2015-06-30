/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#ifndef MOTLLEMULTIHOP_H
#define MOTLLEMULTIHOP_H

/* Pick a multi-hop router appropriate for your platform */
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)

#define ROUTER WMEWMAMultiHopRouter

#elif defined(PLATFORM_TELOS) || defined(PLATFORM_TELOSB) || defined(PLATFORM_MICAZ)
  
#define ROUTER LQIMultiHopRouter

#else
#error "Unsupported platform. Add appropriate definitions to this file (MotlleMultihop.h)"
#endif

#endif

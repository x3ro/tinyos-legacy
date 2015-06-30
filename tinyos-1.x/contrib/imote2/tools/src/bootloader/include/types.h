/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @file types.h
 * @author
 *
 * Type defines for the data types.
 *
 */
#ifndef BL_TYPES_H
#define BL_TYPES_H

#ifndef _STDLIB_H_
#ifndef _STDINT_H_
typedef signed int	int32_t;
typedef signed short	int16_t;
typedef signed char	int8_t;

typedef unsigned int	uint32_t;
typedef unsigned short	uint16_t;
typedef	unsigned char	uint8_t;
#endif
#endif

typedef unsigned char	result_t;

typedef unsigned char bool;

/* Few definitions that we use to prevent too many changes in the Ported (TinyOS) Code */

#ifdef FALSE //if FALSE is defined, undefine it, for the enum below
#undef FALSE
#endif
#ifdef TRUE //if TRUE is defined, undefine it, for the enum below
#undef TRUE
#endif
enum {
  FALSE = 0,
  TRUE = 1
};


enum { /* standard codes for result_t */
  FAIL = 0,
  SUCCESS = 1
};


#endif

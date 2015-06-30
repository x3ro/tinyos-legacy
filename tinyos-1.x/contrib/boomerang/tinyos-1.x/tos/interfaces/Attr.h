// $Id: Attr.h,v 1.1.1.1 2007/11/05 19:09:01 jpolastre Exp $

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

/* 
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     6/27/2002
 *
 */

// Header files for attributes -- See AttrUse.ti and AttrRegister.ti

// XXX nested .th files are not supported yet
// includes SchemaType;


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */

#define NUM_SYSTEM_ATTRS	13
#ifdef BOARD_MICASB
#define	NUM_SENSOR_ATTRS	10
#elif BOARD_MICAWB
#define NUM_SENSOR_ATTRS	6
#elif BOARD_MICAWBDOT
#define NUM_SENSOR_ATTRS	16
#endif

enum {
#if NESC >= 110
	MAX_ATTRS = uniqueCount("Attr")
#else
	MAX_ATTRS = NUM_SYSTEM_ATTRS 
//may not always be defined
#ifdef NUM_SENSOR_ATTRS
	   + NUM_SENSOR_ATTRS
#endif
#endif /* NESC >= 110 */
,
	MAX_CONST_LEN = 4,
	MAX_CONST_ATTRS = 1
};

// will add support for other languages later
typedef struct {
	TOSType type;	
	uint8_t nbytes;
    uint8_t idx; //index into AttrDesc array
	uint8_t id; // id for AttrRegister interface dispatch
	int8_t constIdx;  // index for constant values
	char *name;
} AttrDesc;

typedef AttrDesc *AttrDescPtr;

typedef struct {
  uint8_t numAttrs;
  AttrDesc attrDesc[MAX_ATTRS];
} AttrDescs;

typedef AttrDescs *AttrDescsPtr;

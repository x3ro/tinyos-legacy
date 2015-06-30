// $Id: TupleM.nc,v 1.5 2004/07/17 00:07:53 jhellerstein Exp $

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
 * Authors:	Joe Hellerstein
 *              Design by Sam Madden, Wei Hong, and Joe Hellerstein
 * Date last modified:  7/14/04
 *
 *
 */

/**
 * @author Joe Hellerstein
 * @author Design by Joe Hellerstein
 * @author Wei Hong
 * @author and Sam Madden
 */

includes Attr;

/* Routines to manage a tuple */
module TupleM {
#ifdef kUART_DEBUGGER
  uses {
    interface Debugger as UartDebugger;
  }
#endif
  provides {
    interface Tuple;
  }
}

implementation {
  uint16_t typeToSize(TOSType type);
  uint16_t fieldOffset(TupleDescPtr tdesc, uint8_t fieldIdx);

  /** Zero out the storage in this tuple 
      @param t The Tuple to init */
  command result_t Tuple.tupleInit(TupleStructPtr t) {
	memset((void *)t, 0, sizeof(TupleStruct));
	return SUCCESS;
  }

  /** Set the specified field in the specified tuple, using the provided tuple descriptor
      to determine where to write the data.
      @param t The tuple whose field is to be set
	  @param tdesc Tuple descriptor for this tuple
      @param fieldIdx The index of the field to set
      @param data The data to write into the field
	  @param isNull Is the field NULL valued?
      @return FAIL if the field is out or range, SUCCESS otherwise.
  */
  command result_t Tuple.setField(TupleStructPtr t,
							TupleDescPtr tdesc,
							uint8_t fieldIdx, 
							CharPtr data,
							bool isNull) {
	uint16_t offset;

	if (fieldIdx > tdesc->numFields)
	  return FAIL;

	offset = fieldOffset(tdesc, fieldIdx);
	  
	// copy the data into the field
	memcpy(&(t->fieldData[offset]), data, typeToSize(tdesc->fDescs[fieldIdx].type));
	t->notNull |= ((!isNull) << fieldIdx);
	return SUCCESS;
  }
	

  /** Return a pointer into the field data for the specified field, using the
      provided arrays of sizes and types to compute the appropriate offset.
      @param t The tuple whose field is to be set
	  @param tdesc Tuple descriptor for this tuple
      @param fieldIdx The index of the field to set
	  @param fieldData A variable caller provides to overwrite with the data in the field
	  @param isNull A variable caller provides to overwrite if field is NULL valued or not.
      @return FAIL if the field is out of range, SUCCESS otherwise
  */
  command result_t Tuple.getFieldPtr(TupleStructPtr t, 
							   TupleDescPtr tdesc,
							   uint8_t fieldIdx,
							   CharPtr *fieldData, // OUT
							   bool *isNull // OUT
							   ) {
	if (fieldIdx > tdesc->numFields)
	  return FAIL;

	*fieldData = &(t->fieldData[fieldOffset(tdesc, fieldIdx)]);
	*isNull = t->notNull & (1 << fieldIdx);
	return SUCCESS;
  }

  uint16_t typeToSize(TOSType type) {
	return sizeOf(type);
  }

  uint16_t fieldOffset(TupleDescPtr tdesc, uint8_t fieldIdx) {
	uint16_t offset;
	uint8_t i;

	// figure out offset of the field
	for (i=0; i < fieldIdx; i++)
	  offset += typeToSize(tdesc->fDescs[i].type);
	return offset;
  }

}



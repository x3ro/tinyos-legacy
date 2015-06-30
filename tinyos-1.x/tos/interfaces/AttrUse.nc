// $Id: AttrUse.nc,v 1.4 2003/10/07 21:46:13 idgay Exp $

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

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */


includes SchemaType;
includes Attr;

/** Interface for using Attributes.  Attributes provided a generic mechanism for 
	registering named attribute-value pairs and retrieving their values.
    <p>
    See lib/Attributes/... for examples of components that register attributes
    <p>
    See interfaces/Attr.h for the data structures used in this interface 
    <p>
    Implemented by lib/Attr.td
    <p>
    @author Wei Hong (wei.hong@intel-research.net)
*/

interface AttrUse
{
  /** Get a descriptor for the specified attribute
      @param name The (8 byte or shorted, null-terminated) name for the attribute of interest.
      @return A pointer to the attribute descriptior, or NULL if no such attribute exists.
  */
  command AttrDescPtr getAttr(char *name);

  /** Get a descriptor for the specified attribute
      @param attrIdx THe (0-based) index of the attribute of interest
      @return A pointer to the attribute descriptior, or NULL if no such attribute exists.
  */
  command AttrDescPtr getAttrById(uint8_t attrIdx);

  /** Get the number of attributes currently registered with the system
      @return The number of attributes currently registered with the system. 
  */	
  command uint8_t numAttrs();

  /** Returns a list of all attributes in the system.
      @return A list of all the attributes in the system 
  */
  command AttrDescsPtr getAttrs();

  /** Get the value of a specified attribute.
      @param name The name of the attribute to fetch
      @param resultBuf The buffer to write the value into (must be at least sizeOf(AttrDescPtr.type) long)
      @param errorNo (on return) The error code, if any (see SchemaType.h for a list of error codes.) Note that
             the error code may be SCHEMA_RESULT_PENDING, in which case a getAttrDone event will be fired
	     at some point to indicate that the data has been written into resultBuf.
  */	     
  command result_t getAttrValue(char *name, char *resultBuf, SchemaErrorNo *errorNo);

  /** Set the value of the specified attribute.
      @param name The attribute to set
      @param attrVal The value to set it to
  */
  command result_t setAttrValue(char *name, char *attrVal);

  /** Signal that a specific getAttrValue command is complete.
      @param name The name of the command that finished
      @param resultBuf The buffer that the value was written into
      @param errorNo The result code from the get command
  */
  event result_t getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo);
  /** start an attribute, e.g., power up a sensor
      @param name The name of the attribute to start
  */	     
  command result_t startAttr(uint8_t id);

  /** Signal that an attribute has been started
      @param name attribute name
  */
  event result_t startAttrDone(uint8_t id);
}

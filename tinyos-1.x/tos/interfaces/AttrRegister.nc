// $Id: AttrRegister.nc,v 1.5 2004/03/09 18:30:09 idgay Exp $

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

/** Interface for registering attributes.	
    <p>
    See lib/Attributes/... for examples of components that register attributes
    <p>
    See interfaces/Attr.h for the data structures used in this interface.  See
    docs/tinyschema.pdf for more detailed documentation.
    <p>
    Implemented by lib/Attr.td
    <p>

    @author Wei Hong (wei.hong@intel-research.net)
*/
interface AttrRegister
{
  /** Register an attribute with the specified name, type, and length.
	@param name The name of the attribute to register. Must be in global
	  storage.
	@param attrType The type of the attribute to register (see SchemaType.h for a list of types.)
	@param attrLen The length (in bytes) of the attribute.
  */
  command result_t registerAttr(char *name, TOSType attrType, uint8_t attrLen);

  /** The provider (client) receives this event when a request for an attribute
      value is made.  See AttrUse.td.  The provider must fetch the value
      of the attribute (and/or set the errorNo.)  If this is a split phase
      get, the client must call getAttrDone() once the fetch is complete.
      @param name The name of the attribute to get
      @param resultBuf The buffer to write the result into
      @param errorNo (on return) The error code, if any (see SchemaType.h)
  */
  event result_t getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo);

  /* The provider (client) receives this event when a request to set an attribute
     value is made. 
     @param name The name of the attribute to set
     @param attrValue The value to set the attribute to
  */
  event result_t setAttr(char *name, char *attrVal);
  
  /** Should be called when a split-phase attribute get has completed.
      @param name The name of the attribute that was fetched
      @param resultBuf The buffer where the value of the result was written
      @param errorNo An error code
  */
  command result_t getAttrDone(char *name, char *resultBuf, SchemaErrorNo errorNo);
  /** The provider (client) receives this event when a request to start an
      attribute is made.  See AttrUse.td. 
      @param name The name of the attribute to start
  */
  event result_t startAttr();
  /**  command to be called when an attribute has been started
      @param name The name of the attribute that was fetched
  */
  command result_t startAttrDone();
}

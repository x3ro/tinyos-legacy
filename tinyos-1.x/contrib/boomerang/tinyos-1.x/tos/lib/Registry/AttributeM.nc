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
 * @author Kamin Whitehouse
 */

generic module AttributeM(typedef AttributeType_t) {
  provides{
    interface StdControl;
    interface Attribute<AttributeType_t>;
    interface AttrBackend;
  }
}
implementation {
  AttributeType_t val;
  bool isvalid;

  command result_t StdControl.init() {
    isvalid=0;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  command bool Attribute.valid() {
    return isvalid;
  }

  command AttributeType_t Attribute.get() {
    return val;
  }

  command const void* AttrBackend.get() {
    return &val;
  }

  command result_t Attribute.set(AttributeType_t newval) {
    val=newval;
    isvalid=TRUE;
    signal Attribute.updated(val);
    signal AttrBackend.updated(&val);
    return SUCCESS;
  }
  command result_t AttrBackend.set(const void* newval) {
    if (newval!=NULL)
      return call Attribute.set( (*(AttributeType_t*)newval));
    else
      return FAIL;
  }

  command result_t Attribute.update() {
    //the default Attribute is cached, not split-phase
    return FAIL;
  }
  command result_t AttrBackend.update() {
    //the default Attribute is cached, not split-phase
    return FAIL;
  }


  default event void Attribute.updated(AttributeType_t newval)  {
  }
  default event void AttrBackend.updated(const void* newval)  {
  }


  command uint8_t AttrBackend.size() {
    return sizeof(AttributeType_t);
  }

}


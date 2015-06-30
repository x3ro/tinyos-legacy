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

module RegistryM{
  provides {
    interface StdControl;
    interface GenericBackend;
    interface AttrBackend as MockAttrBackend;
  }
  uses {
    interface AttrBackend[AttrID_t attrID];
  }
}
implementation {

  /*******************
   * this module just translates from the runtime parameter used by
   * GenericBackend to the compile time parameter used by AttrBackend.
   *****************/

  command uint8_t GenericBackend.size(const void* itemID){
    return call AttrBackend.size[*(AttrID_t*)itemID]();
  }

  command const void* GenericBackend.get(const void* itemID){
    return call AttrBackend.get[*(AttrID_t*)itemID]();
  }

  command result_t GenericBackend.update(const void* itemID){
    return call AttrBackend.update[*(AttrID_t*)itemID]();
  }

  command result_t GenericBackend.set(const void* itemID, const void* data){
    return call AttrBackend.set[*(AttrID_t*)itemID](data);
  }

  event void AttrBackend.updated[uint8_t attrID](const void* val){
    signal GenericBackend.updated(&attrID, val);
  }

  default command uint8_t AttrBackend.size[AttrID_t attrID](){
    return 0;
  }

  default command const void* AttrBackend.get[AttrID_t attrID](){
    return NULL;
  }

  default command result_t AttrBackend.set[AttrID_t attrID](const void* val){
    return FAIL;
  }

  default command result_t AttrBackend.update[AttrID_t attrID](){
    return FAIL;
  }

  default event void GenericBackend.updated(const void* itemID, const void* newvalue){
  }

  // Stub StdControl implementation to make RegistryC happy if there are
  // no other StdControl's to wire to
  command result_t StdControl.init() { return SUCCESS; }
  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  // Mock AttrBackend implementaiton to make RegistryC happy if there are
  // no other AttrBackend's to wire to
  command uint8_t MockAttrBackend.size() { return 0; }
  command const void* MockAttrBackend.get() { return NULL; }
  command result_t MockAttrBackend.set(const void* val) { return FAIL; }
  command result_t MockAttrBackend.update() { return FAIL; }
}


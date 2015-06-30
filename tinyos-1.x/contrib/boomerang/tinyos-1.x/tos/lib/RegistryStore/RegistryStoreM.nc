// $Id: RegistryStoreM.nc,v 1.1.1.1 2007/11/05 19:09:16 jpolastre Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Kamin Whitehouse
 */

includes Registry;
includes RegistryStore;

module RegistryStoreM {
  provides {
    interface RegistryStore;
  }
  uses {
    interface InternalFlash;
    interface AttrBackend[AttrID_t attrID];
  }
}

implementation {

  command result_t RegistryStore.clearAll() {
    uint8_t buf[REGISTRY_STORE_SIZE];
    memset(buf, 0, REGISTRY_STORE_SIZE);
    call InternalFlash.write(0, buf, REGISTRY_STORE_SIZE);
    return SUCCESS;
  }

  command result_t RegistryStore.save(uint8_t attr) {
    void *ptr = (void*)call AttrBackend.get[storedAttributes[attr][0]]();
    if (attr >= NUM_STORED_ATTRS) {
      return 2;
    }
    if (ptr == NULL) {
      return 3;
    }
    return call InternalFlash.write( (void*)storedAttributes[attr][1], 
				     ptr, storedAttributes[attr][2]);
  }

  command result_t RegistryStore.restore(uint8_t attr) {
    /*We must set the attribute first, or it might fail on get.
     This means that if this function returns false, the attribute
    will be reset to value 0.  I think this is Ok.*/
    void* ptr;
    uint8_t buf[REGISTRY_STORE_SIZE];
    memset(buf, 0, REGISTRY_STORE_SIZE);
    call AttrBackend.set[storedAttributes[attr][0]]((void*)(&buf));
    ptr = (void*)call AttrBackend.get[storedAttributes[attr][0]]();
    if (attr >= NUM_STORED_ATTRS || ptr == NULL) {
      return FAIL;
    }
    return call InternalFlash.read( (void*)storedAttributes[attr][1], 
				    ptr, storedAttributes[attr][2]);
  }

  command result_t RegistryStore.saveAll() {
    uint8_t attr;
    for (attr=0; attr < NUM_STORED_ATTRS; attr++) {
      if (call RegistryStore.save(attr) == FAIL){
	return FAIL;
      }
    }
    return SUCCESS;
  }

  command result_t RegistryStore.restoreAll() {
    uint8_t attr;
    for (attr=0; attr < NUM_STORED_ATTRS; attr++) {
      if (call RegistryStore.restore(attr) == FAIL){
	return FAIL;
      }
    }
    return SUCCESS;
  }

  event void AttrBackend.updated[AttrID_t attrID](const void* newval){
  }

   default command uint8_t AttrBackend.size[AttrID_t attrID](){return 0;}
   default command const void* AttrBackend.get[AttrID_t attrID](){return NULL;}
   default command result_t AttrBackend.set[AttrID_t attrID](const void* val){return FAIL;}
   default command result_t AttrBackend.update[AttrID_t attrID](){return FAIL;}

}

// $Id: RegistryStore.h,v 1.3 2005/08/11 23:19:10 jwhui Exp $

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
 *
 *    This file defines which Registry Attributes are stored to flash.
 *
 *    A copy of this file should be added to your platform directory
 *    because all applications on a particular platform should use the
 *    same set of RegistryStore attributes, otherwise it will not work
 *    well with multiple Deluge images using the same locations in
 *    flash.
 */


#ifdef __REGISTRY_STORE_H__
  You have more than one RegistryStore.h in your path!!
#else
#define __REGISTRY_STORE_H__

/***********
 * This variable holds maximum size of the RegistryStore
 * Do _NOT_ make this value larger or the registry store will interfere with deluge
 ***********/
enum registryStore{
  REGISTRY_STORE_SIZE = 94,
  NUM_STORED_ATTRS=2,
};


/***********
 * This variable holds the metadata for attributes stored in flash.
 * Format: {AttributeID, AddressInFlash, SizeInFlash (bytes)}
 *
 * ONLY APPEND!  Do not delete from this variable unless you want to
 * clear the entire RegistryStore before restoring anything.
 ***********/
uint8_t storedAttributes[NUM_STORED_ATTRS][3] = {
  {ATTRIBUTE_LOCATION, 0, 8},
  {ATTRIBUTE_GPSLOCATION, 8, 8},
};

#endif

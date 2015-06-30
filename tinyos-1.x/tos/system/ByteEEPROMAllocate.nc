// $Id: ByteEEPROMAllocate.nc,v 1.2 2003/10/07 21:46:36 idgay Exp $

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
includes ByteEEPROMInternal;
module ByteEEPROMAllocate {
  provides {
    interface AllocationReq[uint8_t id];
    command RegionSpecifier *getRegion(uint8_t id);
    interface StdControl;
  }
}
implementation {
  bool allocated;

  enum {
    NREGIONS = uniqueCount("ByteEEPROM")
  };

  RegionSpecifier regions[NREGIONS];
  RegionSpecifier *allocatedHead;
  
  command RegionSpecifier *getRegion(uint8_t id) {
    // Fail before allocation completes, for invalid regions, for
    // unallocated regions
    if (!allocated || id >= NREGIONS)
      return NULL;
    if (regions[id].startByte == regions[id].stopByte)
      return NULL;
    return &regions[id];
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }
  
  void addAllocatedRegion(RegionSpecifier *currentRequest,
			  RegionSpecifier **allocatedRegion) {
    currentRequest->next = *allocatedRegion;
    *allocatedRegion = currentRequest;
  }

  // Returns: value  rounded up to a multiple of alignment
  // Requires: alignment be a power of 2
  inline uint32_t alignup(uint32_t value, uint32_t alignment) {
    return (value + (alignment - 1)) & ~(alignment - 1);
  }
  
  result_t findFreeRegionAddrAndAlloc(RegionSpecifier *currentRequest) {
    RegionSpecifier **allocatedRegion = &allocatedHead;
    uint32_t startByte = 0;
    uint32_t stopByte;

    while (NULL != *allocatedRegion) {
      stopByte = (*allocatedRegion)->startByte;

      if (((currentRequest->startByte >= startByte) &&
	   (currentRequest->startByte < stopByte)) &&
	  ((currentRequest->stopByte >= startByte) &&
	   (currentRequest->stopByte <= stopByte))) {
	addAllocatedRegion(currentRequest, allocatedRegion);
	
	return SUCCESS;
      }

      startByte = alignup((*allocatedRegion)->stopByte, TOS_BYTEEEPROM_PAGESIZE);
      allocatedRegion = &(*allocatedRegion)->next;
    }
    
    stopByte = TOS_BYTEEEPROM_LASTBYTE;

    if (((currentRequest->startByte >= startByte) &&
	 (currentRequest->startByte < stopByte)) &&
	((currentRequest->stopByte >= startByte) &&
	 (currentRequest->stopByte <= stopByte))) {
      addAllocatedRegion(currentRequest, allocatedRegion);
      
      return SUCCESS;
    }

    // Mark as unallocated (for getRegion)
    currentRequest->startByte = currentRequest->stopByte = 0;
    return FAIL;
  }
  
  // currentRequest->stopByte corresponds to the number of bytes that
  // needs to be allocated
  result_t findFreeRegionAndAlloc(RegionSpecifier *currentRequest) {
    RegionSpecifier **allocatedRegion = &allocatedHead;
    uint32_t startByte = 0;
    uint32_t stopByte;
    
    while (NULL != *allocatedRegion) {
      stopByte = (*allocatedRegion)->startByte;

      if ((stopByte - startByte) >= currentRequest->stopByte) {
	currentRequest->startByte = startByte;
	currentRequest->stopByte = startByte + currentRequest->stopByte;

	addAllocatedRegion(currentRequest, allocatedRegion);

	return SUCCESS;
      }
      startByte = alignup((*allocatedRegion)->stopByte, TOS_BYTEEEPROM_PAGESIZE);
      allocatedRegion = &(*allocatedRegion)->next;
    }

    stopByte = TOS_BYTEEEPROM_LASTBYTE;

    if ((stopByte - startByte) >= currentRequest->stopByte) {
      currentRequest->startByte = startByte;
      currentRequest->stopByte = startByte + currentRequest->stopByte;

      addAllocatedRegion(currentRequest, allocatedRegion);

      return SUCCESS;
    }

    // Mark as unallocated (for getRegion)
    currentRequest->startByte = currentRequest->stopByte = 0;

    return FAIL;
  }

  command result_t StdControl.start() {
    if (!allocated)
      {
	result_t success;
	uint8_t i;
	
	//process the requests that specified an address first
	for (i = 0; i < NREGIONS; i++)
	  {
	    RegionSpecifier *region = &regions[i];

	    // We set the next field of address-based allocations to a
	    // non-null value in requestAddr...
	    if (region->next)
	      {
		success = findFreeRegionAddrAndAlloc(region);
		signal AllocationReq.requestProcessed[i](success);
	      }
	  }
      
	//process the requests that didn't specify an address
	for (i = 0; i < NREGIONS; i++)
	  {
	    RegionSpecifier *region = &regions[i];

	    // startByte for bytes-based allocations is set to a
	    // distincitive value in request
	    if (region->startByte == 0xffffffff)
	      {
		success = findFreeRegionAndAlloc(region);
		signal AllocationReq.requestProcessed[i](success);
	      }
	  }

	allocated = TRUE;
      }
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  command result_t AllocationReq.request[uint8_t id](uint32_t numBytesReq) {
    RegionSpecifier *allocate = &regions[id];

    // Fail after start or for invalid arguments
    if (allocated || numBytesReq == 0)
      return FAIL;

    allocate->startByte = 0xffffffff;
    allocate->stopByte = numBytesReq;

    return SUCCESS;
  }  

  command result_t AllocationReq.requestAddr[uint8_t id](uint32_t byteAddr,
							 uint32_t numBytesReq) {
    RegionSpecifier *allocate = &regions[id];

    // Fail after start or for invalid arguments
    if (allocated || numBytesReq == 0 || (byteAddr & (TOS_BYTEEEPROM_PAGESIZE - 1)) != 0)
      return FAIL;

    allocate->startByte = byteAddr;
    allocate->stopByte = byteAddr + numBytesReq;
    allocate->next = allocate; // Hacky way to mark request (see start)

    return SUCCESS;
  }
  
  default event result_t AllocationReq.requestProcessed[uint8_t id](result_t success) {
    return SUCCESS;
  }
}

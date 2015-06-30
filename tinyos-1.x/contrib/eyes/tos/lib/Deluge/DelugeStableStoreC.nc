// $Id: DelugeStableStoreC.nc,v 1.2 2005/01/25 18:08:53 klueska Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * Provides stable storage services to Deluge.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

includes DelugeStableStore;

includes crc;
//includes InternalFlash;
includes PageEEPROM;

configuration DelugeStableStoreC {
  provides {
    interface StdControl;
    interface DelugeMetadataStableStore;
    interface DelugeImgStableStore[uint8_t id];
  }
}
implementation {
  components
    ByteEEPROMAllocate,
    DelugeStableStoreM as StableStore,
    PageEEPROMC as Flash;
    
#if defined(PLATFORM_EYESIFX)
  components DelugeMetadataStableStoreC;
#endif    
    
#ifndef PLATFORM_PC
  components InternalFlashC;
  StableStore.IFlash -> InternalFlashC;
#endif    
    
  StdControl = StableStore;

  StableStore.SubControl -> ByteEEPROMAllocate;
  StableStore.SubControl -> Flash;

#if defined(PLATFORM_EYESIFX)
  DelugeMetadataStableStore = DelugeMetadataStableStoreC.MetadataStableStore;
#else
  DelugeMetadataStableStore = StableStore;  
#endif  
  DelugeImgStableStore = StableStore;

  StableStore.AllocationReq -> ByteEEPROMAllocate.AllocationReq[unique("ByteEEPROM")];
  StableStore.Flash -> Flash.PageEEPROM[unique("PageEEPROM")];
}

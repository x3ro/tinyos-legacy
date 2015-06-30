// $Id: BlockStorageC.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $

/*									tab:4
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
 */

/**
 * Implementation of the block storage abstraction from TEP103 for the
 * ST M25P serial code flash.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#include "BlockStorage.h"

configuration BlockStorageC {
  provides {
    interface Mount[blockstorage_t blockId];
    interface BlockRead[blockstorage_t blockId];
    interface BlockWrite[blockstorage_t blockId];
    interface StorageRemap[blockstorage_t blockId];
  }
}

implementation {

  components MainBlockStorageC;
  components BlockStorageM, StorageManagerC, LedsC as Leds;
  components new STM25PResourceC() as CmdReadCrcC;

  Mount = BlockStorageM.Mount;
  BlockRead = BlockStorageM.BlockRead;
  BlockWrite = BlockStorageM.BlockWrite;
  StorageRemap = StorageManagerC.StorageRemap;

  BlockStorageM.SectorStorage -> StorageManagerC.SectorStorage;
  BlockStorageM.ActualMount -> StorageManagerC.Mount;
  BlockStorageM.StorageManager -> StorageManagerC.StorageManager;
  BlockStorageM.Leds -> Leds;
  BlockStorageM.CmdReadCrc -> CmdReadCrcC;

}

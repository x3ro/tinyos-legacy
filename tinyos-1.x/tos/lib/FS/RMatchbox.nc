// $Id: RMatchbox.nc,v 1.2 2003/10/07 21:46:18 idgay Exp $

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
 * File system component.
 * Busy rules:
 *   The following operations cannot be in progress simultaneously:
 *      FileDir.start through the last FileDir.nextFile
 *      FileRename.rename through FileRename.renamed
 *      FileDelete.delete through FileDelete.deleted
 *      FileRead.open through FileRead.opened
 *      FileWrite.open through FileWrite.opened
 *   Also, as stated by the FileRead and FileWrite interfaces, there are at
 *   most two files open at any time (one for reading and one for writing)
 */

includes IFS;
configuration RMatchbox {
  provides {
    interface StdControl;
    interface FileDir;
    interface FileRead[uint8_t fd];
  }
  uses {
    interface Debug;
    event result_t ready();
  }
}
implementation {
  // FileXXX implementations
  components Read, Dir;

  // Internal services
  components Coordinator, MetaData, Reader, RFreeList as FreeList;

  // Low-level internal components
  components LocateRoot, ScanFS, Blocks;

  // System components
  components PageEEPROMC;

  // Forward provided interfaces to their implementation components
  FileDir = Dir;
  FileRead = Read;

  // initialisation wiring
  StdControl = Coordinator;
  StdControl = MetaData;
  StdControl = Read;
  StdControl = PageEEPROMC;
  MetaData.IFileCoord -> Coordinator;
  MetaData.FreeListControl -> FreeList;

  // Dir wiring
  Dir.IFileCoord -> Coordinator;
  Dir.IFileMetaRead -> MetaData.IFileMetaRead[unique("IFileMetaRead")];
  Dir.IFileFree -> FreeList;

  // Read wiring
  Read.IFileCoord -> Coordinator;
  Read.IFileMetaRead -> MetaData.IFileMetaRead[unique("IFileMetaRead")];
  Read.IFileRead -> Reader.IFileRead;

  // MetaData wiring
  MetaData.IFileFree -> FreeList;
  MetaData.MetaDataReader -> Reader.IFileRead[IFS_RFD_META];
  //MetaData.MetaDataWriter -> Writer.IFileWrite[IFS_WFD_META];
  MetaData.IFileRoot -> LocateRoot;
  MetaData.IFileScan -> ScanFS;
  MetaData.IFileBlockMeta -> Blocks.IFileBlockMeta[unique("IFileBlockMeta")];
  MetaData.ready = ready;

  // Reader wiring
  Reader.IFileBlock -> Blocks.IFileBlock[unique("IFileBlock")];
  Reader.IFileBlockMeta -> Blocks.IFileBlockMeta[unique("IFileBlockMeta")];
  Reader.RemainingMeta -> Blocks.IFileBlockMeta[unique("IFileBlockMeta")];

  // LocateRoot wiring
  LocateRoot.IFileBlock -> Blocks.IFileBlock[unique("IFileBlock")];
  LocateRoot.ReadRoot -> Blocks.IFileBlock[unique("IFileBlock")];
  LocateRoot.CheckRoot -> Blocks.IFileBlockMeta[unique("IFileBlockMeta")];

  // ScanFS wiring
  ScanFS.IFileMetaRead -> MetaData.IFileMetaRead[unique("IFileMetaRead")];
  ScanFS.IFileBlockMeta -> Blocks.IFileBlockMeta[unique("IFileBlockMeta")];
  ScanFS.IFileFree -> FreeList;
  ScanFS.newBlockRead <- Reader.newBlock;

  // Blocks wiring
  Blocks.PageEEPROM -> PageEEPROMC;

  // open file coordination
  Read.IFileCheck -> Coordinator;
  Coordinator.ReadCheck -> Read.ReadCheck;
  //Coordinator.WriteCheck -> Write.WriteCheck;

  // debug
  Read.Debug = Debug;
  Dir.Debug = Debug;
  Coordinator.Debug = Debug;
  MetaData.Debug = Debug;
  Reader.Debug = Debug;
  FreeList.Debug = Debug;
  LocateRoot.Debug = Debug;
  ScanFS.Debug = Debug;
  Blocks.Debug = Debug;
  PageEEPROMC.Debug = Debug;
}

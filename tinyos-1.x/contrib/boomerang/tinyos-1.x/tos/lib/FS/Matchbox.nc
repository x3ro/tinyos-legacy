// $Id: Matchbox.nc,v 1.1.1.1 2007/11/05 19:09:13 jpolastre Exp $

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
configuration Matchbox {
  provides {
    interface StdControl;
    interface FileDelete;
    interface FileDir;
    interface FileRead[uint8_t fd];
    interface FileRename;
    interface FileWrite[uint8_t fd];
  }
  uses {
    interface Debug;

    /**
     * Signaled when the filing system is ready to accept operations.
     * @return Ignored.
     */
    event result_t ready();
  }
}
implementation {
  // FileXXX implementations
  components Read, Write, Dir, Rename, Delete;

  // Internal services
  components Coordinator, MetaData, Reader, Writer, FreeList;

  // Low-level internal components
  components LocateRoot, ScanFS, Blocks;

  // System components
  components PageEEPROMC, ByteEEPROMAllocate;


  // Forward provided interfaces to their implementation components
  FileDelete = Delete;
  FileDir = Dir;
  FileRead = Read;
  FileRename = Rename;
  FileWrite = Write;

  // initialisation wiring
  StdControl = Coordinator;
  StdControl = MetaData;
  StdControl = Writer;
  StdControl = Read;
  StdControl = ByteEEPROMAllocate;
  StdControl = PageEEPROMC;
  MetaData.AllocationReq -> ByteEEPROMAllocate.AllocationReq[unique("ByteEEPROM")];
  MetaData.IFileCoord -> Coordinator;
  MetaData.FreeListControl -> FreeList;

  // Delete wiring
  Delete.IFileCoord -> Coordinator;
  Delete.IFileMetaRead -> MetaData.IFileMetaRead[unique("IFileMetaRead")];
  Delete.IFileMetaWrite -> MetaData.IFileMetaWrite[unique("IFileMetaWrite")];

  // Dir wiring
  Dir.IFileCoord -> Coordinator;
  Dir.IFileMetaRead -> MetaData.IFileMetaRead[unique("IFileMetaRead")];
  Dir.IFileFree -> FreeList;

  // Read wiring
  Read.IFileCoord -> Coordinator;
  Read.IFileMetaRead -> MetaData.IFileMetaRead[unique("IFileMetaRead")];
  Read.IFileRead -> Reader.IFileRead;

  // Rename wiring
  Rename.IFileCoord -> Coordinator;
  Rename.IFileMetaRead -> MetaData.IFileMetaRead[unique("IFileMetaRead")];
  Rename.IFileMetaWrite -> MetaData.IFileMetaWrite[unique("IFileMetaWrite")];

  // Write wiring
  Write.IFileCoord -> Coordinator;
  Write.IFileMetaRead -> MetaData.IFileMetaRead[unique("IFileMetaRead")];
  Write.IFileMetaWrite -> MetaData.IFileMetaWrite[unique("IFileMetaWrite")];
  Write.IFileWrite -> Writer.IFileWrite;
  Write.IFileWrite2 -> Writer.IFileWrite2;
  Write.IFileFree -> FreeList;


  // MetaData wiring
  MetaData.IFileFree -> FreeList;
  MetaData.MetaDataReader -> Reader.IFileRead[IFS_RFD_META];
  MetaData.MetaDataWriter -> Writer.IFileWrite[IFS_WFD_META];
  MetaData.IFileRoot -> LocateRoot;
  MetaData.IFileScan -> ScanFS;
  MetaData.IFileBlockMeta -> Blocks.IFileBlockMeta[unique("IFileBlockMeta")];
  MetaData.ready = ready;

  // Reader wiring
  Reader.IFileBlock -> Blocks.IFileBlock[unique("IFileBlock")];
  Reader.IFileBlockMeta -> Blocks.IFileBlockMeta[unique("IFileBlockMeta")];
  Reader.RemainingMeta -> Blocks.IFileBlockMeta[unique("IFileBlockMeta")];

  // Writer wiring
  Writer.IFileBlock -> Blocks.IFileBlock[unique("IFileBlock")];
  Writer.IFileBlockErase -> Blocks.IFileBlockErase[unique("IFileBlockErase")];
  Writer.IFileBlockMeta -> Blocks.IFileBlockMeta[unique("IFileBlockMeta")];
  Writer.IFileFree -> FreeList;

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
  Blocks.PageEEPROM -> PageEEPROMC.PageEEPROM[unique("PageEEPROM")];

  // open file coordination
  Delete.IFileCheck -> Coordinator;
  Rename.IFileCheck -> Coordinator;
  Read.IFileCheck -> Coordinator;
  Write.IFileCheck -> Coordinator;
  Coordinator.ReadCheck -> Read.ReadCheck;
  Coordinator.WriteCheck -> Write.WriteCheck;

  // debug
  Read.Debug = Debug;
  Write.Debug = Debug;
  Dir.Debug = Debug;
  Rename.Debug = Debug;
  Delete.Debug = Debug;
  Coordinator.Debug = Debug;
  MetaData.Debug = Debug;
  Reader.Debug = Debug;
  Writer.Debug = Debug;
  FreeList.Debug = Debug;
  LocateRoot.Debug = Debug;
  ScanFS.Debug = Debug;
  Blocks.Debug = Debug;
}

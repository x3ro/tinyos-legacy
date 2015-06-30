includes IFS;
module MetaData {
  provides {
    interface StdControl;
    interface IFileMetaRead[uint8_t clientId];
    interface IFileMetaWrite[uint8_t clientId];
  }
  uses {
    interface IFileCoord;
    interface IFileFree;
    interface IFileRead as MetaDataReader;
    interface IFileWrite as MetaDataWriter;
    interface IFileRoot;
    interface IFileScan;
    interface StdControl as FreeListControl;
    interface IFileBlockMeta;
    event result_t ready();
  }
#include "massert.h"
}
implementation {
  uint8_t rclient, wclient;
  fileblock_t root, nFiles;
  filemeta_t metadataVersion;

  task void boot() {
    call IFileRoot.locateRoot();
  }

  command result_t StdControl.init() {
    call FreeListControl.init();
    post boot();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  default event result_t ready() {
    return SUCCESS;
  }

  void reserveMeta() {
    fileblock_t n;
    // Reserve free space for a copy of this directory to ensure that
    // we can always delete files on a full disk
    n = ((uint32_t)nFiles * sizeof(struct fileEntry) + sizeof metadataVersion + IFS_PAGE_SIZE - 1) >> IFS_LOG2_PAGE_SIZE;
    call IFileFree.setReserved(n);
  }
  
  void signalready() {
    reserveMeta();
    signal ready();
  }

  event void IFileRoot.emptyMatchbox() {
    /* Format.
       We don't actually write anything, we just:
       - leave all blocks as free, set free pointer to block 0
       - set nFiles to 0
         (this value is special-cased in IFileMetaRead.read)
    */
    root = IFS_EOF_BLOCK;
    nFiles = 0;
    metadataVersion = 0x4249;
    call IFileFree.setFreePtr(0);
    call IFileCoord.unlock();
    call Debug.dbg8(0xf0);
    signalready();
  }

  event void IFileRoot.possibleRoot(fileblock_t possibleRoot,
				    filemeta_t possibleVersion) {
    root = possibleRoot;
    metadataVersion = possibleVersion;
  }

  event filemeta_t IFileRoot.currentVersion() {
    return metadataVersion;
  }

  event void IFileRoot.located() {
    call IFileScan.scanFS(root);
  }

  event void IFileScan.anotherFile() {
    nFiles++;
  }

  event void IFileScan.scanned(fileresult_t result) {
    if (result == FS_OK)
      {
	call Debug.dbg8(0xf1);
	call Debug.dbg16(root);
	call Debug.dbg16(nFiles);
      }
    else
      {
	/* Bad file system. Lose all files. */
	call Debug.dbg8(0xf2);
	call IFileFree.freeall();
	root = IFS_EOF_BLOCK;
	nFiles = 0;
      }
    call IFileCoord.unlock();
    signalready();
  }

  struct fileEntry readFile;

  task void noFiles() {
    signal IFileMetaRead.nextFile[rclient](&readFile, FS_NO_MORE_FILES);
  }

  command void IFileMetaRead.readNext[uint8_t id]() {
    assert(id == rclient);
    if (root == IFS_EOF_BLOCK) // No root...
      post noFiles();
    else
      call MetaDataReader.read(&readFile, sizeof readFile);
  }

  event void MetaDataReader.readDone(filesize_t nRead, fileresult_t result) {
    if (result == FS_OK && nRead == 0)
      result = FS_NO_MORE_FILES;
    else
      assert(nRead == sizeof readFile);

    signal IFileMetaRead.nextFile[rclient](&readFile, result);
  }

  command void IFileMetaRead.read[uint8_t id]() {
    rclient = id;
    call MetaDataReader.open(root, sizeof metadataVersion, TRUE);
  }

  struct fileEntry writeFile;
  fileblock_t writeCounter;
  fileresult_t writeOk;

  void deleteBlocks(uint8_t meta, fileblock_t freedBlock) {
    writeCounter = meta; // hack
    signal IFileBlockMeta.readDone(freedBlock, 0, FS_OK);
  }

  void wready() {
    signal IFileMetaWrite.writeReady[wclient]();
  }

  task void wreadyTask() {
    wready();
  }

  command void IFileMetaWrite.write[uint8_t id]() {
    wclient = id;
    writeCounter = 0;
    call IFileFree.setReserved(0);
    call MetaDataWriter.new(TRUE);
  }

  event void MetaDataWriter.newDone(fileresult_t result) {
    writeOk = result;
    if (result == FS_OK)
      {
	metadataVersion++;
	call MetaDataWriter.write(&metadataVersion, sizeof metadataVersion);
      }
    else
      {
	// Close file so it's clear that we didn't use any blocks
	call MetaDataWriter.close();
	wready();
      }
  }

  command void IFileMetaWrite.writeFile[uint8_t id](const char *filename,
						   fileblock_t firstBlock) {
    assert(id == wclient);

    if (writeOk == FS_OK)
      {
	memcpy(writeFile.name, filename, sizeof writeFile.name);
	writeFile.firstBlock = firstBlock;
	call MetaDataWriter.write(&writeFile, sizeof writeFile);
	writeCounter++;
      }
    else
      post wreadyTask();
  }

  event void MetaDataWriter.writeDone(filesize_t nWritten, fileresult_t result) {
    writeOk = result;
    wready();
  }

  task void wcompleteTask() {
    reserveMeta();
    signal IFileMetaWrite.writeCompleted[wclient](writeOk);
  }

  command void IFileMetaWrite.writeComplete[uint8_t id](fileresult_t callerResult) {
    assert(wclient == id);

    // Caller's error takes priority
    writeOk = frcombine(callerResult, writeOk);

    if (writeOk == FS_OK)
      call MetaDataWriter.metaSync();
    else
      deleteBlocks(1, call MetaDataWriter.firstBlock());
  }

  event void MetaDataWriter.syncDone(fileresult_t result) {
    writeOk = result;

    /* Commit changes to local state */
    if (result == FS_OK)
      {
	deleteBlocks(1, root);
	root = call MetaDataWriter.firstBlock();
	nFiles = writeCounter;

	call Debug.dbg8(0xf3);
	call Debug.dbg16(root);
	call Debug.dbg16(nFiles);
      }
    else
      {
	call Debug.dbg8(0xf4);
	metadataVersion--;
	deleteBlocks(1, call MetaDataWriter.firstBlock());
      }
  }

 void blocksDeleted(fileresult_t result) {
   if (writeCounter)
     post wcompleteTask();
   else
     signal IFileMetaWrite.blocksDeleted[wclient](result);
  }

  event void IFileBlockMeta.readDone(fileblock_t nextBlock,
				     fileblockoffset_t lastByte,
				     fileresult_t result) {
    if (result != FS_OK || nextBlock == IFS_EOF_BLOCK)
      blocksDeleted(result);
    else
      {
	call IFileFree.free(nextBlock);
	call IFileBlockMeta.read(nextBlock, FALSE);
      }
  }

  command void IFileMetaWrite.deleteBlocks[uint8_t id](fileblock_t firstBlock) {
    wclient = id;
    deleteBlocks(0, firstBlock);
  }

  default event void IFileMetaWrite.blocksDeleted[uint8_t id](fileresult_t result) {
    assert(0);
  }
  default event void IFileMetaRead.nextFile[uint8_t id](struct fileEntry *file, fileresult_t result) {
    assert(0);
  }
  default event void IFileMetaWrite.writeReady[uint8_t id]() {
    assert(0);
  }
  default event void IFileMetaWrite.writeCompleted[uint8_t id](fileresult_t result) {
    assert(0);
  }
  event void IFileBlockMeta.writeDone(fileresult_t result) { 
    assert(0);
  }
  event void MetaDataReader.remaining(filesize_t n, fileresult_t result) {
    assert(0);
  }
}

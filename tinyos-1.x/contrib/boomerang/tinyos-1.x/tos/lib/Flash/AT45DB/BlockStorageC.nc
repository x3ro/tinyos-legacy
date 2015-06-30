// $Id: BlockStorageC.nc,v 1.1.1.1 2007/11/05 19:09:11 jpolastre Exp $
includes Storage;
#define HALAT45DB PageEEPROM
includes BlockStorage;

configuration BlockStorageC {
  provides {
    interface Mount[blockstorage_t blockId];
    interface BlockRead[blockstorage_t blockId];
    interface BlockWrite[blockstorage_t blockId];
    interface StorageRemap[blockstorage_t blockId];
  }
}
implementation {
  components BlockStorageM, StorageManagerC, Main;

  Mount = BlockStorageM.Mount;
  BlockWrite = BlockStorageM.BlockWrite;
  BlockRead = BlockStorageM.BlockRead;
  StorageRemap = StorageManagerC.StorageRemap;
  
  Main.StdControl -> StorageManagerC;
  BlockStorageM.HALAT45DB -> StorageManagerC.HALAT45DB;
  BlockStorageM.ActualMount -> StorageManagerC.Mount;
  BlockStorageM.AT45Remap -> StorageManagerC;
}

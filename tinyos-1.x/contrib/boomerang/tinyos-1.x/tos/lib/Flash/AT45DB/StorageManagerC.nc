includes Storage;
#define HALAT45DB PageEEPROM
includes BlockStorage;

configuration StorageManagerC {
  provides {
    interface StdControl;
    interface Mount[volume_t volume];
    interface HALAT45DB[volume_t volume];
    interface StorageRemap[volume_t volume];
    interface AT45Remap;
  }
}
implementation {
  components StorageManagerM, PageEEPROMC as HALAT45DBC, HALAT45DBShare, InternalFlashC;

  StdControl = StorageManagerM;
  StdControl = HALAT45DBC;
  Mount = StorageManagerM;
  HALAT45DB = HALAT45DBShare;
  AT45Remap = StorageManagerM;
  StorageRemap = StorageManagerM;

  StorageManagerM.HALAT45DB -> HALAT45DBShare.HALAT45DB[uniqueCount("StorageManager")];

  HALAT45DBShare.ActualAT45 -> HALAT45DBC.PageEEPROM[unique("PageEEPROM")];
  HALAT45DBShare.AT45Remap -> StorageManagerM;
}

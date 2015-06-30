includes crc;
includes StorageManager;
#define HALAT45DB PageEEPROM
module StorageManagerM {
  provides {
    interface StdControl;
    interface Mount[volume_t volume];
    interface StorageRemap[volume_t volume];
    interface AT45Remap;
  }
  uses interface HALAT45DB;
}
implementation {
  enum {
    NVOLUMES = uniqueCount("StorageManager")
  };

  struct volume_definition_header_t header;
  struct volume_definition_t volumes[NVOLUMES];

  enum {
    S_READY,
    S_MOUNTING
  };
  struct {
    bool validated : 1;
    bool invalid : 1;
    bool busy : 1;
    uint8_t state : 2;
  } f;

  uint8_t nextVolume;
  volume_t client;
  volume_id_t id;

  command result_t StdControl.init() {
    uint8_t i;

    for (i = 0; i < NVOLUMES; i++)
      volumes[i].id = INVALID_VOLUME_ID;

    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  void mountComplete(storage_result_t r) {
    f.busy = FALSE;
    signal Mount.mountDone[client](r, id);
  }

  void check(result_t r) {
    if (r == FAIL)
      mountComplete(STORAGE_FAIL);
  }

  void checkNextVolume() {
    if (f.invalid || nextVolume == header.nvolumes)
      {
	volumes[client].id = INVALID_VOLUME_ID;
	mountComplete(STORAGE_FAIL);
      }
    else
      check(call HALAT45DB.read(VOLUME_TABLE_PAGE, sizeof(struct volume_definition_header_t) +
				nextVolume++ * sizeof(struct volume_definition_t),
				&volumes[client], sizeof volumes[client]));
  }

  task void mountVolume() {
    if (!f.validated)
      check(call HALAT45DB.read(VOLUME_TABLE_PAGE, 0, &header, sizeof header));
    else
      checkNextVolume();
  }

  command result_t Mount.mount[volume_t v](volume_id_t i) {
    if (f.busy || volumes[v].id != INVALID_VOLUME_ID)
      return FAIL;

    f.busy = TRUE;
    client = v;
    id = i;
    nextVolume = 0;
    post mountVolume();

    return SUCCESS;
  }

  command uint32_t StorageRemap.physicalAddr[volume_t v](uint32_t volumeAddr) {
    return ((uint32_t)volumes[v].start << AT45_PAGE_SIZE_LOG2) + volumeAddr;
  }

  command at45page_t AT45Remap.remap(volume_t volume, at45page_t volumePage) {
    if (volume == NVOLUMES) // special internal-use case
      return volumePage;
    else
      return volumePage + volumes[volume].start;
  }

  command storage_addr_t AT45Remap.volumeSize(volume_t volume) {
    return (storage_addr_t)volumes[volume].length << AT45_PAGE_SIZE_LOG2;
  }

  event result_t HALAT45DB.writeDone(result_t result) {
    return SUCCESS;
  }

  event result_t HALAT45DB.eraseDone(result_t result) {
    return SUCCESS;
  }

  event result_t HALAT45DB.syncDone(result_t result) {
    return SUCCESS;
  }

  event result_t HALAT45DB.flushDone(result_t result) {
    return SUCCESS;
  }

  event result_t HALAT45DB.readDone(result_t result) {
    if (!f.validated)
      {
	size_t nvOffset = offsetof(struct volume_definition_header_t, nvolumes);
	size_t n = header.nvolumes * sizeof *volumes +
	  sizeof(struct volume_definition_header_t) - nvOffset;

	check(call HALAT45DB.computeCrc(VOLUME_TABLE_PAGE, nvOffset, n));
      }
    else
      {
	if (volumes[client].id == id)
	  mountComplete(STORAGE_OK);
	else
	  checkNextVolume();
      }
    return SUCCESS;
  }

  event result_t HALAT45DB.computeCrcDone(result_t result, uint16_t crc) {
    f.validated = TRUE;
    f.invalid = crc != header.crc;
    checkNextVolume();
    return SUCCESS;
  }
}

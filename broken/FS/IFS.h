#include "PageEEPROM.h"
#include "Matchbox.h"

// internal constants, types for filing system
enum {
  IFS_PAGE_SIZE = 256,
  IFS_LOG2_PAGE_SIZE = 8,
  IFS_FULL_PAGE_SIZE = 264,

  IFS_NUM_PAGES = 1536
};

typedef eeprompage_t fileblock_t;
typedef eeprompageoffset_t fileblockoffset_t; /* 0 to IFS_PAGE_SIZE */
typedef uint8_t fileblockfoo_t; /* 0 to IFS_PAGE_SIZE - 1 */
typedef uint32_t filemeta_t;	/* Metadata version number */

struct fileEntry {
  char name[14];
  fileblock_t firstBlock;
};

enum {
  IFS_OFFSET_METADATA = 258,
  IFS_EOF_BLOCK = IFS_NUM_PAGES + 42,
  IFS_ROOT_MARKER = 4,
  IFS_ROOT_MARKER_BITS = 3
};

enum {
  IFS_RFD_META = unique("FileRead"),
  IFS_WFD_META = unique("FileWrite")
};

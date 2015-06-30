#ifndef MATCHBOX_H
#define MATCHBOX_H

// user constants, types for filing system
typedef uint32_t filesize_t;

// Number of files for read and write
enum {
  FS_NUM_RFDS = 3,
  FS_NUM_WFDS = 3
};

enum {
  FS_OK,
  FS_NO_MORE_FILES,
  FS_ERROR_NOSPACE,
  FS_ERROR_BAD_DATA,
  FS_ERROR_FILE_OPEN,
  FS_ERROR_NOT_FOUND,
  FS_ERROR_HW
};

enum {
  FS_FTRUNCATE = 1,
  FS_FCREATE = 2
};

typedef uint8_t fileresult_t;

fileresult_t frcombine(fileresult_t r1, fileresult_t r2)
/* Returns: FAIL if r1 or r2 == FAIL , r2 otherwise. This is the standard
     combining rule for fileresults
*/
{
  return r1 != FS_OK ? r1 : r2;
}

enum {
  FS_CRC_FILES = FALSE
};

#endif

#ifndef SIZES_H
#define SIZES_H

/*
 * Debug messages
 */

//#define INDEX_DEBUG
//#define ARRAY_DEBUG
//#define CHUNK_DEBUG
//#define QUEUE_DEBUG
//#define STACK_DEBUG
//#define STREAM_DEBUG
//#define STREAM_INDEX_DEBUG
//#define CHECKPOINT_DEBUG
//#define ROOT_DIR_DEBUG
//#define FS_DEBUG
//#define FLASH_DEBUG
//#define FILE_DEBUG
//#define COMPACT_DEBUG
//#define DEBUG

#define COUNT 10
/* Length of the data (compaction expt) */
#define LEN 80


/*
 * This indicates the number of elements in level 1 of the index
 */
#define ARRAY_ELEMENTS_PER_CHUNK 5

/*
 * This indicates the number of index elements in level 2 of the index
 */
#define INDEX_ELEMENTS_PER_CHUNK 5

/*
 * This indicates the number of checkpoints in use in the system
 */
#define NUM_CHECKPOINTS 1

/*
 * This indicates the size of the file buffers used by FileM.nc
 */
#define FILE_READ_BUFF 80
#define FILE_WRITE_BUFF 80

#endif

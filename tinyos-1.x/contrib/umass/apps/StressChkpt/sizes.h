#ifndef SIZES_H
#define SIZES_H

/*
 * Debug messages
 */

#define FLASH_DEBUG
//#define INDEX_DEBUG
//#define ARRAY_DEBUG
#define CHUNK_DEBUG
//#define QUEUE_DEBUG
//#define STACK_DEBUG
//#define STREAM_DEBUG
//#define STREAM_INDEX_DEBUG
//#define CHECKPOINT_DEBUG
//#define ROOT_DIR_DEBUG
//#define COMPACT_DEBUG
#define COUNT 20
/* Length of the data (compaction expt) */
#define LEN 20


//#define NUM_CHECKPOINTS 1 

/*
 * This indicates the number of elements in level 1 of the index
 */
#define ARRAY_ELEMENTS_PER_CHUNK 10

/*
 * This indicates the number of index elements in level 2 of the index
 */
#define INDEX_ELEMENTS_PER_CHUNK 10




#endif

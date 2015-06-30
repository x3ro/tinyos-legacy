/*
 * file:        common_header.h
 * description: common headers
 */

/*
 * Common declarations
 */

#ifndef COMMON_HEADER_H
#define COMMON_HEADER_H

#include "platform.h"

struct flashptr_t
{
	pageptr_t page;
	offsetptr_t offset;
};

typedef struct flashptr_t flashptr_t;

typedef uint8_t fileptr_t;

/*
 * The following is just a temp buffer that is used to read the headers
 * - it should be >= size of the chunk header + the max {app_headers}
 */
#define MAX_HEADERS_LEN 10

/*
 * The following is just a temp buffer used to hold the memory state of 
 * each storage object for checkpointing / restore purposes. Needs to be
 * set manually unfortunately because we dont know how much state each
 * storage object needs.
 */
#define MAX_STATE 200

/*
 * The following defines the max number of files that can be supported
 * by Capsule
 */
#define MAX_FILES 8

/*
 * The following defines the max size of the filename (in bytes)
 */
#define MAX_FILENAME 16


/*
 * The following defines the number of instances of each of these storage 
 * objects being used in the application.
 * The values for these are set automatically by the compiler
 */
#define NUM_ARRAYS uniqueCount("Array")

#define NUM_QUEUES uniqueCount("Queue")

#define NUM_INDEXES uniqueCount("Index")

#define NUM_STACKS uniqueCount("Stack")

#define NUM_STREAMS uniqueCount("Stream")

#define NUM_CHECKPOINTS uniqueCount("Checkpoint")

#define NUM_STREAM_INDEXES uniqueCount("StreamIndex")

#endif

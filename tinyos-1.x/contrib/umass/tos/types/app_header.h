/*
 * file:        app_header.h
 * description: Application level headers used by Capsule
 */

/*
 * Application level headers used by the different storage objects
 */

#ifndef APP_HEADER_H
#define APP_HEADER_H

#include "common_header.h"

// Stack header
struct stack_header
{
    flashptr_t prev_ptr;
};
typedef struct stack_header stack_header;


// Queue header
struct queue_header
{
    flashptr_t prev_ptr;
};
typedef struct queue_header queue_header;


// Stream header
struct stream_header
{
    flashptr_t prev_ptr;
};
typedef struct stream_header stream_header;


// Array header
//
struct array_header
{
    flashptr_t ptr[ARRAY_ELEMENTS_PER_CHUNK];
};
typedef struct array_header array_header;


// Index header
//
struct index_header
{
    flashptr_t ptr[INDEX_ELEMENTS_PER_CHUNK];
};
typedef struct index_header index_header;


// Transaction data header
// - Stores memory state for various storage objects
//
struct checkpoint_header
{
    uint8_t state_buffer[MAX_STATE];
};
typedef struct checkpoint_header checkpoint_header;


// File
//
struct file_header
{
    bool invalid;
    char name[MAX_FILENAME];
    uint16_t length;
    flashptr_t start_ptr;
    uint8_t last_index;
};
typedef struct file_header file_header;


// Filesystem data header
//
struct filesystem
{
    file_header data[MAX_FILES];
};
typedef struct filesystem filesystem;


// Root data header
// - This data is stored in the root area of the flash
//
struct root_header
{
    uint8_t crc;
    uint16_t timestamp;
    flashptr_t root[NUM_CHECKPOINTS];
};
typedef struct root_header root_header;


bool cmpflashptr(flashptr_t *ptr1, flashptr_t *ptr2)
{
    if ( (ptr1->page == ptr2->page) && (ptr1->offset == ptr2->offset))
        return (TRUE);
    else
        return (FALSE);
}

#endif

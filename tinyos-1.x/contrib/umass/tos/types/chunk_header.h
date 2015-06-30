/*
 * file:        chunk_header.h
 * description: Chunk header stamped on every chunk written by FAL
 */

/*
 * Header present for every chunk on the flash
 */

#ifndef CHUNK_HEADER_H
#define CHUNK_HEADER_H

#include "common_header.h"

/*
 * The structure of one write buffer looks like:
 * -------------------------------------------------
 * | chunk 1 | chunk 2 | ... |
 * -------------------------------------------------
 */

struct chunk_header
{
    datalen_t data_len;
    uint8_t ecc;
};
typedef struct chunk_header chunk_header;

#endif

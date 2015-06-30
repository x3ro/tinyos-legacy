/*
 * file:        platform.h
 * description: Platform-specific definition
 */

/*
 * Common declarations
 */

#ifndef PLATFORM_H
#define PLATFORM_H

//#define PLATFORM_TELOSB

/*
 * NOTE : These need to be set according to flash and user configuration
 */
typedef uint16_t pageptr_t;
typedef uint16_t offsetptr_t;
typedef uint16_t datalen_t; 

/* The size of each page on the NAND flash */
#define PAGE_SIZE 256

/* The size of each page on the NAND flash */
#define ERASE_BLOCK_SIZE 256

/* XXX --------------- SET THE FOLLOWING BEFORE OPERATION ----------------- XXX
 * The following both should be calculated based on the size of a page
 * NAND_BUFFER_SIZE = NAND_PAGE_SIZE (set in common_header.h) / number of
 *                       times write is possible to a page
 */
#define BUFFER_SIZE 256

/*
 * The allocated root directory area in units of erase blocks
 * 1 erase block = NAND_ERASE_BLOCK_SIZE pages
 */
#define ROOT_DIRECTORY_AREA 10

#define DELUGE_AREA 0

#endif

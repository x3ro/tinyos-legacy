/*
 * file:        platform.h
 * description: A platform-specific file
 */

/*
 * Common declarations
 */

#ifndef PLATFORM_H
#define PLATFORM_H

#define PLATFORM_MICA2_NOR

#ifndef PLATFORM_MICA2_NOR

/************ NAND board ***************/
#define PLATFORM_MICA2_NAND

/*
 * NOTE : These need to be set according to flash and user configuration
 */
typedef uint16_t pageptr_t;
typedef unsigned int offsetptr_t;
typedef uint16_t datalen_t; 

/* The size of each page on the NAND flash */
#define PAGE_SIZE 512

/* The size of each page on the NAND flash */
#define ERASE_BLOCK_SIZE 32

/* XXX --------------- SET THE FOLLOWING BEFORE OPERATION ----------------- XXX
 * The following both should be calculated based on the size of a page
 * NAND_BUFFER_SIZE = NAND_PAGE_SIZE (set in common_header.h) / number of
 *                       times write is possible to a page
 */
#define BUFFER_SIZE 512

#else

/************ Mica2 NOR ***************/

/*
 *  * NOTE : These need to be set according to flash and user configuration
 *   */
typedef uint16_t pageptr_t;
typedef uint16_t offsetptr_t;
typedef uint16_t datalen_t; 

/* The size of each page on the flash */
#define PAGE_SIZE 256

#define ERASE_BLOCK_SIZE 1

/* XXX --------------- SET THE FOLLOWING BEFORE OPERATION ----------------- XXX
 *  * The following both should be calculated based on the size of a page
 *   * NAND_BUFFER_SIZE = NAND_PAGE_SIZE (set in common_header.h) / number of
 *    *                       times write is possible to a page
 *     */
#define BUFFER_SIZE 256

#endif

/*
 * The allocated root directory area in units of erase blocks
 * 1 erase block = NAND_ERASE_BLOCK_SIZE pages
 */
#define ROOT_DIRECTORY_AREA 2

#define DELUGE_AREA 2

#endif

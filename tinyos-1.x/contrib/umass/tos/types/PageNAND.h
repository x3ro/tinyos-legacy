/*
 * file:        PageNAND.h
 * description:
 */

#ifndef TOS_PAGENAND_H
#define TOS_PAGENAND_H

enum {
    TOS_NAND_PAGE_SIZE = 512,
    TOS_NAND_EXTRA_SIZE = 16,
    TOS_NAND_ERASE_SIZE = 32 /* number of pages in an erase block */
};

typedef uint32_t nandpage_t;
typedef uint16_t nandoffset_t;

#endif

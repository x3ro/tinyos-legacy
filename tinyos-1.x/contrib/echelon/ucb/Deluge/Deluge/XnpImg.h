
/**
 * XnpImg.h - Reads and writes srec data in Xnp compatible format.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

#ifndef __XNP_IMG_H__
#define __XNP_IMG_H__

#define FLASH_BYTES_PER_LINE     ((uint32_t)16)
#define FLASH_LINES_PER_PAGE     ((uint32_t)16)
#define XNP_IMG_START_PAGE       ((uint32_t)1)
#define XNP_BYTES_PER_LINE       ((uint32_t)16)
#define FLASH_LINES_PER_XNP_LINE ((uint32_t)2)
#define XNP_DATA_LINE_OFFSET     ((uint32_t)8)

#define FLASH_BYTES_PER_XNP_LINE (FLASH_LINES_PER_XNP_LINE*FLASH_BYTES_PER_LINE)
#define XNP_LINES_PER_PAGE       (FLASH_LINES_PER_PAGE/FLASH_LINES_PER_XNP_LINE)
#define XNP_BYTES_PER_PAGE       (XNP_LINES_PER_PAGE*XNP_BYTES_PER_LINE)

// returns: 0 <= x < FLASH_LINES_PER_PAGE
#define OFFSET_TO_FLASH_LINE(x)        ((((x)%XNP_BYTES_PER_PAGE)/XNP_BYTES_PER_LINE)*FLASH_LINES_PER_XNP_LINE)
// returns: 0 <= x < FLASH_BYTES_PER_LINE
#define OFFSET_TO_FLASH_LINE_OFFSET(x) (((x)%XNP_BYTES_PER_LINE)+XNP_DATA_LINE_OFFSET)

#define OFFSET_TO_FLASH_PAGE(x)   (XNP_IMG_START_PAGE + ((x)/XNP_BYTES_PER_PAGE))
#define OFFSET_TO_FLASH_OFFSET(x) ((OFFSET_TO_FLASH_LINE(x)*FLASH_BYTES_PER_LINE)+OFFSET_TO_FLASH_LINE_OFFSET(x))

#define XNP_HEADER_SIZE 8

typedef struct xnpSrecLine_t {
  uint16_t pid;
  uint16_t cid;
  uint8_t  type;
  uint8_t  length;
  uint16_t addr;
  uint8_t  data[16];
  uint16_t checksum;
} xnpSrecLine_t;

#endif

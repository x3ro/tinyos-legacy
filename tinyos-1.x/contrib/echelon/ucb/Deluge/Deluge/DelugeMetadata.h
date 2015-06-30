
/**
 * DelugeMetadata.h - Manages metadata.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

#ifndef __DELUGEIMGMETADATA_H__
#define __DELUGEIMGMETADATA_H__

#include "AM.h"

#define DELUGE_MAX_NUM_PAGES       (((DELUGE_MAX_IMAGE_SIZE-1)/DELUGE_BYTES_PER_PAGE)+1)
#define DELUGE_PAGE_BITVEC_SIZE    (((DELUGE_MAX_NUM_PAGES-1) / 8) + 1)
#define DELUGE_DELTA_VEC_SIZE      (DELUGE_MAX_NUM_PAGES/2)
#define DELUGE_UPD_PKT_BITVEC_SIZE (DELUGE_DELTA_VEC_SIZE/DELUGE_NUM_DELTAS_PER_PKT)

#define NIBBLE_GET(x, i)       (((x)>>(4*(i)))&0xf)
#define NIBBLE_SET(x, i, v)    ((((v)&0xf)<<(4*(i))) | ((x)&(0xf<<(4*(!(i))))))
#define NIBBLEVEC_GET(x, i)    (NIBBLE_GET((x)[(i)/2], (i)%2))
#define NIBBLEVEC_SET(x, i, v) ((x)[(i)/2] = NIBBLE_SET((x)[(i)/2],(i)%2,(v))) 

typedef uint16_t imgvnum_t;

typedef struct DelugeImgSummary {
  imgvnum_t vNum;                           // version num of image
  uint16_t  numPgsComplete;                 // num pages available to send
} DelugeImgSummary;

typedef struct DelugeMetadata {
  DelugeImgSummary summary;
  uint16_t         sig;
  uint16_t         prevVNum;
  uint32_t         imgSize;
  uint16_t         numPgs;
  uint8_t          deltas[DELUGE_DELTA_VEC_SIZE];          // vector of page version deltas
  uint8_t          incompletePgs[DELUGE_PAGE_BITVEC_SIZE]; // bit-vector marking needed pages
} DelugeMetadata;

enum {
  DELUGE_DIFF   = 0,
  DELUGE_DELTAS = 1,
};

#define DELUGE_DIFF_PKT_BITVEC_SIZE (TOSH_DATA_LENGTH-7)
#define DELUGE_NUM_DELTAS_PER_PKT   (DELUGE_DIFF_PKT_BITVEC_SIZE*2)

typedef struct DelugeImgDiff {
  imgvnum_t vNum;                        // version num of new image
  uint8_t   type : 1;                    // if this is a diff bitvec or a delta vec
  uint32_t  imgSize : 23;                // size of the new image in bytes
  uint16_t  startPg;                     // start page of delta vec
  uint8_t   updateVector[DELUGE_DIFF_PKT_BITVEC_SIZE]; // pages which have changed
} __attribute__ ((packed)) DelugeImgDiff;

#endif

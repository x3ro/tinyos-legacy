#ifndef __FSMATE_H__
#define __FSMATE_H__

// !! SENSOR_READINGS + SIZEOF(RECORDMETADATA)/2 <= MATE_BUF_LEN
//#define SENSOR_READINGS 3
#define RECORD_SIZE_IN_WORDS ((sizeof(RecordMetadata) / 2) + SENSOR_READINGS)

#define LOC_BLKOFFSET 4
#define LOC_STARTCOOKIE 8
#define LOC_SEQNO 12
#define LOC_RECSIZE 16

enum {
  FSMATE_VOL_ID = 3,
  //FSMATE_VOL_ID = unique("BlockWrite"),
  FSMATE_NUM_BLOCKS = 9
};

typedef enum {
  OFF,
  READY, 
  READ,
  WRITE,
  DEL
} FlashStatus;

typedef struct RecordMetadata {
  uint32_t timeStamp;
  uint32_t seqNo;
  uint16_t status;
} RecordMetadata;

#endif

/**
   |------------------|
   |    TIMESTAMP     | <- 4 bytes (2 words)
   |------------------|
   |     SEQ NO       | <- 4 bytes (2 words)
   |------------------|
   |  STATUS |          <- 2 bytes (1 word)
   |---------|
**/


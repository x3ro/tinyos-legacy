/**
 * @file      ResponseData.c
 * @author    Michael Li
 *
 * @version   2004/9/14    mli      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: ResponseData.h,v 1.1 2005/03/31 07:51:06 husq Exp $
 */


// NOTE:  data taken from SkyeTek Protocol V.2 document

typedef struct rfid_codes
{
  uint8_t code; 
  char *description;
} rfid_codes_t; 


#define NUM_RESPONSE_CODES 26 
rfid_codes_t response_codes[NUM_RESPONSE_CODES] =
{
  {0x00, "Invalid Response Code"},
  {0x14, "SELECT TAG pass"},
  {0x1C, "SELECT TAG LOOP activate"},
  {0x94, "SELECT TAG fail"},
  {0x9C, "SELECT TAG LOOP cancel"},
  {0x21, "READ MEM pass"},
  {0x22, "READ SYS pass"},
  {0x24, "READ TAG pass"},
  {0xA1, "READ MEM fail"},
  {0xA2, "READ SYS fail"},
  {0xA4, "READ TAG fail"},
  {0x41, "WRITE MEM pass"},
  {0x42, "WRITE SYS pass"},
  {0x44, "WRITE TAG pass"},
  {0xC1, "WRITE MEM fail"},
  {0xC2, "WRITE SYS fail"},
  {0xC4, "WRITE TAG fail"},
  {0x80, "Non ASCII character in REQUEST"},
  {0x81, "BAD CRC"},
  {0x82, "FLAGS don't match COMMAND"},
  {0x83, "FLAGS don't match TAG TYPE"},
  {0x84, "Unkown COMMAND"},
  {0x85, "Unkown TAG TYPE"},
  {0x86, "Invalid STARTING BLOCK"},
  {0x87, "Invalid NUMBER OF BLOCKS"},
  {0x88, "Invalid Message Length"},
};




// tag type name 
#define NUM_TAG_TYPES 10 
rfid_codes_t tag_types[NUM_TAG_TYPES] =
{
  {0x00, "Auto-detect"},
  {0x01, "ISO15693"},
  {0x02, "I CODE1"},
  {0x03, "Tag-it HF"},
  {0x04, "ISO14443A"},
  {0x05, "ISO14443B"},
  {0x06, "PicoTag"},
  {0x07, "RFU"},
  {0x08, "GemWave C210"},
  {0x09, "RFU"}
};



// ASCII version of tagType returned from SkyeRead Mini
typedef struct tagType
{
  uint8_t type[2];
  uint8_t typeExt1[2];
  uint8_t typeExt2[2];
  uint8_t typeExt3[2];
} tagType_t;


// Tag specs info 
typedef struct tagSpecs
{
  uint8_t type;
  uint8_t typeExt1;
  uint8_t typeExt2;
  uint8_t typeExt3;
  uint8_t TIDSize;
  uint8_t blockSize;
  uint8_t numBlocks;
  char *description;
} tagSpecs_t;



#define NUM_TAG_TYPE_SPECS 11
tagSpecs_t RFIDtags[NUM_TAG_TYPE_SPECS] =
{
  { 0, 0x00, 0x00, 0x00, 0,  0,   0, ""  },  // unkown specs
  { 1, 0xE0, 0x07, 0x00, 6,  4,  64, "Tag-it HF-I (Texas Instruments)"},
  { 1, 0xE0, 0x04, 0x01, 5,  4,  28, "I-Code SLI (Philips)"}, 
  { 1, 0x60, 0x05, 0x02, 5,  8,  29, "my-d SRF55VxxP (Infineon)"},
  { 1, 0x60, 0x05, 0x00, 5,  8, 125, "my-d SRF55V10P (Infineon)"},
  { 1, 0xE0, 0x02, 0x00, 6,  4,  16, "LRI512 (ST Microelectronics)"},
  { 2, 0x00, 0x00, 0x00, 8,  4,  16, "(Philips)"},
  { 3, 0x00, 0x00, 0x00, 4,  4,   8, ""},
  { 4, 0x00, 0x00, 0x00, 4, 16,  64, "Mifare Standard 4k (Philips)"},
  { 5, 0x00, 0x00, 0x00, 8,  2,  11, "SR176 (ST Microelectronics)"},
  { 6, 0x00, 0x00, 0x00, 8,  8,  29, "(Inside Contactless)"}
};

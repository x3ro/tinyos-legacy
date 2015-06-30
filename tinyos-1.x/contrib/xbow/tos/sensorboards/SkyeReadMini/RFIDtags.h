/*
 * Description:
 * Tag specs for 13.56 MHz RFIDs taken from 
 * "SkyeTek Procool v.2.0" document" Section 5: Tag Descriptions
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors: Michael Li 
 *
 * Date last modified:  10/05/04
 *
 */


#define UNKNOWN 0x00
#define ISO15693 0x01
#define I_CODE1 0x02
#define Tagit_HF 0x03
#define ISO14443A 0x04
#define IS014444B 0x05
#define PicoTag_2K 0x06
#define RFU 0x07           // specs not defined in SkyeTek Protocol V.2
#define GemWave_C210 0x08  // specs not defined in SkyeTek Protocol V.2


// ASCII version of tagType returned from SkyeRead Mini
typedef struct tagType
{
  uint8_t type[2];
  uint8_t typeExt1[2];
  uint8_t typeExt2[2];
  uint8_t typeExt3[2];
} tagType_t;


typedef struct tagSpecs
{
  uint8_t type;
  uint8_t typeExt1;
  uint8_t typeExt2;				  	
  uint8_t typeExt3;				  	
  uint8_t TIDSize;
  uint8_t blockSize; 
  uint8_t numBlocks; 
} tagSpecs_t;



#define NUM_TAG_SPEC_TYPES 11 
tagSpecs_t RFIDtags[NUM_TAG_SPEC_TYPES] =
{
  {   UNKNOWN, 0x00, 0x00, 0x00, 0,  0,   0}, // Unkown tag found 
  {  ISO15693, 0xE0, 0x07, 0x00, 6,  4,  64}, // ISO15693 - Tag-it HF-I (Texas Instruments)
  {  ISO15693, 0xE0, 0x04, 0x01, 5,  4,  28}, // ISO15693 - I-Code SLI (Philips)
  {  ISO15693, 0x60, 0x05, 0x02, 5,  8,  29}, // ISO15693 - my-d SRF55VxxP (Infineon)
  {  ISO15693, 0x60, 0x05, 0x00, 5,  8, 125}, // ISO15693 - my-d SRF55V10P (Infineon)
  {  ISO15693, 0xE0, 0x02, 0x00, 6,  4,  16}, // ISO15693 - LRI512 (ST Microelectronics)
  {   I_CODE1, 0x00, 0x00, 0x00, 8,  4,  16}, // I CODE1 (Philips)
  {  Tagit_HF, 0x00, 0x00, 0x00, 4,  4,   8}, // Tag-it HF 
  { ISO14443A, 0x00, 0x00, 0x00, 4, 16,  64}, // ISO14443A - Mifare Standard 4k (Philips)
  { IS014444B, 0x00, 0x00, 0x00, 8,  2,  11}, // ISO14443B - SR176 (ST Microelectronics)
  {PicoTag_2K, 0x00, 0x00, 0x00, 8,  8,  29}  // PicoTag 2K (Inside Contactless)
};


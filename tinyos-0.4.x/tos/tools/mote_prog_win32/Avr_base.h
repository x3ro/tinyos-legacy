/*
  Avr.h
  Uros Platise, (c) 1997
*/

#ifndef __AVR
#define __AVR

#include "Serial.h"
#include "sdf.h"
#include "PartDB.h"
#include "PSPI.h"

#define TARGET_MISSING 0xff
#define DEVICE_LOCKED  0x1
const unsigned BufferSize = (256*1024);
//  static const unsigned char highByte = 0x08;
//   static const unsigned char lowByte = 0x00;
  static const unsigned char highByte = 0x00;
   static const unsigned char lowByte = 0x08;

enum TSegmentName { SEG_UNKOWN, SEG_FLASH, SEG_EEPROM };
void Program_AVR(char FileName, TSegmentName Segmment=SEG_FLASH);
//------------------------------------------------------------------------------
class TAvr : public PSPI, public TSDF
{
private:
   struct SPart
   {
      char* name;
      unsigned char PartFamily;
   };
   static SPart  Parts[];
   unsigned char VendorCode;
   unsigned char PartFamily;
   unsigned char PartNumber;
   unsigned char last_data;
   unsigned int last_addr;
   unsigned int last_addr_full;
   bool deviceLocked;
   TPartDB* Part;
public:
   void writePage();
   TAvr (TDev*, TPartDB* _Part);
   ~TAvr () { }
   void enableAvr ();
   void identify ();
   int  getPart(unsigned char addr);
   int  readEEPROM (unsigned int addr);
   void writeEEPROM (unsigned int addr, unsigned char byte);
   int readFLASH (unsigned int addr);
   void write_verifyFLASH (unsigned int addr, unsigned char byte);
   void chipErase ();
   void setExtClock();
   void read_fuse();
 
   TSegTable* segFlash, *segEeprom;

  /* Standard Downloading Functions (sdf) */
   void upload (TAout* aout, bool verifyOnly=false);
   void download (TAout* aout, THexType inHexType=Undefined);
private:
   void checkMemoryRange (unsigned int addr, unsigned int top_addr);
   void waitAfterWrite ();
   TSegmentName parseSegment (TDataQuery* dataP);
   bool MisMatch;
};

#endif

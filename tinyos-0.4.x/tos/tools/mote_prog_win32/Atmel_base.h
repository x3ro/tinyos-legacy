/*
  Avr.h
  Uros Platise, (c) 1997
*/

#ifndef __AtmelAVR
#define __AtmelAVR

#include "Serial.h"
#include "sdf.h"
#include "PartDB.h"

#define TARGET_MISSING 0xff
#define DEVICE_LOCKED  0x1
 static const unsigned char lckPrg = 4;
   static const unsigned char lckPrgRd = 0;
class TAtmelAvr : public TSDF, public TSPI
{
private:
   struct SPart
   {
      char* name;
      unsigned char PartFamily;
   };
   static SPart  Parts[];
   struct SPrgPart
   {
      char* name;
      unsigned char code;
   };
   static SPrgPart PrgParts[];
   unsigned char supPrgCodes[16]; /* returned by programmer */

   unsigned char VendorCode;
   unsigned char PartFamily;
   unsigned char PartNumber;
   bool deviceLocked;
   TPartDB* Part;
   enum TSegmentName { SEG_FLASH=1, SEG_EEPROM, SEG_OTHER };

   unsigned char desiredCode;

  /* cache low byte returned at the same time as high byte */
   unsigned char bufLowByte;
   unsigned int bufAddr;
   bool cacheLowByte;

public:
   TAtmelAvr (TDev*, TPartDB* _Part, char *pName=NULL);
   ~TAtmelAvr ();
   void enableAvr ();
   int  readEEPROM (unsigned int addr);
   void writeEEPROM (unsigned int addr, unsigned char byte);
   int  readFLASH (unsigned int addr);
   void writeFLASH (unsigned int addr, unsigned char byte);
   void chipErase ();

   int  readLockBits ();
   void writeLockBits (unsigned char byte);

  
   TSegTable* segFlash, *segEeprom;

  /* Standard Downloading Functions (sdf) */
   void upload (TAout* aout, bool verifyOnly=false);
   void download (TAout* aout, THexType inHexType=Undefined);

  /* Some helper functions */
   bool isDeviceLocked () { return(PartFamily==DEVICE_LOCKED)?true:false; }

private:
   void ChkResp (unsigned char x);
   void identify ();
   void setAddress (unsigned int addr);
   void checkMemoryRange (unsigned int addr, unsigned int top_addr);
   TSegmentName parseSegment (TDataQuery* dataP);
};

#endif

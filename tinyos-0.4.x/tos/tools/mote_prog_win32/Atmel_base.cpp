#include "PCH.h" // common MicroSoft/Borland Headers
/*
    Avr.C

    Kit for AVR
    In-System Programmable
    Microcontrolers

    Uros Platise, (c) 1997
*/

#include "Atmel_base.h" // this is the header file for this source code
/* ATMEL STANDART AVR codes */
TAtmelAvr::SPart TAtmelAvr::Parts[] = {
   { "at90s1200", 0x90},
   { "at90s2313", 0x91},
   { "at90s4414", 0x92},
   { "at90s8515", 0x93},
   { "",          TARGET_MISSING},
   { "locked",    DEVICE_LOCKED},
   { "",          0x0}
};

/* ATMEL non-standart Programmer's AVR codes
   Valid for software version:
      SW_MAJOR=1, SW_MINOR=5
*/
//------------------------------------------------------------------------------
TAtmelAvr::SPrgPart TAtmelAvr::PrgParts[] = {
   { "S1200C", 0x12},
   { "S1200D", 0x13},
   { "S8515A", 0x38},
   { "S8252",  0x86},
   { "",       0x00}
};
//------------------------------------------------------------------------------
/* If invalid code is returned (~13) issue an error */
void TAtmelAvr::ChkResp (unsigned char x)
{
   if(x!=13)
   {
      throw Error_Device ("Device is not responding correctly.");
   }
}
//------------------------------------------------------------------------------
TAtmelAvr::TAtmelAvr (TDev* device, TPartDB* _Part, char *pName) :
TSPI (device), Part (_Part), cacheLowByte (false)
{
   device->bitOrentation (false);
   desiredCode=0;
   bool gotDevice=false;
   if(pName!=NULL)
   {
      if(pName[0] >= '0' && pName[0] <= '9')
      {
         desiredCode = strtol (&pName[0],(char**)NULL,16);
      }
      else
      {
         int j;
         for(j=0; PrgParts[j].code != 0; j++)
         {
            if(strcmp (pName, PrgParts[j].name)==0)
            {
               desiredCode = PrgParts[j].code;
               break;
            }
         }
         if(PrgParts[j].code == 0)
         {
            throw Error_Device ("Invalid part name.");
         }
      }
   }
  /* check: software version and supported part codes */
   unsigned char swVersion[2] = {'V', 0};
   unsigned char hwVersion[2] = {'v', 0};
   Send (swVersion, 1, 2);
   Send (hwVersion, 1, 2);
   printf ("Programmer Info:\n");
   printf ("  Software Version: %c.%c, Hardware Version: %c.%c\n",
           swVersion[0], swVersion[1],
           hwVersion[0], hwVersion[1]);

   unsigned char supCodes[1] = {'t'};
   device->Send (supCodes, 1);
   unsigned char bufCode;
   timeval timeout = {1, 0};
   int i=0;
   if(pName==NULL)
      printf ("  Supported Parts:\n");

   do
   {
      device->Recv (&bufCode, 1, &timeout);
      supPrgCodes[i++] = bufCode;
      if(bufCode==0)
      {
         break;
      }
      if(pName!=NULL)
      {
         if(bufCode == desiredCode)
         {
            gotDevice=true;
         }
         continue;
      }
      int j;
      for(j=0; PrgParts[j].code != 0; j++)
      {
         if(PrgParts[j].code == bufCode)
         {
            printf ("    - %.2xh (%s)\n", bufCode, PrgParts[j].name);
            break;
         }
      }
      if(PrgParts[j].code == 0)
      {
         printf ("    - %.2xh (not on the uisp's list yet)\n", bufCode);
      }
   } while(1);
   printf ("\n");
   if(gotDevice==false)
   {
      if(pName==NULL)
      {
         throw Error_Device ("Select one device from the above list and run me again.");
      }
      else
      {
         throw Error_Device ("Programmer does not supported chosen device.");
      }
   }
}
//------------------------------------------------------------------------------
TAtmelAvr::~TAtmelAvr ()
{
  /* leave programming mode! Due to this
     procedure, enableAvr had to be taken out
     of TAtmelAvr::TAtmelAvr func. */
   unsigned char leavePrg[1] = { 'L'};
   Send (leavePrg, 1);
}
//------------------------------------------------------------------------------
void TAtmelAvr::enableAvr ()
{
  /* Select Device Type */
   unsigned char setDevice[2] = { 'T', desiredCode};
   Send (setDevice, 2, 1);
   ChkResp (setDevice[0]);

  /* Enter Programming Mode */
   unsigned char enterPrg[1] = { 'P'};
   Send (enterPrg, 1);
   ChkResp (enterPrg[0]);

  /* Check chip ID */
   identify ();
}
//------------------------------------------------------------------------------
void TAtmelAvr::identify ()
{
  /* Read Signature Bytes */
   unsigned char sigBytes[3] = { 's', 0, 0};
   Send (sigBytes, 1, 3);
   VendorCode = sigBytes[0];
   PartFamily = sigBytes[1];
   PartNumber = sigBytes[2];

   if(PartFamily==DEVICE_LOCKED &&
      PartNumber==0x02)
   {
      deviceLocked=true;
      printf ("Cannot identify device because is it locked.\n");
      return;
   }
   else
   {
      deviceLocked=false;
   }
   if(PartFamily==TARGET_MISSING)
   {
      printf ("An error has occuried durring target initilization.\n"
              " * Target status:\n"
              "   Vendor Code = %x, Part Family = %x, Part Number = %x\n\n",
              VendorCode, PartFamily, PartNumber);
      throw Error_Device ("Probably the target is missing.");
   }
   if(PartFamily==DEVICE_LOCKED)
   {
      printf ("Device is locked.\n");
      return;
   }
   int i;
   for(i=0; Parts[i].PartFamily != 0x0; i++)
   {
      if(PartFamily == Parts[i].PartFamily)
      {
         printf ("Device %s found.\n", Parts[i].name);
         Part->setPart (Parts[i].name);

      /* find flash end eeprom segments */
         for(int j=0; Part->segTableP[j].segName[0] != 0; j++)
         {
            if(strcmp (Part->segTableP[j].segName, "flash")==0)
            {
               segFlash = &Part->segTableP[j];
               printf ("FLASH: %ld bytes\n", segFlash->size);
            }
            if(strcmp (Part->segTableP[j].segName, "eeprom")==0)
            {
               segEeprom = &Part->segTableP[j];
               printf ("EEPROM: %ld bytes\n", segEeprom->size);
            }
         }
         return;
      } /* end if */
   }
   if(Parts[i].PartFamily == 0x0)
   {
      throw Error_Device ("Probably the AVR MCU is not in the RESET state.\n"
                          "Check it out and run me again.");
   }
}
//------------------------------------------------------------------------------
void TAtmelAvr::setAddress (unsigned int addr)
{
   unsigned char setAddr[3] = { 'A', (addr>>8)&0xff, addr&0xff};
   Send (setAddr, 3, 1);
   ChkResp (setAddr[0]);
}
//------------------------------------------------------------------------------
int TAtmelAvr::readEEPROM (unsigned int addr)
{
   checkMemoryRange (addr, segEeprom->size);
   setAddress (addr);
   unsigned char readEE[1] = { 'd'};
   Send (readEE, 1);
   return(int)readEE[0];
}
//------------------------------------------------------------------------------
void TAtmelAvr::writeEEPROM (unsigned int addr, unsigned char byte)
{
   checkMemoryRange (addr, segEeprom->size);
   setAddress (addr);
   unsigned char writeEE[2] = { 'D', byte};
   Send (writeEE, 2, 1);
   ChkResp (writeEE[0]);
}
//------------------------------------------------------------------------------
int TAtmelAvr::readFLASH (unsigned int addr)
{
   unsigned int saddr = addr>>1;
   if(bufAddr==saddr && cacheLowByte==true)
   {
      return bufLowByte;
   }
   checkMemoryRange (addr, segFlash->size);
   setAddress (saddr);
   unsigned char rdF[2] = { 'R', 0};
   Send (rdF, 1, 2);
  /* cache low byte */
   cacheLowByte = true;
   bufAddr = saddr;
   bufLowByte = rdF[1];
   return rdF[addr&1];
}
//------------------------------------------------------------------------------
void TAtmelAvr::writeFLASH (unsigned int addr, unsigned char byte)
{
   cacheLowByte = false; /* clear buffer */
   checkMemoryRange (addr, segFlash->size);
   setAddress (addr>>1);
   unsigned char wrF[2] = { (addr&1)?'c':'C', byte};
   Send (wrF, 2, 1);
   ChkResp (wrF[0]);
}
//------------------------------------------------------------------------------
void TAtmelAvr::checkMemoryRange (unsigned int addr, unsigned int top_addr)
{
   if(addr >= top_addr)
   {
      throw Error_MemoryRange ();
   }
}
//------------------------------------------------------------------------------
void TAtmelAvr::chipErase ()
{
   unsigned char eraseTarget[1] = { 'e'};
   Send (eraseTarget, 1);
   ChkResp (eraseTarget[0]);
   if(PartFamily==DEVICE_LOCKED)
   {
      identify ();
   }
}
//------------------------------------------------------------------------------
int TAtmelAvr::readLockBits ()
{
   unsigned char rdLock[1] = { 'F'};
   Send (rdLock, 1);
   return rdLock[0];
}
//------------------------------------------------------------------------------
void TAtmelAvr::writeLockBits (unsigned char byte)
{
   unsigned char wrLock[2] = { 'l', byte};
   Send (wrLock, 2, 1);
   ChkResp (wrLock[0]);
}
//------------------------------------------------------------------------------
void TAtmelAvr::upload (TAout* aout, bool verifyOnly)
{
   unsigned char read_buf[256*1024];
   char segName_buf[32];
   TDataQuery rdQ;
   rdQ.segName = segName_buf;
   rdQ.buf = read_buf;
   while(aout->readData (&rdQ)>0)
   {
      TSegmentName curSeg = parseSegment (&rdQ);
      printf ("%s: %Xh bytes to %s at %Xh",
              (verifyOnly==false)?"Uploading":"Verifying",
              rdQ.size, rdQ.segName, rdQ.offset);
      if(rdQ.keepOut==true)
      {
         printf (" - skipping\n"); continue;
      }
      putchar ('\n');
      if(curSeg==SEG_FLASH)
      {
         if(rdQ.size&1)
         {
            throw Error_Device ("Flash segment not correctly aligned.");
         }
      }
      unsigned char byteBuf;
      for(unsigned int ib=0; ib<rdQ.size; ib++, rdQ.offset++)
      {
         if(verifyOnly==false)
         {
            switch(curSeg)
            {
            case SEG_FLASH:
               writeFLASH (rdQ.offset, rdQ.buf[ib]);
               break;
            case SEG_EEPROM:
               writeEEPROM (rdQ.offset, rdQ.buf[ib]);
               break;
            default:
               break;
            }
         }
         else
         {
            switch(curSeg)
            {
            case SEG_FLASH:
               byteBuf = (unsigned char)readFLASH (rdQ.offset);
               if(rdQ.buf[ib]!=byteBuf)
               {
                  printf ("\r             \r"
                          "difference at %04Xh: flash=%.2x, file=%.2x\n",
                          rdQ.offset, byteBuf, rdQ.buf[ib]);
               }
               break;
            case SEG_EEPROM:
               byteBuf = (unsigned char)readEEPROM (rdQ.offset);
               if(rdQ.buf[ib]!=byteBuf)
               {
                  printf ("\r            \r"
                          "difference at %04Xh: eeprom=%.2x, file=%.2x\n",
                          rdQ.offset, byteBuf, rdQ.buf[ib]);
               }
               break;
            default: break;
            }
         }
         if((ib%8)==0)
            printf ("\r%04Xh", ib);fflush (stdout);

         if (kbhit() && getch() == 0x1b) break;  // stop on ESC only
      }
      printf ("\r          \r"); fflush (stdout); /* delete status line */
   }
}
//------------------------------------------------------------------------------
void TAtmelAvr::download (TAout* aout, THexType inHexType)
{
   unsigned char write_buf[256*1024];
   char segName_buf[32];
   TDataQuery wrQ;
   wrQ.segName = segName_buf;
   wrQ.buf = write_buf;
   wrQ.offset = 0x0; /* !!! */
   wrQ.keepOut = false;

  /* download flash */
   if(aout->segRequest ("flash"))
   {
      strcpy (wrQ.segName, "flash");
      printf ("Downloading %lxh bytes from flash memory ...\n", segFlash->size);
      for(long fi=0; fi<segFlash->size; fi++)
      {
         wrQ.buf[fi] = (unsigned char)readFLASH (fi);
         if((fi%16)==0)
            printf ("\r%04Xh", fi); fflush (stdout);

         if (kbhit() && getch() == 0x1b) break;  // stop on ESC only
      }
      printf ("\r          \r"); fflush (stdout); /* delete status line */
      wrQ.size = segFlash->size;
      aout->writeData (&wrQ, inHexType);
   }
  /* download eeprom */
   if(aout->segRequest ("eeprom"))
   {
      strcpy (wrQ.segName, "eeprom");
      printf ("Downloading %lxh bytes from eeprom memory ...\n", segEeprom->size);
      for(long fi=0; fi<segEeprom->size; fi++)
      {
         wrQ.buf[fi] = (unsigned char)readEEPROM (fi);
         if((fi%16)==0)
            printf ("\r%04Xh", fi); fflush (stdout);

         if (kbhit() && getch() == 0x1b) break;  // stop on ESC only
      }
      printf ("\r          \r"); fflush (stdout); /* delete status line */
      wrQ.size = segEeprom->size;
      aout->writeData (&wrQ, inHexType);
   }
}
//------------------------------------------------------------------------------
/*
  This is required because if file is not linked with avr-gcc
  eram and sram segments are not removed.
*/
TAtmelAvr::TSegmentName TAtmelAvr::parseSegment (TDataQuery* dataP)
{
   if(strcmp (dataP->segName, "flash")==0)
   {
      return SEG_FLASH;
   }
   else if(strcmp (dataP->segName, "eeprom")==0)
   {
      return SEG_EEPROM;
   }
   else if(strcmp (dataP->segName, "eram")==0)
   {
      return SEG_OTHER;
   }
   else if(strcmp (dataP->segName, "sram")==0)
   {
      return SEG_OTHER;
   }
   else
   {
      throw Error_Device ("Invalid Segment", dataP->segName);
   }
}
//------------------------------------------------------------------------------


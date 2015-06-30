#include "PCH.h" // common MicroSoft/Borland Headers
/*
Avr.C

  Kit for AVR
  In-System Programmable
  Microcontrolers
  
    Uros Platise, (c) 1997
*/

#include "Avr_base.h"// this is the header file for this source code
const char MAX_ERRORS = 10;
//------------------------------------------------------------------------------
TAvr::SPart TAvr::Parts[] = {
  { "at90s1200", 0x90},
  { "at90s2313", 0x91},
  { "at90s4414", 0x92},
  { "at90s8515", 0x93},
  { "atmega163", 0x94},
  { "", TARGET_MISSING},
  { "device locked", DEVICE_LOCKED},
  { "", 0x0}
};
//------------------------------------------------------------------------------
TAvr::TAvr (TDev* device, TPartDB* _Part) : Part (_Part)
{
  //   device->bitOrentation (true);
  enableAvr ();
  identify ();
  last_addr = 0xffffffff;
}
//------------------------------------------------------------------------------
void TAvr::enableAvr ()
{
  unsigned char prg [4] = { 0xAC, 0x53, 0, 0};
  int try_number = 32;
  do
  {
    prg[0]=0xAC; prg[1]=0x53; prg[2]=prg[3]=0;
    Send (prg, 4);
    if(prg[2] == 0x53)
      break;
    clk ();
  } while(try_number--);
  if(try_number == -1)
    throw Error_Device ("Exceeded 32 tries to find device. Check device connection");
  else if(try_number < 32)
    printf ("Succeeded after %d retries.\n", (32-try_number));
  
}
//------------------------------------------------------------------------------
void TAvr::identify ()
{
  VendorCode = getPart (0);
  PartFamily = getPart (1);
  PartNumber = getPart (2);
  if(PartFamily==DEVICE_LOCKED &&
    PartNumber==0x02)
  {
    deviceLocked=true;
    printf ("Cannot identify device because is it locked.\n");
    return;
  }
  else
    deviceLocked=false;
  
  if(PartFamily==TARGET_MISSING)
  {
    printf ("An error has occuried durring initilization.\n"
      " * Target status:\n"
      "   Vendor Code = %x, Part Family = %x, Part Number = %x\n\n",
      VendorCode, PartFamily, PartNumber);
    throw Error_Device ("Probably the target is missing.");
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
int TAvr::getPart (unsigned char addr)
{
  unsigned char info[4] = { 0x30, 0, addr, 0};
  Send(info, 4);
  return int(info[3]);
}
//------------------------------------------------------------------------------
int TAvr::readEEPROM (unsigned int addr)
{
  checkMemoryRange (addr, segEeprom->size);
  unsigned char eeprom[4] = { 0xA0,
    (unsigned char)((addr>>8)&0xff),
    (unsigned char)(addr&0xff),
    0}; 
  Send(eeprom, 4);
  return int(eeprom[3]);
}

void TAvr::writePage(){
  //	printf("page\n");
  unsigned int addr = last_addr;
  checkMemoryRange (addr, segFlash->size);
  addr = last_addr;
  unsigned char hl = (addr&1)?(lowByte):(highByte);
  addr>>=1;
  unsigned char flash[4] = { 0x4C,
    (unsigned char)((addr >> 8) & 0xff),
    (unsigned char)(addr & 0xff),
    0};
  
  Send(flash, 4);
  flash[3] = ~last_data;
  int count = 0;
  while(flash[3] != last_data){
    waitAfterWrite ();
    flash[0] = 0x20+hl;
    flash[1] = ((addr >> 8) & 0xff);
    flash[2] = (addr & 0xff);
    flash[3] = 0x00;
    Send(flash, 4);
    count ++;
    if(count > 50)
    {
      throw Error_Device (" !!!!!!!! Could not verify address....!!!!!!!!\n"
	"Check it out and run me again.");
      exit(-1);
    }
  }
  
  
}


//------------------------------------------------------------------------------
void TAvr::writeEEPROM (unsigned int addr, unsigned char byte)
{
  checkMemoryRange (addr, segEeprom->size);
  unsigned char eeprom[4] = { 0xC0,
    (unsigned char)((addr>>8)&0xff),
    (unsigned char)(addr&0xff),
    byte};
  Send(eeprom, 4);
  waitAfterWrite ();
}
//------------------------------------------------------------------------------
int TAvr::readFLASH (unsigned int addr)
{
  checkMemoryRange (addr, segFlash->size);
  unsigned char hl = (addr&1)?(lowByte):(highByte);
  addr>>=1;
  unsigned char flash[4] = { 0x20+hl,
    (unsigned char)((addr >> 8) & 0xff),
    (unsigned char)(addr & 0xff),
    0};
  
  Send(flash, 4);
  
  return int(flash[3]);
}
//------------------------------------------------------------------------------
void TAvr::write_verifyFLASH (unsigned int addr, unsigned char byte)
{
  //   printf("sending %d address %x data ", addr, byte);
  unsigned int Address = addr;
  unsigned int org_addr = addr;
  checkMemoryRange (addr, segFlash->size);
  unsigned char hl = (addr&1)?(lowByte):(highByte);
  addr>>=1;
  unsigned char flash[4] = { 0x40+hl,
    (unsigned char)((addr >> 8) & 0xff),
    (unsigned char)(addr & 0xff),
    byte};
  
  if((last_addr != 0xffffffff) && (((last_addr ^ org_addr) & 0xfffff80) != 0)){
    //	printf("addr: %x, last %x\n", org_addr, last_addr);
    writePage();
    last_addr = 0xffffffff;	
  }
  last_addr = org_addr;
  last_data = byte;
  Send(flash, 4);
}
//------------------------------------------------------------------------------
void TAvr::checkMemoryRange (unsigned int addr, unsigned int top_addr)
{
  if(addr >= top_addr)
  {
    throw Error_MemoryRange ();
  }
}
//------------------------------------------------------------------------------
void TAvr::chipErase ()
{
  unsigned char chip_erase[4] = { 0xAC, 0x80, 0x00, 0x00};
  Send (chip_erase, 4);
  waitAfterWrite ();
  waitAfterWrite ();
  waitAfterWrite ();
  waitAfterWrite ();
  waitAfterWrite ();
  enableAvr (); // this toggles the reset line
}


void TAvr::read_fuse ()
{
  unsigned char ext_clock[4] = { 0x50, 0x00, 0x00, 0x00};
  Send (ext_clock, 4);
  waitAfterWrite ();
  waitAfterWrite ();
  waitAfterWrite ();
  waitAfterWrite ();
  waitAfterWrite ();
  printf("read fuse: %x\n", ext_clock[3]);
  enableAvr (); // this toggles the reset line 
}


void TAvr::setExtClock ()
{
  unsigned char ext_clock[4] = { 0xAC, 0xa0, 0x00, 0xFF};
  Send (ext_clock, 4);
  waitAfterWrite ();
  waitAfterWrite ();
  waitAfterWrite ();
  waitAfterWrite ();
  waitAfterWrite ();
  printf("write_fuse: %x\n", ext_clock[3]);
  enableAvr (); // this toggles the reset line
}
//------------------------------------------------------------------------------
void TAvr::waitAfterWrite ()
{
  //   timeval tv;
  //   tv.tv_sec = 0;
  //   tv.tv_usec = 4000;
  /*  select (0,NULL,NULL,NULL, &tv); */
  //	printf("war\n");
  volatile int i;
  for(i=0; i<(5000*speed); i++);
}
//------------------------------------------------------------------------------
void TAvr::upload (TAout* aout, bool verifyOnly)
{
  unsigned char read_buf[BufferSize];
  char segName_buf[32];
  TDataQuery rdQ;
  
  rdQ.segName = segName_buf;
  rdQ.buf = read_buf;
  for (unsigned i=0; i<BufferSize; i++)
    read_buf[i] = 0xff; // clear buffer
  
  read_buf[20000] = 0;
  while(aout->readData (&rdQ)>0)
  {
    TSegmentName curSeg = parseSegment (&rdQ);
    printf ("%s: %04Xh bytes to %s at %04Xh",
      (verifyOnly==false)?"Uploading":"Verifying",
      rdQ.size, rdQ.segName, rdQ.offset);
    if(rdQ.keepOut==true)
    {
      printf (" - skipping\n");
      continue;
    }
    putchar ('\n');
    //      if(curSeg==SEG_FLASH)
    //      {
    //         if(rdQ.size&1)
    //            throw Error_Device ("Flash segment not correctly aligned.");
    //      }
    
    printf("sleeping...\n");
    for(int pp = 0; pp < 0xffff; pp++){}
    unsigned int Address = rdQ.offset;
    //Address +=8;
    MisMatch = false;
    int first = 0;
    //if(verifyOnly) rdQ.size = BufferSize;
    for(unsigned ib=0; ib<rdQ.size; ib++, Address++)
    {
      
      unsigned char byte = rdQ.buf[ib];
      if(verifyOnly==false)
      {
	switch(curSeg)
	{
	case SEG_FLASH:
	  write_verifyFLASH(Address, byte);
	  break;
	case SEG_EEPROM:
	  writeEEPROM (Address, byte);
	  break;
	}
      }
      else
      {
	unsigned char read_data;
	switch(curSeg)
	{
	case SEG_FLASH:
	  read_data = (unsigned char)readFLASH (Address);
	  if(byte != read_data)
	  {
	    printf ("\r             \r"
	      "difference at %04Xh: flash=%.2X, file=%.2X\n",
	      Address, read_data, byte);
	  }
	  break;
	case SEG_EEPROM:
	  read_data = (unsigned char)readEEPROM (Address);
	  if(byte != read_data)
	  {
	    printf ("\r            \r"
	      "difference at %04Xh: eeprom=%.2X, file=%.2X\n",
	      Address, read_data, byte);
	  }
	  break;
	}
      }
      if((ib%128)==0)
      {
	if(MisMatch) printf ("\n");
	printf ("\r%04Xh", ib); fflush (stdout);
	MisMatch = false;
      }
      if (kbhit() && getch() == 0x1b) break;  // stop on ESC only
    }
    if ((verifyOnly == false) && (curSeg == SEG_FLASH))
      writePage();
    printf ("\r          \r"); 
    printf ("%s COMPLETE!\n",
      (verifyOnly==false)?"Uploading":"Verifying");
    fflush (stdout); /* delete status line */
  }
}
//------------------------------------------------------------------------------
void TAvr::download (TAout* aout, THexType inHexType)
{
  unsigned char write_buf[BufferSize];
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
    for(long address=segFlash->start; address<segFlash->size; address++)
    {
      write_buf[address] = readFLASH(address);
      if((address%16)==0)
	printf ("\r%04Xh", address);fflush (stdout);
      
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
    for(long address=segEeprom->start; address<segEeprom->size; address++)
    {
      write_buf[address] = readEEPROM(address);
      if((address%16)==0)
	printf ("\r%04Xh", address);fflush (stdout);
      
      if (kbhit() && getch() == 0x1b) break;  // stop on ESC only
    }
    
    printf ("\r          \r"); fflush (stdout); /* delete status line */
    wrQ.size = segEeprom->size;
    aout->writeData (&wrQ, inHexType);
  }
}
//------------------------------------------------------------------------------
TSegmentName TAvr::parseSegment (TDataQuery* dataP)
{
  if(strcmp (dataP->segName, "flash")==0)
    return SEG_FLASH;
  
  else if(strcmp (dataP->segName, "eeprom")==0)
    return SEG_EEPROM;
  
  else
    throw Error_Device ("Invalid Segment", dataP->segName);
}
//------------------------------------------------------------------------------



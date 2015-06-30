/* Stk500.C, Daniel Berntsson, 2001 */

#include "Stk500.h"
#include "Serial.h"


const TByte TStk500::pSTK500[] = { 0x30, 0x20 };
const TByte TStk500::pSTK500_Reply[] = { 0x14, 0x10 };

const TByte TStk500::SWminor[] = { 0x41, 0x82, 0x20 };
const TByte TStk500::SWminor_Reply[] = { 0x14, 0x07, 0x10 };

const TByte TStk500::SWmajor[] = { 0x41, 0x81, 0x20 };
const TByte TStk500::SWmajor_Reply[] = {0x14, 0x01, 0x10 };

const TByte TStk500::MagicNumber[] = { 0x45, 0x03, 0x00, 0xD7, 0xA0, 0x20 };
const TByte TStk500::MagicNumber_Reply[] = {0x14, 0x10 };

const TByte TStk500::EnterPgmMode[] = { 0x50, 0x20 };
const TByte TStk500::EnterPgmMode_Reply[] = { 0x14, 0x10 };

const TByte TStk500::LeavePgmMode[] = { 0x51, 0x20 };
const TByte TStk500::LeavePgmMode_Reply[] = { 0x14, 0x10 };

const TByte TStk500::SetAddress[] = { 0x55, '?', '?', 0x20 };
const TByte TStk500::SetAddress_Reply[] = { 0x14, 0x10 };

const TByte TStk500::EraseDevice[] = { 0x52, 0x20 };
const TByte TStk500::EraseDevice_Reply[] = { 0x14, 0x10 };

const TByte TStk500::WriteMemory[] = { 0x64, '?', '?', '?' };
const TByte TStk500::WriteMemory_Reply[] = { 0x14, 0x10 };

const TByte TStk500::ReadMemory[] = { 0x74, 0x01, 0x00, '?', 0x20 };;
const TByte TStk500::ReadMemory_Reply[] = { 0x14 };

const TByte TStk500::GetSignature[] = {0x75, 0x20};
const TByte TStk500::GetSignature_Reply[] = {0x75, '?', '?', '?', 0x20};

const TByte TStk500::CmdStopByte[] = { 0x20 };

const TByte TStk500::ReplyStopByte[] = { 0x10 };

const TByte TStk500::Flash = 'F';

const TByte TStk500::EEPROM = 'E';

const TByte TStk500::DeviceParam_Reply[] = { 0x14, 0x10 };

const TStk500::SPrgPart TStk500::prg_part[] = {
  {"AT90S4414",
   {0x42, 0x50, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0x7f, 0x7f, 0x80,
    0x7f, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x10, 0x00, 0x20}
  },
  {"AT90S2313",
   {0x42, 0x40, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0x7f, 0x7f, 0x80,
    0x7f, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x08, 0x00, 0x20}
  },
  {"AT90S1200",
   {0x42, 0x33, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x04, 0x00, 0x20}
  },
  {"AT90S2323",
   {0x42, 0x41, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x08, 0x00, 0x20}
  },
  {"AT90S2343",
   {0x42, 0x43, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x08, 0x00, 0x20}
  },
  {"AT90S2333",
   {0x42, 0x42, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x08, 0x00, 0x20}
  },
  {"AT90S4433",
   {0x42, 0x51, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x10, 0x00, 0x20}
  },
  {"AT90S4434",
   {0x42, 0x52, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x10, 0x00, 0x20}
  },
  {"AT90S8515",
   {0x42, 0x60, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0x7f, 0x7f, 0x80,
    0x7f, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x20, 0x00, 0x20}
  },
  {"AT90S8535",
   {0x42, 0x61, 0x00, 0x00, 0x01, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x20, 0x00, 0x20}
  },
  {"ATtiny11",
   {0x42, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x20}
  },
  {"ATtiny12",
   {0x42, 0x12, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0xff, 0xff, 0xff,
    0xff, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x04, 0x00, 0x20}
  },
  {"ATtiny15",
   {0x42, 0x13, 0x00, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0xff, 0xff, 0xff,
    0xff, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x04, 0x00, 0x20}
  },
  {"ATtiny22",
   {0x42, 0x20, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0xff, 0xff, 0x00,
    0xff, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x08, 0x00, 0x20}
  },
  {"ATtiny28",
   {0x42, 0x22, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00, 0x20}
  },
  {"ATmega323",
   {0x42, 0x90, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, 0x00, 0x80, 0x04, 0x00, 0x00, 0x00, 0x80, 0x00, 0x20}
  },
  {"ATmega161",
   {0x42, 0x80, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0xff, 0xff, 0xff,
    0xff, 0x00, 0x80, 0x02, 0x00, 0x00, 0x00, 0x40, 0x00, 0x20}
  },
  {"ATmega163",
   {0x42, 0x81, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0xff, 0xff, 0xff,
    0xff, 0x00, 0x80, 0x02, 0x00, 0x00, 0x00, 0x40, 0x00, 0x20}
  },
  {"ATmega103",
   {0x42, 0xb1, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x10, 0x00, 0x00, 0x02, 0x00, 0x00, 0x20}
  },
  {"ATmega128",
   {0x42, 0xb2, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x03, 0xff, 0xff, 0xff,
    0xff, 0x01, 0x00, 0x10, 0x00, 0x00, 0x02, 0x00, 0x00, 0x20}
  },
  {"", {0}}
};


/* Read byte from active segment at address addr. */
TByte TStk500::ReadByte(TAddr addr){

  if (read_buffer == NULL)
    ReadMem();

  return read_buffer[addr];
}


/* Write byte to active segment */
void TStk500::WriteByte(TAddr addr, TByte byte, bool flush_buffer=true){

  if (write_buffer == NULL) {
    write_buffer = new TByte[GetSegmentSize()];
    memset(write_buffer, 0xff, GetSegmentSize());
  }

  if (addr > maxaddr)
    maxaddr = addr;

  write_buffer[addr] = byte;
}


void TStk500::FlushWriteBuffer(){
  TByte buf[0x200];
  int wordsize;
  TAddr addr;
  TByte seg;

  if (segment == SEG_FLASH) {
    wordsize = 2;
    seg = Flash;
  } else {
    wordsize = 1;
    seg = EEPROM;
  }

  EnterProgrammingMode();

  addr = 0;
  for (unsigned int addr=0; addr<maxaddr; addr+=0x100) {
    memcpy(buf, SetAddress, sizeof(SetAddress));
    buf[1] = (addr/wordsize) & 0xff;
    buf[2] = ((addr/wordsize) >> 8) & 0xff;
    Send(buf, sizeof(SetAddress), sizeof(SetAddress_Reply));
    if (memcmp(buf, SetAddress_Reply, sizeof(SetAddress_Reply)) != 0) {
      throw Error_Device ("Device is not responding correctly."); }

    memcpy(buf, WriteMemory, sizeof(WriteMemory));
    buf[1] = 0x01;
    buf[2] = 0x00;
    buf[3] = seg;
    memcpy(buf+sizeof(WriteMemory), write_buffer+addr, 0x100);
    memcpy(buf+sizeof(WriteMemory)+0x100,
       CmdStopByte, sizeof(CmdStopByte));
    Send(buf, sizeof(WriteMemory)+0x100+sizeof(CmdStopByte),
     sizeof(WriteMemory_Reply));
    if (memcmp(buf, WriteMemory_Reply, sizeof(WriteMemory_Reply)) != 0) {
      throw Error_Device ("Device is not responding correctly."); }
  }   
  LeaveProgrammingMode();
}


/* Chip Erase */
void TStk500::ChipErase(){
  TByte buf[100];

  EnterProgrammingMode();

  memcpy(buf, EraseDevice, sizeof(EraseDevice));
  Send(buf, sizeof(EraseDevice), sizeof(EraseDevice_Reply));
  if (memcmp(buf, EraseDevice_Reply, sizeof(EraseDevice_Reply)) != 0) {
    throw Error_Device ("Device is not responding correctly."); }

  LeaveProgrammingMode();
}


/* Brrr.. evil :( */
void TStk500::WriteLockBits(TByte bits){
  throw Error_Device ("TStk500::WriteLockBits not implemented.");
}


void TStk500::EnterProgrammingMode() {
  TByte buf[100];
  TByte vmajor;
  TByte vminor;

  memcpy(buf, pSTK500, sizeof(pSTK500));
  Send(buf, sizeof(pSTK500), sizeof(pSTK500_Reply));
  if (memcmp(buf, pSTK500_Reply, sizeof(pSTK500_Reply)) != 0) {
    throw Error_Device ("Device is not responding correctly."); }

  memcpy(buf, prg_part[desired_part].params,
     sizeof(prg_part[desired_part].params));
  Send(buf, sizeof(prg_part[desired_part].params),
       sizeof(DeviceParam_Reply));
  if (memcmp(buf, DeviceParam_Reply, sizeof(DeviceParam_Reply)) != 0) {
    throw Error_Device ("Device is not responding correctly."); }

  memcpy(buf, SWminor, sizeof(SWminor));
  Send(buf, sizeof(SWminor), sizeof(SWminor_Reply));
  vminor = buf[1];

  memcpy(buf, SWmajor, sizeof(SWmajor));
  Send(buf, sizeof(SWmajor), sizeof(SWmajor_Reply));
  vmajor = buf[1];

  if (! (vmajor == 1 && vminor == 7))
    throw Error_Device ("Need STK500 firmware version 1.7.");

  memcpy(buf, MagicNumber, sizeof(MagicNumber));
  Send(buf, sizeof(MagicNumber), sizeof(MagicNumber_Reply));
  if (memcmp(buf, MagicNumber_Reply, sizeof(MagicNumber_Reply)) != 0) {
    throw Error_Device ("Device is not responding correctly."); }

  memcpy(buf, EnterPgmMode, sizeof(EnterPgmMode));
  Send(buf, sizeof(EnterPgmMode), sizeof(EnterPgmMode_Reply));
  if (memcmp(buf, EnterPgmMode_Reply, sizeof(EnterPgmMode_Reply)) != 0) {
    throw Error_Device ("Failed to enter programming mode."); }
}


void TStk500::LeaveProgrammingMode() {
  TByte buf[100];

  memcpy(buf, LeavePgmMode, sizeof(LeavePgmMode));
  Send(buf, sizeof(LeavePgmMode), sizeof(LeavePgmMode_Reply));
  if (memcmp(buf, LeavePgmMode_Reply, sizeof(LeavePgmMode_Reply)) != 0) {
    throw Error_Device ("Device is not responding correctly."); }
}


void TStk500::ReadSignature() {
  TByte buf[100];

  memcpy(buf, GetSignature, sizeof(GetSignature));
  Send(buf, sizeof(GetSignature), sizeof(GetSignature_Reply));
  part_number = buf[1];
  part_family = buf[2];
  vendor_code = buf[3];
}


void TStk500::ReadMem(){
  TByte buf[0x200];
  int wordsize;
  TAddr addr;
  TByte seg;

  read_buffer = new TByte[GetSegmentSize()];

  if (segment == SEG_FLASH) {
    wordsize = 2;
    seg = Flash;
  } else {
    wordsize = 1;
    seg = EEPROM;
  }

  EnterProgrammingMode();

  addr = 0;
  for (unsigned int addr=0; addr<GetSegmentSize(); addr+=0x100) {
    memcpy(buf, SetAddress, sizeof(SetAddress));
    buf[1] = (addr/wordsize) & 0xff;
    buf[2] = ((addr/wordsize) >> 8) & 0xff;
    Send(buf, sizeof(SetAddress), sizeof(SetAddress_Reply));
    if (memcmp(buf, SetAddress_Reply, sizeof(SetAddress_Reply)) != 0) {
      throw Error_Device ("Device is not responding correctly."); }
   
    memcpy(buf, ReadMemory, sizeof(ReadMemory));
    buf[3] = seg;
    Send(buf, sizeof(ReadMemory), 2+0x100);

    memcpy(read_buffer+addr, buf+1, 0x100);
  }

  LeaveProgrammingMode();
}


TStk500::TStk500() {
  /* Select Part by name */
  desired_part=-1;
  const char* desired_partname = GetCmdParam("-dpart");

  if (desired_partname!=NULL) {
    int j;
    for (j=0; prg_part[j].name[0] != 0; j++){
      if (strcmp (desired_partname, prg_part[j].name)==0){
    desired_part = j;
    break;
      }
    }
    if (prg_part[j].name[0]==0){throw Error_Device("-dpart: Invalid name.");}
  } else {
    int i = 0;
    Info(0, "No part specified, supported devices are:\n");
    while (prg_part[i].name[0] != '\0')
      Info(0, "%s\n", prg_part[i++].name);
    throw Error_Device("");
  }

  EnterProgrammingMode();
  ReadSignature();
  LeaveProgrammingMode();
  Identify();

  write_buffer = NULL;
  read_buffer = NULL;
  maxaddr = 0;
}



TStk500::~TStk500() {
  delete write_buffer;
  delete read_buffer;
}

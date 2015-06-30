/* Stk500.h, Daniel Berntsson, 2001 */

#ifndef __STK500
#define __STK500

#include "Global.h"
#include "Serial.h"
#include "Avr.h"

class TStk500: public TAvr, TSerial {
private:
  struct SPrgPart{
    const char name[10];
    const TByte params[22];
  };

  int desired_part;
  TByte* write_buffer;
  TByte* read_buffer;
  TAddr maxaddr;

  static const TByte pSTK500[];
  static const TByte pSTK500_Reply[];
  static const TByte SWminor[];
  static const TByte SWminor_Reply[];
  static const TByte SWmajor[];
  static const TByte SWmajor_Reply[];
  static const TByte MagicNumber[];
  static const TByte MagicNumber_Reply[];
  static const TByte EnterPgmMode[];
  static const TByte EnterPgmMode_Reply[];
  static const TByte LeavePgmMode[];
  static const TByte LeavePgmMode_Reply[];
  static const TByte SetAddress[];
  static const TByte SetAddress_Reply[];
  static const TByte EraseDevice[];
  static const TByte EraseDevice_Reply[];
  static const TByte WriteMemory[];
  static const TByte WriteMemory_Reply[];
  static const TByte ReadMemory[];
  static const TByte ReadMemory_Reply[];
  static const TByte GetSignature[];
  static const TByte GetSignature_Reply[];
  static const TByte CmdStopByte[];
  static const TByte ReplyStopByte[];
  static const TByte Flash;
  static const TByte EEPROM;
  static const TByte DeviceParam_Reply[];
  static const SPrgPart prg_part[];
   
  void EnterProgrammingMode();
  void LeaveProgrammingMode();
  void ReadSignature();
  void ReadMem();

public:
  /* Read byte from active segment at address addr. */
  TByte ReadByte(TAddr addr);

  /* Write byte to active segment at address addr */
  void WriteByte(TAddr addr, TByte byte, bool flush_buffer=true);
  void FlushWriteBuffer();

  /* Chip Erase */
  void ChipErase();

  /* Write lock bits */
  void WriteLockBits(TByte bits);

  TStk500();
  ~TStk500();
};

#endif

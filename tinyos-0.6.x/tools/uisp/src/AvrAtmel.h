/* AvrAtmel.h, Uros Platise (c) 1999 */

#ifndef __AVR_ATMEL
#define __AVR_ATMEL

#include "Global.h"
#include "Serial.h"
#include "Avr.h"

class TAvrAtmel: public TAvr, TSerial {
private:
  /* Programmer AVR codes */
  struct SPrgPart{
    const char* name;
    TByte code;
    const char* description;
    bool supported;
  };
  static SPrgPart prg_part[];
  TByte desired_avrcode;

  /* Flash word's lower byte cache */
  bool cache_lowbyte;
  TByte buf_lowbyte;
  TAddr buf_addr;
  
  /* Speed-up Transfer by using the Auto-Increment Option */
  TAddr apc_address;	/* AVR Programmer's Current Address */
  bool apc_autoinc;	/* Auto Increment Supported by AVR ISP SoftVer 2 */

private:
  void EnterProgrammingMode();
  void LeaveProgrammingMode();
  void CheckResponse(TByte x);
  void EnableAvr();
  void SetAddress(TAddr addr);
  void WriteProgramMemoryPage();

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
  
  TAvrAtmel();
  ~TAvrAtmel();
};

#endif

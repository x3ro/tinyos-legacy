/* AvrDummy.h, Uros Platise (c) 1999 */

#ifndef __AVR_DUMMY
#define __AVR_DUMMY

#include "Global.h"
#include "Avr.h"
#include "DAPA.h"

class TAvrDummy: public TAvr, TDAPA {
private:
  bool use_data_polling;
  float min_poll_time, max_poll_time, total_poll_time;
  unsigned long total_poll_cnt;  /* bytes or pages */

  void EnableAvr();
  TByte GetPartInfo(TAddr addr);
  void WriteProgramMemoryPage();
  TByte ReadLockFuseBits();
  TByte ReadFuseLowBits();
  TByte ReadFuseHighBits();
  TByte ReadCalByte();
  void WriteOldFuseBits(TByte val);  /* 5 bits */
  void WriteFuseLowBits(TByte val);
  void WriteFuseHighBits(TByte val);

  /* lock bits */
  void WriteLockBits(TByte bits);
  TByte ReadLockBits();

public:
  /* Read byte from active segment at address addr. */
  TByte ReadByte(TAddr addr);

  /* Write byte to active segment at address addr */
  void WriteByte(TAddr addr, TByte byte, bool flush_buffer=true);
  void FlushWriteBuffer();
  
  /* Chip Erase */
  void ChipErase();

  /* Transfer Statistics */
  unsigned int GetPollCount();
  float GetMinPollTime();
  float GetTotPollTime();
  float GetMaxPollTime();
  void ResetMinMax();
  
  TAvrDummy();
  ~TAvrDummy(){}
};

#endif

#ifndef _SR_TIMESTAMP__
#define _SR_TIMESTAMP__

#include <TosTime.h>

typedef uint8_t TimeStamp[5];

void timeStampPrint(TimeStamp t) {
  dbg(DBG_USR1, "%u.%u\n", t[0], *(uint32_t *)(&t[1]));
}

tos_time_t timeStamp2tos(TimeStamp t) {
  tos_time_t result;
  
  result.low32 = *(uint32_t *)(&t[1]);
  result.high32 = t[0];
  
  return result;
}

uint64_t timeStamp2ulint(TimeStamp t) {
  return *(uint32_t *)(&t[1]) + (((uint64_t)t[0]) << 32);
}

uint32_t timeStampDiv32(TimeStamp t, uint32_t _div) {
  uint64_t num = 
    *(uint32_t *)(&t[1]) + (((uint64_t)t[0]) << 32);

  return (uint32_t)(num / (uint64_t)_div);
}

void tos2timeStamp(tos_time_t tt, TimeStamp t) {
  *(uint32_t *)(&t[1]) = tt.low32;
  t[0] = (uint8_t)(tt.high32 & 0x000000FF);      
}

void ulint2timeStamp(uint64_t t, TimeStamp ts) {
  ts[0] = ((uint8_t *)&t)[1];
  *(uint32_t *)(&ts[1]) = ((uint32_t *)&t)[1];
}

void timeStampAdd16(TimeStamp t, uint16_t amt) {
  uint32_t oldAmt = *(uint32_t *)(&t[1]);
  
  if (oldAmt + amt < oldAmt)
    t[0]++;
  
  *(uint32_t *)(&t[1]) += amt;
}

void timeStampAdd32(TimeStamp t, uint32_t amt) {
  uint32_t oldAmt = *(uint32_t *)(&t[1]);
  
  if (oldAmt + amt < oldAmt)
    t[0]++;
  
  *(uint32_t *)(&t[1]) += amt;
}

int64_t timeStampDiff(TimeStamp t1, 
		      TimeStamp t2) {
  return *(uint32_t *)(&t1[1]) + (int64_t)(((uint64_t)t1[0]) << 32) - 
    (*(uint32_t *)(&t2[1]) + (int64_t)(((uint64_t)t2[0]) << 32));
}

int8_t timeStampCompare(TimeStamp t1,
			TimeStamp t2) {
  if (t1[0] > t2[0])
    return 1;
  if (t1[0] < t2[0])
    return -1;

  if (*(uint32_t *)(&t1[1]) > *(uint32_t *)(&t2[1]))
    return 1;
  if (*(uint32_t *)(&t1[1]) < *(uint32_t *)(&t2[1]))
    return -1;

  return 0;
}

void timeStampCopy(TimeStamp tgt, TimeStamp src) {
  memcpy(tgt, src, sizeof(TimeStamp));
}

#endif

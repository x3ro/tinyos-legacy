/*
  F i x e d . h

  $Id: Fixed.h,v 1.1 2004/05/18 18:58:18 ssbapat Exp $
*/

#ifndef _FIXED_H_
#define _FIXED_H_

/* 8-bit fixed point types */

typedef uint8_t ufix8_1_t;
typedef uint8_t ufix8_2_t;
typedef uint8_t ufix8_3_t;
typedef uint8_t ufix8_4_t;
typedef uint8_t ufix8_5_t;
typedef uint8_t ufix8_6_t;
typedef uint8_t ufix8_7_t;
typedef uint8_t ufix8_8_t;
typedef int8_t fix8_1_t;
typedef int8_t fix8_2_t;
typedef int8_t fix8_3_t;
typedef int8_t fix8_4_t;
typedef int8_t fix8_5_t;
typedef int8_t fix8_6_t;
typedef int8_t fix8_7_t;
typedef int8_t fix8_8_t;

/* 16-bit fixed point types */

typedef uint16_t ufix16_1_t;
typedef uint16_t ufix16_2_t;
typedef uint16_t ufix16_3_t;
typedef uint16_t ufix16_4_t;
typedef uint16_t ufix16_5_t;
typedef uint16_t ufix16_6_t;
typedef uint16_t ufix16_7_t;
typedef uint16_t ufix16_8_t;
typedef uint16_t ufix16_9_t;
typedef uint16_t ufix16_10_t;
typedef uint16_t ufix16_11_t;
typedef uint16_t ufix16_12_t;
typedef uint16_t ufix16_13_t;
typedef uint16_t ufix16_14_t;
typedef uint16_t ufix16_15_t;
typedef uint16_t ufix16_16_t;
typedef int16_t fix16_1_t;
typedef int16_t fix16_2_t;
typedef int16_t fix16_3_t;
typedef int16_t fix16_4_t;
typedef int16_t fix16_5_t;
typedef int16_t fix16_6_t;
typedef int16_t fix16_7_t;
typedef int16_t fix16_8_t;
typedef int16_t fix16_9_t;
typedef int16_t fix16_10_t;
typedef int16_t fix16_11_t;
typedef int16_t fix16_12_t;
typedef int16_t fix16_13_t;
typedef int16_t fix16_14_t;
typedef int16_t fix16_15_t;
typedef int16_t fix16_16_t;

/* 32-bit fixed point types */

typedef uint32_t ufix32_1_t;
typedef uint32_t ufix32_2_t;
typedef uint32_t ufix32_3_t;
typedef uint32_t ufix32_4_t;
typedef uint32_t ufix32_5_t;
typedef uint32_t ufix32_6_t;
typedef uint32_t ufix32_7_t;
typedef uint32_t ufix32_8_t;
typedef uint32_t ufix32_9_t;
typedef uint32_t ufix32_10_t;
typedef uint32_t ufix32_11_t;
typedef uint32_t ufix32_12_t;
typedef uint32_t ufix32_13_t;
typedef uint32_t ufix32_14_t;
typedef uint32_t ufix32_15_t;
typedef uint32_t ufix32_16_t;
typedef int32_t fix32_1_t;
typedef int32_t fix32_2_t;
typedef int32_t fix32_3_t;
typedef int32_t fix32_4_t;
typedef int32_t fix32_5_t;
typedef int32_t fix32_6_t;
typedef int32_t fix32_7_t;
typedef int32_t fix32_8_t;
typedef int32_t fix32_9_t;
typedef int32_t fix32_10_t;
typedef int32_t fix32_11_t;
typedef int32_t fix32_12_t;
typedef int32_t fix32_13_t;
typedef int32_t fix32_14_t;
typedef int32_t fix32_15_t;
typedef int32_t fix32_16_t;

/* Conversion functions */

/* TODO - overflow checking? */

inline ufix16_1_t uint8_to_ufix16_1(uint8_t uint8Num)
{
  return ((ufix16_1_t)uint8Num) << 1;
}

inline ufix16_3_t uint8_to_ufix16_3(uint8_t uint8Num)
{
  return ((ufix16_3_t)uint8Num) << 3;
}

inline ufix16_8_t uint8_to_ufix16_8(uint8_t uint8Num)
{
  return ((ufix16_8_t)uint8Num) << 8;
}

inline ufix32_3_t uint8_to_ufix32_3(uint8_t uint8Num)
{
  return ((ufix32_3_t)uint8Num) << 3;
}

inline ufix32_6_t uint8_to_ufix32_6(uint8_t uint8Num)
{
  return ((ufix32_6_t)uint8Num) << 6;
}

inline ufix32_15_t uint8_to_ufix32_15(uint8_t uint8Num)
{
  return ((ufix32_15_t)uint8Num) << 15;
}

inline fix32_6_t uint8_to_fix32_6(uint8_t uint8Num)
{
  return ((fix32_6_t)uint8Num) << 6;
}

inline ufix16_8_t ufix16_1_to_ufix16_8(ufix16_1_t ufix16_1Num)
{
  return ((ufix16_8_t)ufix16_1Num << 7);
}

inline ufix16_8_t ufix16_3_to_ufix16_8(ufix16_3_t ufix16_3Num)
{
  return ((ufix16_8_t)ufix16_3Num << 5);
}

inline ufix16_9_t ufix16_3_to_ufix16_9(ufix16_3_t ufix16_3Num)
{
  return ((ufix16_9_t)ufix16_3Num << 6);
}

inline ufix32_3_t ufix16_3_to_ufix32_3(ufix16_3_t ufix16_3Num)
{
  return ((ufix32_3_t)ufix16_3Num);
}

inline fix32_3_t ufix16_3_to_fix32_3(ufix16_3_t ufix16_3Num)
{
  return ((fix32_3_t)ufix16_3Num);
}

inline fix32_6_t ufix16_3_to_fix32_6(ufix16_3_t ufix16_3Num)
{
  return ((fix32_6_t)ufix16_3Num) << 3;
}

inline ufix16_3_t ufix32_3_to_ufix16_3(ufix32_3_t ufix32_3Num)
{
  return ((ufix16_3_t)ufix32_3Num & 0xFFFF);
}

inline ufix16_15_t ufix32_15_to_ufix16_15(ufix32_15_t ufix32_15Num)
{
  return ((ufix16_15_t)ufix32_15Num & 0xFFFF);
}

inline ufix32_6_t fix32_6_to_ufix32_6(fix32_6_t fix32_6Num)
{
  return ((ufix32_6_t)fix32_6Num);
}

#endif

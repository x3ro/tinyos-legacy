/*
  U t i l M a t h . h

  $Id: UtilMath.h,v 1.1 2004/05/18 18:58:18 ssbapat Exp $
*/

#ifndef _UTIL_MATH_H_
#define _UTIL_MATH_H_

/*
  Parity
*/
inline bool IsOddU8(uint8_t num)
  { return (num & 1); };
     
inline bool IsEvenU8(uint8_t num)
  { return !(num & 1); };
     
inline bool IsOddU16(uint16_t num)
  { return (num & 1); };
     
inline bool IsEvenU16(uint16_t num)
  { return !(num & 1); };

/*
  Min and Max
*/
inline uint8_t MinU8(uint8_t A, uint8_t B)
  { return (A < B) ? A : B; };
     
inline uint8_t MaxU8(uint8_t A, uint8_t B)
  { return (A > B) ? A : B; };
     
inline uint16_t MinU16(uint16_t A, uint16_t B)
  { return (A < B) ? A : B; };
     
inline uint16_t MaxU16(uint16_t A, uint16_t B)
  { return (A > B) ? A : B; };

inline int8_t Min8(int8_t A, int8_t B)
  { return (A < B) ? A : B; };
     
inline int8_t Max8(int8_t A, int8_t B)
  { return (A > B) ? A : B; };
     
inline int16_t Min16(int16_t A, int16_t B)
  { return (A < B) ? A : B; };
     
inline int16_t Max16(int16_t A, int16_t B)
  { return (A > B) ? A : B; };

/*
  CeilDiv and RoundDiv
*/
inline uint8_t CeilDivU8(uint8_t N, uint8_t M)
  { return (N - 1)/M + 1; };

inline uint16_t CeilDivU16(uint16_t N, uint16_t M)
  { return (N - 1)/M + 1; };

inline uint8_t RoundDivU8(uint8_t N, uint8_t M) {
  return N/M + (N%M >= M>>1);
};

inline int8_t RoundDiv8(int8_t N, int8_t M) {
  return N/M + (N%M >= M>>1);
};

inline uint16_t RoundDivU16(uint16_t N, uint16_t M) {
  return N/M + (N%M >= M>>1);
};

inline int16_t RoundDiv16(int16_t N, int16_t M) {
  return N/M + (N%M >= M>>1);
};

inline uint32_t RoundDivU32(uint32_t N, uint32_t M) {
  return N/M + (N%M >= M>>1);
};

inline int32_t RoundDiv32(int32_t N, int32_t M) {
  return N/M + (N%M >= M>>1);
};

/*
  Log2
*/

inline int8_t Log2U16(uint16_t num)
{
  int8_t i;

  i = -1;
  while (num != 0) {
    num = (num >> 1);
    i++;
  }

  return i;
}

inline int8_t Log2U32(uint32_t num)
{
  int8_t i;

  i = -1;
  while (num != 0) {
    num = (num >> 1);
    i++;
  }

  return i;
}

/*
  Sqrt
  This will return a fixed point result were shift indicates the type
  of the fixed point number.
*/

inline uint8_t SqrtU8(uint8_t num)
{
  uint16_t highSqr, lowSqr;
  uint8_t highGuess, highPow, nextGuess;
  uint8_t lowGuess;
  
  if(num == 0)
      return num;
  
  highPow = Log2U16(num - 1) + 1;
  nextGuess = (1 << (((highPow - 1) >> 1) + 1)) ;

  do {
    highGuess = nextGuess;
    highSqr = highGuess * highGuess;
    nextGuess = highGuess - (highSqr - num)/(2*highGuess); // no overflow
  } while (nextGuess != highGuess);

  lowGuess = highGuess - 1;
  lowSqr = lowGuess*lowGuess;

  return ((num - lowSqr) < (highSqr - num)) ? lowGuess : highGuess;
} // Sqrt8

inline uint16_t SqrtU16(uint16_t num)
{
  uint32_t highSqr, lowSqr;
  uint16_t highGuess, highPow;
  uint16_t nextGuess, lowGuess;

  highPow = Log2U16(num - 1) + 1;
  nextGuess = (1 << (((highPow - 1) >> 1) + 1));

  do {
    highGuess = nextGuess;
    highSqr = highGuess * highGuess;
    nextGuess = highGuess - (highSqr - num)/(2*highGuess); // no overflow
  } while (nextGuess != highGuess);

  lowGuess = highGuess - 1;
  lowSqr = lowGuess*lowGuess;

  return ((num - lowSqr) < (highSqr - num)) ? lowGuess : highGuess;
} // Sqrt16

// Will overflow for numbers > ~ 3 billion

inline uint16_t SqrtU32(uint32_t num)
{
  uint32_t highSqr, lowSqr;
  uint16_t highGuess, highPow;
  uint16_t nextGuess, lowGuess;

  highPow = Log2U32(num - 1) + 1;
  nextGuess = (1 << (((highPow - 1) >> 1) + 1));

  do {
    highGuess = nextGuess;
    highSqr = highGuess * highGuess;
    nextGuess = highGuess - (highSqr - num)/(2*highGuess); // no overflow
  } while (nextGuess != highGuess);

  lowGuess = highGuess - 1;
  lowSqr = lowGuess*lowGuess;

  return ((num - lowSqr) < (highSqr - num)) ? lowGuess : highGuess;
} // Sqrt32

/* Absolute value */

inline uint8_t Abs8(int8_t num)
{
  return ((num)<0?(-(num)):(num));
}

inline uint16_t Abs16(int16_t num)
{
  return ((num)<0?(-(num)):(num));
}

inline uint32_t Abs32(int32_t num)
{
  return ((num)<0?(-(num)):(num));
}

/* Bit manipulation utilities */

/* Returns the bit width required to represent the given argument */

inline uint8_t BitWidthU8(uint8_t num)
{
  uint8_t i;

  i = 0;
  while (num != 0) {
    num >>= 1;
    i++;
  }

  return i;
} // BitWidthU8

inline uint8_t BitWidth8(int8_t num)
{
  return BitWidthU8((uint8_t)(num < 0 ? ~num : num)) + 1;
} // BitWidth8

inline uint8_t BitWidthU16(uint16_t num)
{
  uint8_t i;

  i = 0;
  while (num != 0) {
    num >>= 1;
    i++;
  }

  return i;
} // BitWidthU16

inline uint8_t BitWidth16(int16_t num)
{
  return BitWidthU16((uint16_t)(num < 0 ? ~num : num)) + 1;
} // BitWidth16

inline uint8_t BitWidthU32(uint32_t num)
{
  uint8_t i;

  i = 0;
  while (num != 0) {
    num >>= 1;
    i++;
  }

  return i;
} // BitWidthU32

inline uint8_t BitWidth32(int32_t num)
{
  return BitWidthU32((uint32_t)(num < 0 ? ~num : num)) + 1;
} // BitWidth32

/* Computes the "headroom" (number of consecutive zeros in the high
   binary places) and "footroom" (number of consecutive zeros in the
   low binary places) of the given argument */

inline uint8_t HeadRoomU8(uint8_t num) {
  return (8 - BitWidthU8(num));
}

inline uint8_t HeadRoom8(int8_t num) {
  return (8 - BitWidth8(num));
}

inline uint8_t FootRoomU8(uint8_t num) {
  uint8_t i;

  i = 0;
  while ((num & 0x01) == 0) {
    num >>= 1;
    i++;
  }

  return i;
}

inline uint8_t FootRoom8(int8_t num) {
  uint8_t i;

  i = 0;
  while ((num & 0x01) == 0) {
    num >>= 1;
    i++;
  }

  return i;
}

#endif

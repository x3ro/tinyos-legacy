#ifndef BASETYPES_H
#define BASETYPES_H

/* Basic unit storage is 4 bytes. It can represent
   - an IEEE 32-bit float (with some NaN patterns missing)
   - a 16-bit integer
   - a 16-bit atom
   - a 16-bit pointer
   The last 3 are coded as various kinds of NaN. specifically:
   - all 3 have sign = 1, low-order bit of mantissa = 1
   - the 16-bits are mantissa bits 3 through 18
   - mantissa bits 2,1 are 00 for integer, 01 for atom, 10 for pointer
*/

typedef uint32_t mvalue;
typedef uint32_t svalue;

typedef struct neverdeclaredeither *pvalue;
typedef int16_t ivalue;
typedef uint16_t avalue;

typedef uint16_t msize;

#endif

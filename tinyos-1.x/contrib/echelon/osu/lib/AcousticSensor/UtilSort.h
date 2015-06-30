/*
  U t i l S o r t . h
*/

#ifndef _UTIL_SORT_H_
#define _UTIL_SORT_H_

/*
  Swap funcitons.

  Note that the swap funciton don't care about the rathter the
  argument is sigined or unsigned.  So we arbitrarly piced unsinged if
  the actual array is signed it should be case.
*/
inline void Swap8(uint8_t *data, uint16_t index0, uint16_t index1)
{
  uint8_t temp;

  temp = data[index0];
  data[index0] = data[index1];
  data[index1] = temp;
} // Swap8

inline void Swap16(uint16_t *data, uint16_t index0, uint16_t index1)
{
  uint16_t temp;

  temp = data[index0];
  data[index0] = data[index1];
  data[index1] = temp;
} // Swap16


/*
  BubleSort
*/

inline void BubbleSortU8(uint8_t *data, uint16_t len)
{
  uint16_t i,j;

  for (i = len; i > 1; i--)
    for (j = 0; j < i-1; j++)
      if (data[j+1] < data[j])
        Swap8(data, j, j+1);
} // BubleSort

inline void BubbleSort8(int8_t *data, uint16_t len)
{
  uint16_t i,j;

  for (i = len; i > 1; i--)
    for (j = 0; j < i-1; j++)
      if (data[j+1] < data[j])
        Swap8((uint8_t *) data, j, j+1);
} // BubleSort

inline void BubbleSortU16(uint16_t *data, uint16_t len)
{
  uint16_t i,j;

  for (i = len; i > 1; i--)
    for (j = 0; j < i-1; j++)
      if (data[j+1] < data[j])
        Swap16(data, j, j+1);
} // BubleSort

inline void BubbleSort16(int16_t *data, uint16_t len)
{
  uint16_t i,j;

  for (i = len; i > 1; i--)
    for (j = 0; j < i-1; j++)
      if (data[j+1] < data[j])
        Swap16((uint16_t *) data, j, j+1);
} // BubleSort

#endif

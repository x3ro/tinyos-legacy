
#ifndef _H_common_math_h
#define _H_common_math_h

  uint16_t absdiff_u16( uint16_t a, uint16_t b )
  {
    return (a<b) ? (b-a) : (a-b);
  }

#endif

#ifndef __BYTEORDER
#define __BYTEORDER

/*
 *
 * $Log: byteorder.h,v $
 * Revision 1.1  2005/04/19 02:56:03  husq
 * Import the micazack and CC2420RadioAck
 *
 * Revision 1.2  2005/03/02 22:34:16  jprabhu
 * Added Log-tag for capturing changes in files.
 *
 *
 */

inline int is_host_msb()
{
   const uint8_t n[2] = {0,1};
   return ((*(uint16_t*)n) == 1);
}

inline int is_host_lsb()
{
   const uint8_t n[2] = {1,0};
   return ((*(uint16_t*)n) == 1);
}

inline uint16_t toLSB16( uint16_t a )
{
   return is_host_lsb() ? a : ((a<<8)|(a>>8));
}

inline uint16_t fromLSB16( uint16_t a )
{
   return is_host_lsb() ? a : ((a<<8)|(a>>8));
}

#endif

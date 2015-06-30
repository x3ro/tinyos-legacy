//$Id: GroupSet.h,v 1.2 2005/06/30 04:58:28 cssharp Exp $
#ifndef _H_GroupSet_h
#define _H_GroupSet_h

enum
{
  GROUPSET_ADDRESS_PREFIX = 0xFD,
  GROUPSET_BITS = 96,
  GROUPSET_BYTES = GROUPSET_BITS >> 3,
};

typedef struct groupset_t
{
  uint8_t vec[GROUPSET_BYTES];
} groupset_t;

#endif//_H_GroupSet_h


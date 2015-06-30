
#ifndef _H_ChangeGroupId_h
#define _H_ChangeGroupId_h

enum
{
  AM_CHANGE_GROUP_ID = 247,
};

typedef struct
{
  uint8_t new_group;
  uint16_t address_verify;
} ChangeGroupId_t;

#endif//_H_ChangeGroupId_h


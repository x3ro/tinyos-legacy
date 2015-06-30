//$Id: Ident.h,v 1.4 2005/06/14 18:10:10 gtolle Exp $

#ifndef __IDENT_H__
#define __IDENT_H__

enum {
  ATTR_AMAddress = 1,
  ATTR_AMGroup = 2,
  ATTR_HardwareID = 3,
  ATTR_ProgramName = 4,
  ATTR_ProgramCompilerID = 5,
  ATTR_ProgramCompileTime = 6,
};

enum {
  HARDWARE_ID_LEN = 8,
};

typedef struct hardwareID
{
  char hardwareID[HARDWARE_ID_LEN];
} hardwareID_t;

typedef struct programName
{
  char programName[IDENT_MAX_PROGRAM_NAME_LENGTH];
} programName_t;

#endif // __IDENT_H__

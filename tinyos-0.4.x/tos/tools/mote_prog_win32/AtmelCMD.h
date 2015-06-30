/*
  termAvr.h
  Uros Platise, (c) 1997
*/

#ifndef __AtmelCMD
#define __AtmelCMD

#include "Atmel_base.h"

class TAtmelCMD : public TAtmelAvr
{
public:
   TAtmelCMD (TDev *device, TPartDB* Part, char* pName=NULL) :
   TAtmelAvr (device, Part, pName) { }
   ~TAtmelCMD () { }
   void Do (int argc, char* argv[]);
};

#endif



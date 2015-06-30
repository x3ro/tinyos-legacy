/*
  termAvr.h
  Uros Platise, (c) 1997
*/

#ifndef __AtmelTerm
#define __AtmelTerm

#include "Atmel_base.h"

class TAtmelTerm : public TAtmelAvr
{
public:
   TAtmelTerm (TDev *device, TPartDB* Part, char* pName=NULL) :
   TAtmelAvr (device, Part, pName) { }
   ~TAtmelTerm () { }
   void Run ();
};

#endif



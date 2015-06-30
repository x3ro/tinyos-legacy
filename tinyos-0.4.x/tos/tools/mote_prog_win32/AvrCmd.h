/*
  termAvr.h
  Uros Platise, (c) 1997
*/

#ifndef __cmdAvr
#define __cmdAvr

#include "Avr_base.h"

class TcmdAvr : public TAvr
{
public:
   TcmdAvr (TDev *device, TPartDB* Part) :
   TAvr (device, Part) { }
   ~TcmdAvr () { }
   void Do (int argc, char* argv[]);
};

#endif

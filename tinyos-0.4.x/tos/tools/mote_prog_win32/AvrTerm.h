/*
  termAvr.h
  Uros Platise, (c) 1997
*/

#ifndef __termAvr
#define __termAvr

#include "Avr_base.h"

class TtermAvr : public TAvr {
public:
  TtermAvr (TDev *device, TPartDB* Part) : TAvr (device, Part) {}
  ~TtermAvr () { }
  void Run ();
};

#endif



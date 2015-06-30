/*
	Serial.h  
	RS232 Serial Interface for the standard Atmel Programmer
	Uros Platise(c) copyright 1997-1999
*/

#ifndef __Serial
#define __Serial

#include <sys/types.h>
#if defined(__CYGWIN__)
#include "cygwinp.h"
#endif
#include <time.h>
#include <unistd.h>
#include <termios.h>
#include <string.h>
#include "Global.h"
#include "Error.h"

class TSerial{
private:
  int serline;
  struct termios saved_modes;
  
protected:
  int Tx(unsigned char* queue, int queue_size);
  int Rx(unsigned char* queue, int queue_size, timeval* timeout);

public:
  int Send(unsigned char* queue, int queue_size, int rec_queue_size=-1);

  TSerial();
  ~TSerial();
};

#endif

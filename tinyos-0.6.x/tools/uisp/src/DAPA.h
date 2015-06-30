/*
  DAPA.h
  
  Direct AVR Parallel Access
  
  (c) copyright 1997, Uros Platise  
*/

#ifndef __DAPA
#define __DAPA

#include <sys/types.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include "Error.h"

class TDAPA {
public:
  enum TPaType{	PAT_DAPA, PAT_STK200, PAT_ABB, PAT_AVRISP, PAT_BSD,
		PAT_FBPRG, PAT_DT006,
		PAT_DASA, PAT_DASA2, PAT_DAPA_2};

private:
  int parport_base;
  int ppdev_fd;
  long t_sck;
  TPaType pa_type;
  bool pa_type_is_serial;  /* not ppdev/ppi */
  struct termios saved_modes;
  unsigned char par_data, par_ctrl;  /* write */
  unsigned char par_status;  /* read */
  unsigned int ser_ctrl;  /* TIOCMGET/TIOCMSET */

private:
  int SendRecv(int);
  /* low level access to parallel port lines */
  void OutReset(int);
  void OutSck(int);
  void OutData(int);
  void SckDelay();
  int InData();
  void OutEnaReset(int);
  void OutEnaSck(int);

  void ParportSetDir(int);
  void ParportWriteCtrl();
  void ParportWriteData();
  void ParportReadStatus();

  void SerialReadCtrl();
  void SerialWriteCtrl();

public:
  /* If enable command 0x53 did not echo back, give a positive SCK
     pulse and retry again.
  */
  void PulseSck();
  void PulseReset();
  void Init();
  int Send(unsigned char*, int, int rec_queueSize=-1);
  void Delay_usec(long);

  TDAPA();
  ~TDAPA();
};

#endif

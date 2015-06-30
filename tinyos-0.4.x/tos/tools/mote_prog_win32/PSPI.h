/*
  Serial.h

  (c) copyright 1997, Uros Platise
*/

#ifndef __PSPI
#define __PSPI


// SPI Interface on parallel port
class PSPI
{
private:
   bool port_enabled;
protected:
   int speed;
   int NO_VERIFY;

public:
   PSPI (void);
   ~PSPI (void);
   int Send (unsigned char*, int, int rec_queueSize=-1);
   void clk (void);
   unsigned char send_recv (unsigned char b);
};
extern int parport_base;

#endif
